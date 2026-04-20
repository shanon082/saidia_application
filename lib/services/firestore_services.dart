import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Compatibility classes to keep existing UI code stable while using Supabase.
class Timestamp {
  final DateTime _date;
  Timestamp(this._date);
  DateTime toDate() => _date;
  static Timestamp now() => Timestamp(DateTime.now());

  int get millisecondsSinceEpoch => _date.millisecondsSinceEpoch;

  // Custom for Supabase timestamp fields
  factory Timestamp.parse(String isoString) {
    return Timestamp(DateTime.parse(isoString));
  }
}

class FieldValue {
  static String serverTimestamp() => DateTime.now().toUtc().toIso8601String();
}

class DocumentSnapshot<T> {
  final String id;
  final T? _data;
  final bool exists;
  DocumentSnapshot(this.id, this._data, this.exists);
  T? data() => _data;
}

class QueryDocumentSnapshot<T> {
  final String id;
  final T _data;
  QueryDocumentSnapshot(this.id, this._data);
  T data() => _data;
}

class QuerySnapshot<T> {
  final List<QueryDocumentSnapshot<T>> docs;
  QuerySnapshot(this.docs);
}

// -------------------------------------------------------------

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  static FirestoreService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUid => _supabase.auth.currentUser?.id;
  User? get currentUser => _supabase.auth.currentUser;

  // Helper to parse dates
  Timestamp? parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is String) return Timestamp.parse(val);
    return null;
  }

  // Convert list to snapshot
  QuerySnapshot<Map<String, dynamic>> _toQuerySnapshot(
    List<Map<String, dynamic>> data,
  ) {
    final docs = data.map((map) {
      // Map timestamp fields back to Timestamp object for UI
      if (map.containsKey('createdAt')) {
        map['createdAt'] = parseTimestamp(map['createdAt']);
      }
      if (map.containsKey('updatedAt')) {
        map['updatedAt'] = parseTimestamp(map['updatedAt']);
      }
      if (map.containsKey('timestamp')) {
        map['timestamp'] = parseTimestamp(map['timestamp']);
      }
      if (map.containsKey('appliedAt')) {
        map['appliedAt'] = parseTimestamp(map['appliedAt']);
      }
      if (map.containsKey('reviewedAt')) {
        map['reviewedAt'] = parseTimestamp(map['reviewedAt']);
      }
      if (map.containsKey('lastMessageTime')) {
        map['lastMessageTime'] = parseTimestamp(map['lastMessageTime']);
      }

      final id = map['id']?.toString() ?? map['userId']?.toString() ?? '';
      return QueryDocumentSnapshot<Map<String, dynamic>>(id, map);
    }).toList();
    return QuerySnapshot(docs);
  }

  DocumentSnapshot<Map<String, dynamic>> _toDocSnapshot(
    Map<String, dynamic>? map,
    String fallbackId,
  ) {
    if (map == null) return DocumentSnapshot(fallbackId, null, false);

    if (map.containsKey('createdAt')) {
      map['createdAt'] = parseTimestamp(map['createdAt']);
    }
    if (map.containsKey('updatedAt')) {
      map['updatedAt'] = parseTimestamp(map['updatedAt']);
    }
    if (map.containsKey('timestamp')) {
      map['timestamp'] = parseTimestamp(map['timestamp']);
    }

    final id = map['id']?.toString() ?? map['userId']?.toString() ?? fallbackId;
    return DocumentSnapshot(id, map, true);
  }

  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    String? uid,
  }) async {
    final targetUid = uid ?? currentUid;
    if (targetUid == null) throw Exception('User not authenticated');
    try {
      await _supabase.from('users').upsert({
        'id': targetUid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': 'customer',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await ensureWalletExists(targetUid);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isEmailTaken(String email) async {
    final res = await _supabase
        .from('users')
        .select('id')
        .eq('email', email.trim().toLowerCase())
        .limit(1);
    return res.isNotEmpty;
  }

  Future<bool> isPhoneTaken(String phone) async {
    final res = await _supabase
        .from('users')
        .select('id')
        .eq('phone', phone.trim())
        .limit(1);
    return res.isNotEmpty;
  }

  Future<void> applyAsProvider() async {
    if (currentUid == null) throw Exception('User not authenticated');
    await _supabase
        .from('users')
        .update({
          'providerStatus': 'pending',
          'providerApplicationDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .eq('id', currentUid!);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', currentUid!)
        .map((event) {
          if (event.isEmpty) return _toDocSnapshot(null, currentUid!);
          return _toDocSnapshot(event.first, currentUid!);
        });
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUid == null) return null;
    final res = await _supabase
        .from('users')
        .select()
        .eq('id', currentUid!)
        .maybeSingle();
    return res;
  }

  Future<bool> isUserAdmin() async {
    final data = await getCurrentUserData();
    return data?['role'] == 'admin';
  }

  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = res.user;
    if (user != null) {
      await _supabase.from('users').insert({
        'id': user.id,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': 'admin',
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllProviderApplications() {
    return _supabase
        .from('provider_applications')
        .stream(primaryKey: ['userId'])
        .order('appliedAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllBookings() {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPayments() {
    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Future<void> updateBookingStatusAsAdmin({
    required String bookingId,
    required String status,
    String? adminNote,
  }) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized');
    await _supabase
        .from('bookings')
        .update({
          'status': status.trim().toLowerCase(),
          'adminNote': adminNote,
          'adminUpdatedBy': currentUid,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .eq('id', bookingId);
  }

  Future<void> updateBookingStatusAsProvider({
    required String bookingId,
    required String status,
  }) async {
    if (currentUid == null) throw Exception('Not authenticated');
    final updateData = {
      'status': status.trim().toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'completed') {
      updateData['paymentStatus'] = 'paid';
    }
    await _supabase.from('bookings').update(updateData).eq('id', bookingId);
  }

  // ---- NEW: COMPLETE TASK & PAYMENTS logic ----
  Future<void> confirmTaskCompleted(String bookingId) async {
    if (currentUid == null) throw Exception("Not logged in");

    final booking = await _supabase
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .maybeSingle();
    if (booking == null) throw Exception("Booking not found");

    final providerId = booking['providerId'];
    final amount = (booking['estimatedAmount'] as num).toDouble();

    // Perform Deduction & Escrow Transfer (simulating transaction)
    await topUpWallet(
      amount: amount,
      method: 'booking_revenue',
      currency: 'UGX',
      overrideUserId: providerId,
    );

    // Wait, the customer's wallet must be deducted.
    await _supabase.rpc(
      'deduct_wallet',
      params: {'uid': currentUid!, 'deduct_amount': amount},
    );
    // Wait, Supabase doesn't have this RPC by default. Let's just do an update query here.

    final customerWallet = await _supabase
        .from('wallets')
        .select('balance')
        .eq('userId', currentUid!)
        .maybeSingle();
    final newBal = (customerWallet?['balance'] ?? 0) - amount;
    await _supabase
        .from('wallets')
        .update({'balance': newBal})
        .eq('userId', currentUid!);

    // Log the transaction for customer
    await _supabase.from('wallet_transactions').insert({
      'userId': currentUid,
      'type': 'debit',
      'amount': amount,
      'description': 'Payment for Booking',
    });

    await _supabase
        .from('bookings')
        .update({
          'status': 'completed',
          'paymentStatus': 'paid',
          'paidAmount': amount,
          'customerConfirmation': 'confirmed',
          'customerConfirmedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .eq('id', bookingId);
  }

  Future<void> reportTaskDispute(String bookingId, String reason) async {
    await _supabase
        .from('bookings')
        .update({
          'status': 'disputed',
          'uncompletedReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .eq('id', bookingId);
  }

  Future<Map<String, dynamic>> getAdminReportSummary() async {
    final payments = await _supabase.from('payments').select();
    final bookings = await _supabase.from('bookings').select();
    final users = await _supabase.from('users').select('id');

    double totalRevenue = 0;
    int completedPayments = 0, pendingPayments = 0;
    int completedBookings = 0, pendingBookings = 0;

    for (var p in payments) {
      final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
      final st = (p['status'] ?? '').toString().toLowerCase();
      totalRevenue += amt;
      if (st == 'completed' || st == 'success') {
        completedPayments++;
      } else if (st == 'pending')
        pendingPayments++;
    }

    for (var b in bookings) {
      final st = (b['status'] ?? '').toString().toLowerCase();
      if (st == 'completed' || st == 'confirmed') {
        completedBookings++;
      } else if (st == 'pending')
        pendingBookings++;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalPayments': payments.length,
      'completedPayments': completedPayments,
      'pendingPayments': pendingPayments,
      'totalBookings': bookings.length,
      'completedBookings': completedBookings,
      'pendingBookings': pendingBookings,
      'totalUsers': users.length,
    };
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getAppSettingsStream() {
    return _supabase
        .from('app_settings')
        .stream(primaryKey: ['id'])
        .eq('id', 'general')
        .map((e) {
          if (e.isEmpty) return _toDocSnapshot(null, 'general');
          return _toDocSnapshot(e.first, 'general');
        });
  }

  Future<void> updateAppSettings({required Map<String, dynamic> values}) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized');
    await _supabase.from('app_settings').upsert({
      'id': 'general',
      'values': values,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUid,
    });
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized');
    await _supabase
        .from('users')
        .update({'role': newRole, 'updatedAt': FieldValue.serverTimestamp()})
        .eq('id', userId);
  }

  Future<void> updateProviderApplicationStatus(
    String userId,
    String status,
    String? adminNotes,
  ) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized');
    await _supabase
        .from('provider_applications')
        .update({
          'status': status,
          'adminNotes': adminNotes,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUid,
        })
        .eq('userId', userId);

    await _supabase
        .from('users')
        .update({
          'providerStatus': status,
          'role': status == 'approved' ? 'provider' : 'customer',
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .eq('id', userId);

    await createNotification(
      userId: userId,
      title: status == 'approved'
          ? 'Application Approved'
          : 'Application Updated',
      message: 'Your provider application status is now "$status".',
      type: 'provider_application',
      data: {'status': status},
    );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final users = await _supabase.from('users').select('id, role');
    final apps = await _supabase
        .from('provider_applications')
        .select('userId, status');

    int providers = users.where((u) => u['role'] == 'provider').length;
    int pending = apps.where((a) => a['status'] == 'pending').length;

    return {
      'totalUsers': users.length,
      'totalProviders': providers,
      'pendingApplications': pending,
      'totalApplications': apps.length,
    };
  }

  Future<void> submitProviderApplication({
    required String serviceCategory,
    required String specialization,
    required String experience,
    required String description,
    required String phonenumber,
    required String imageUrl,
    required String city,
    required String address,
    required String hourlyRate,
    required List<String> serviceAreas,
    required List<String> workingDays,
    required String idFront,
    required String idBack,
    required String certificate,
    required List<String> businessImages,
    required String vehicleType,
    required String licensePlate,
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');
    final user = _supabase.auth.currentUser!;
    await _supabase.from('provider_applications').upsert({
      'userId': currentUid,
      'userEmail': user.email ?? '',
      'serviceCategory': serviceCategory,
      'specialization': specialization,
      'experience': experience,
      'description': description,
      'phonenumber': phonenumber,
      'imageUrl': imageUrl,
      'city': city,
      'address': address,
      'hourlyRate': hourlyRate,
      'serviceAreas': serviceAreas,
      'workingDays': workingDays,
      'idFront': idFront,
      'idBack': idBack,
      'certificate': certificate,
      'businessImages': businessImages,
      'status': 'pending',
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (licensePlate != null) 'licensePlate': licensePlate,
    });
  }

  Future<void> createBooking({
    required String providerId,
    required String date,
    required String time,
    required String details,
    required String serviceType,
    double estimatedAmount = 0,
    String currency = 'UGX',
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');
    final res = await _supabase
        .from('bookings')
        .insert({
          'customerId': currentUid,
          'providerId': providerId,
          'date': date,
          'time': time,
          'details': details,
          'serviceType': serviceType,
          'status': 'pending',
          'estimatedAmount': estimatedAmount,
          'currency': currency,
        })
        .select('id')
        .single();

    final bookingId = res['id'];

    await createNotification(
      userId: currentUid!,
      title: 'Booking Submitted',
      message: 'Your booking request has been sent successfully.',
      type: 'booking',
      data: {'bookingId': bookingId, 'providerId': providerId},
    );

    await createNotification(
      userId: providerId,
      title: 'New Booking Request',
      message: 'You have received a new booking request.',
      type: 'booking',
      data: {'bookingId': bookingId, 'customerId': currentUid},
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCustomerBookingsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('customerId', currentUid!)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPaymentsHistoryStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('userId', currentUid!)
        .map(_toQuerySnapshot);
  }

  Future<void> createPaymentRecord({
    required double amount,
    required String type,
    required String status,
    required String method,
    String currency = 'UGX',
    String? bookingId,
    String? providerId,
    String? reference,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');
    await _supabase.from('payments').insert({
      'userId': currentUid,
      'bookingId': bookingId,
      'providerId': providerId,
      'amount': amount,
      'currency': currency,
      'type': type,
      'status': status,
      'method': method,
      'reference': reference,
      'metadata': metadata ?? {},
    });
  }

  Future<void> saveService({
    required String providerId,
    required Map<String, dynamic> providerData,
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');
    final docId = '${currentUid}_$providerId';
    await _supabase.from('saved_services').upsert({
      'id': docId,
      'userId': currentUid,
      'providerId': providerId,
      'providerData': providerData,
    });
  }

  Future<void> unsaveService(String providerId) async {
    if (currentUid == null) throw Exception('User not authenticated');
    final docId = '${currentUid}_$providerId';
    await _supabase.from('saved_services').delete().eq('id', docId);
  }

  Future<bool> isServiceSaved(String providerId) async {
    if (currentUid == null) return false;
    final docId = '${currentUid}_$providerId';
    final res = await _supabase
        .from('saved_services')
        .select('id')
        .eq('id', docId)
        .limit(1);
    return res.isNotEmpty;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSavedServicesStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('saved_services')
        .stream(primaryKey: ['id'])
        .eq('userId', currentUid!)
        .map(_toQuerySnapshot);
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _supabase.from('notifications').insert({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'data': data ?? {},
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream({
    bool unreadOnly = false,
  }) {
    final currentUid = Supabase.instance.client.auth.currentUser?.id;
    if (currentUid == null) return const Stream.empty();

    var query = _supabase
        .from('notifications')
        .select()
        .eq('userId', currentUid);

    if (unreadOnly) {
      query = query.eq('isRead', false);
    }

    return query.asStream().map(_toQuerySnapshot);
  }

  Stream<int> getUnreadNotificationsCountStream() {
    return getNotificationsStream(unreadOnly: true).map((s) => s.docs.length);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'isRead': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsAsRead() async {
    if (currentUid == null) return;
    await _supabase
        .from('notifications')
        .update({'isRead': true})
        .eq('userId', currentUid!);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _supabase.from('notifications').delete().eq('id', notificationId);
  }

  Future<void> clearAllNotifications() async {
    if (currentUid == null) return;
    await _supabase.from('notifications').delete().eq('userId', currentUid!);
  }

  Future<void> ensureWalletExists([String? overrideUserId]) async {
    final targetId = overrideUserId ?? currentUid;
    if (targetId == null) throw Exception('User not authenticated');
    final res = await _supabase
        .from('wallets')
        .select()
        .eq('userId', targetId)
        .maybeSingle();
    if (res == null) {
      await _supabase.from('wallets').insert({
        'userId': targetId,
        'balance': 0.0,
        'currency': 'UGX',
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getWalletStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('wallets')
        .stream(primaryKey: ['userId'])
        .eq('userId', currentUid!)
        .map((e) {
          if (e.isEmpty) return _toDocSnapshot(null, currentUid!);
          return _toDocSnapshot(e.first, currentUid!);
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getWalletTransactionsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .eq('userId', currentUid!)
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Future<void> topUpWallet({
    required double amount,
    String method = 'mobile_money',
    String currency = 'UGX',
    String? overrideUserId,
  }) async {
    final targetId = overrideUserId ?? currentUid;
    if (targetId == null) throw Exception('User not authenticated');
    if (amount <= 0) throw Exception('Amount must be greater than zero');

    final wallet = await _supabase
        .from('wallets')
        .select()
        .eq('userId', targetId)
        .maybeSingle();
    double currentBal = wallet != null
        ? (wallet['balance'] as num).toDouble()
        : 0.0;

    await _supabase.from('wallets').upsert({
      'userId': targetId,
      'balance': currentBal + amount,
      'currency': currency,
    });

    await _supabase.from('wallet_transactions').insert({
      'userId': targetId,
      'type': 'credit',
      'amount': amount,
      'currency': currency,
      'method': method,
      'description': 'Wallet credit',
    });
  }

  Future<void> sendMessageToUser({
    required String recipientId,
    required String message,
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');
    final participants = [currentUid!, recipientId]..sort();
    final chatId = participants.join('_');

    await _supabase.from('chats').upsert({
      'id': chatId,
      'participants': participants,
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _supabase.from('messages').insert({
      'chatId': chatId,
      'senderId': currentUid,
      'message': message,
    });

    await createNotification(
      userId: recipientId,
      title: 'New Message',
      message: message.length > 80 ? '${message.substring(0, 80)}...' : message,
      type: 'chat',
      data: {'chatId': chatId, 'senderId': currentUid},
    );
  }

  Future<void> sendMessage({
    required String providerId,
    required String message,
  }) async {
    await sendMessageToUser(recipientId: providerId, message: message);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatStream(
    String recipientId,
  ) {
    if (currentUid == null) return const Stream.empty();
    final participants = [currentUid!, recipientId]..sort();
    final chatId = participants.join('_');
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chatId', chatId)
        .order('timestamp', ascending: true)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderBookingsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('providerId', currentUid!)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderReviewsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('providerId', currentUid!)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderChatsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('lastMessageTime', ascending: false)
        .map((rows) {
          final filtered = rows.where((chat) {
            final participants =
                (chat['participants'] as List?)?.cast<String>() ?? [];
            return participants.contains(currentUid);
          }).toList();
          return _toQuerySnapshot(filtered);
        });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  getProviderApplicationStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('provider_applications')
        .stream(primaryKey: ['userId'])
        .eq('userId', currentUid!)
        .map((rows) {
          if (rows.isEmpty) return _toDocSnapshot(null, currentUid!);
          return _toDocSnapshot(rows.first, currentUid!);
        });
  }

  Future<void> addProviderBusinessImage(String url) async {
    if (currentUid == null) throw Exception('Not authenticated');
    final app = await _supabase
        .from('provider_applications')
        .select()
        .eq('userId', currentUid!)
        .maybeSingle();
    if (app == null) throw Exception('Provider application not found');
    final images = (app['businessImages'] as List?)?.cast<String>() ?? [];
    if (!images.contains(url)) {
      images.add(url);
      await _supabase
          .from('provider_applications')
          .update({
            'businessImages': images,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .eq('userId', currentUid!);
    }
  }

  Future<void> removeProviderBusinessImage(String url) async {
    if (currentUid == null) throw Exception('Not authenticated');
    final app = await _supabase
        .from('provider_applications')
        .select()
        .eq('userId', currentUid!)
        .maybeSingle();
    if (app == null) throw Exception('Provider application not found');
    final images = (app['businessImages'] as List?)?.cast<String>() ?? [];
    images.remove(url);
    await _supabase
        .from('provider_applications')
        .update({
          'businessImages': images,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .eq('userId', currentUid!);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderPaymentsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('providerId', currentUid!)
        .map(_toQuerySnapshot);
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> getReviewForBooking(
    String bookingId,
  ) async {
    if (currentUid == null) return null;
    final res = await _supabase
        .from('reviews')
        .select()
        .eq('bookingId', bookingId)
        .eq('customerId', currentUid!)
        .limit(1);
    if (res.isEmpty) return null;
    return _toQuerySnapshot(res).docs.first;
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String method,
    String? mobileMoneyNumber,
    String? bankName,
    String? bankAccount,
  }) async {
    if (currentUid == null) throw Exception('Not authenticated');

    // Insert to withdrawal_requests
    await _supabase.from('withdrawal_requests').insert({
      'userId': currentUid,
      'amount': amount,
      'method': method,
      'mobileMoneyNumber': mobileMoneyNumber,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'status': 'pending',
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getWithdrawalRequestsStream() {
    return _supabase
        .from('withdrawal_requests')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyWithdrawalsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase
        .from('withdrawal_requests')
        .stream(primaryKey: ['id'])
        .eq('userId', currentUid!)
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Future<void> processWithdrawalAsAdmin({
    required String withdrawalId,
    required String status,
    String? adminNote,
  }) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized');

    final req = await _supabase
        .from('withdrawal_requests')
        .select()
        .eq('id', withdrawalId)
        .maybeSingle();
    if (req == null) throw Exception('Not found');
    if (req['status'] != 'pending') throw Exception('Already processed');

    await _supabase
        .from('withdrawal_requests')
        .update({
          'status': status,
          'adminNote': adminNote,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .eq('id', withdrawalId);

    if (status == 'approved') {
      // Deduct permanently from wallet
      final userId = req['userId'];
      final amount = (req['amount'] as num).toDouble();
      final wallet = await _supabase
          .from('wallets')
          .select('balance')
          .eq('userId', userId)
          .maybeSingle();
      if (wallet != null) {
        final newBal = (wallet['balance'] as num).toDouble() - amount;
        await _supabase
            .from('wallets')
            .update({'balance': newBal})
            .eq('userId', userId);

        await _supabase.from('wallet_transactions').insert({
          'userId': userId,
          'type': 'debit',
          'amount': amount,
          'method': req['method'],
          'description': 'Withdrawal approved',
        });
      }
    }
  }

  Future<void> confirmBookingCompletion({
    required String bookingId,
    required bool isCompleted,
    String? uncompletedReason,
  }) async {
    await _supabase
        .from('bookings')
        .update({
          'status': isCompleted ? 'completed' : 'issue_reported',
          'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
          'uncompletedReason': uncompletedReason,
          'updatedAt': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId);
  }

  Future<void> processServicePayment({
    required String bookingId,
    required String providerId,
    required double amount,
  }) async {
    // Update booking payment status
    await _supabase
        .from('bookings')
        .update({
          'paymentStatus': 'paid',
          'updatedAt': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId);

    // Add to provider's wallet
    final wallet = await _supabase
        .from('wallets')
        .select('balance')
        .eq('userId', providerId)
        .maybeSingle();
    final currentBalance = (wallet?['balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = currentBalance + amount;

    if (wallet != null) {
      await _supabase
          .from('wallets')
          .update({'balance': newBalance})
          .eq('userId', providerId);
    } else {
      await _supabase.from('wallets').insert({
        'userId': providerId,
        'balance': amount,
      });
    }

    // Record transaction
    await _supabase.from('wallet_transactions').insert({
      'userId': providerId,
      'type': 'credit',
      'amount': amount,
      'method': 'service_payment',
      'description': 'Payment for completed service',
    });

    // Create payment record
    await _supabase.from('payments').insert({
      'bookingId': bookingId,
      'userId': providerId,
      'amount': amount,
      'status': 'completed',
      'type': 'service_payment',
    });
  }

  Future<void> submitReview({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    final currentUid = Supabase.instance.client.auth.currentUser?.id;
    if (currentUid == null) throw 'User not authenticated';

    // Get booking details
    final booking = await _supabase
        .from('bookings')
        .select('providerId')
        .eq('id', bookingId)
        .single();

    await _supabase.from('reviews').insert({
      'bookingId': bookingId,
      'customerId': currentUid,
      'providerId': booking['providerId'],
      'rating': rating,
      'comment': comment,
      'reviewedAt': DateTime.now().toIso8601String(),
    });
  }
}
