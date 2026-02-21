import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('users').doc(currentUid).set({
        'uid': currentUid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': 'customer',
        'providerStatus': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      await ensureWalletExists();
    } catch (e) {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      if (doc.exists) {
        await _firestore.collection('users').doc(currentUid).update({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await ensureWalletExists();
      } else {
        rethrow;
      }
    }
  }

  Future<bool> isEmailTaken(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPhoneTaken(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> applyAsProvider() async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('users').doc(currentUid).update({
      'providerStatus': 'pending',
      'providerApplicationDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    if (currentUid == null) {
      return const Stream.empty();
    }

    return _firestore.collection('users').doc(currentUid).snapshots();
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<bool> isUserAdmin() async {
    if (currentUid == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final authResult = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = authResult.user!;

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': 'admin',
      'providerStatus': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllProviderApplications() {
    return _firestore
        .collection('provider_applications')
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Only admins can update user roles');
    }

    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProviderApplicationStatus(
    String userId,
    String status,
    String? adminNotes,
  ) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Only admins can update applications');
    }

    await _firestore.collection('provider_applications').doc(userId).update({
      'status': status,
      'adminNotes': adminNotes,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': currentUid,
    });

    await _firestore.collection('users').doc(userId).update({
      'providerStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved') {
      await _firestore.collection('users').doc(userId).update({
        'role': 'provider',
      });
    }

    await createNotification(
      userId: userId,
      title: status == 'approved'
          ? 'Application Approved'
          : 'Application Updated',
      message: status == 'approved'
          ? 'Your provider application was approved. You can now start offering services.'
          : 'Your provider application status is now "$status".',
      type: 'provider_application',
      data: {'status': status},
    );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final applicationsSnapshot = await _firestore
        .collection('provider_applications')
        .get();
    final pendingApplications = applicationsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'pending')
        .length;

    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalProviders': usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'provider')
          .length,
      'pendingApplications': pendingApplications,
      'totalApplications': applicationsSnapshot.docs.length,
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
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final user = _auth.currentUser!;

    await _firestore.collection('provider_applications').doc(currentUid).set({
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
      'appliedAt': FieldValue.serverTimestamp(),
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
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final bookingRef = await _firestore.collection('bookings').add({
      'customerId': currentUid,
      'providerId': providerId,
      'date': date,
      'time': time,
      'details': details,
      'serviceType': serviceType,
      'status': 'pending',
      'estimatedAmount': estimatedAmount,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      userId: currentUid!,
      title: 'Booking Submitted',
      message: 'Your booking request has been sent successfully.',
      type: 'booking',
      data: {'bookingId': bookingRef.id, 'providerId': providerId},
    );

    await createNotification(
      userId: providerId,
      title: 'New Booking Request',
      message: 'You have received a new booking request.',
      type: 'booking',
      data: {'bookingId': bookingRef.id, 'customerId': currentUid},
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCustomerBookingsStream() {
    if (currentUid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: currentUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPaymentsHistoryStream() {
    if (currentUid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: currentUid)
        .snapshots();
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
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('payments').add({
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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _savedServiceDocId(String userId, String providerId) =>
      '${userId}_$providerId';

  Future<void> saveService({
    required String providerId,
    required Map<String, dynamic> providerData,
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final docId = _savedServiceDocId(currentUid!, providerId);
    await _firestore.collection('saved_services').doc(docId).set({
      'userId': currentUid,
      'providerId': providerId,
      'providerData': providerData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsaveService(String providerId) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final docId = _savedServiceDocId(currentUid!, providerId);
    await _firestore.collection('saved_services').doc(docId).delete();
  }

  Future<bool> isServiceSaved(String providerId) async {
    if (currentUid == null) return false;

    final docId = _savedServiceDocId(currentUid!, providerId);
    final doc = await _firestore.collection('saved_services').doc(docId).get();
    return doc.exists;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSavedServicesStream() {
    if (currentUid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('saved_services')
        .where('userId', isEqualTo: currentUid)
        .snapshots();
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'data': data ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream({
    bool unreadOnly = false,
  }) {
    if (currentUid == null) {
      return const Stream.empty();
    }

    final query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUid);

    return query.snapshots();
  }

  Stream<int> getUnreadNotificationsCountStream() {
    return getNotificationsStream().map(
      (snapshot) => snapshot.docs
          .where((doc) => (doc.data()['isRead'] as bool?) == false)
          .length,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllNotificationsAsRead() async {
    if (currentUid == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      if ((doc.data()['isRead'] as bool?) != true) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> clearAllNotifications() async {
    if (currentUid == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> ensureWalletExists() async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final walletRef = _firestore.collection('wallets').doc(currentUid);
    final walletDoc = await walletRef.get();

    if (!walletDoc.exists) {
      await walletRef.set({
        'userId': currentUid,
        'balance': 0.0,
        'currency': 'UGX',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getWalletStream() {
    if (currentUid == null) {
      return const Stream.empty();
    }

    return _firestore.collection('wallets').doc(currentUid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getWalletTransactionsStream() {
    if (currentUid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('wallets')
        .doc(currentUid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> topUpWallet({
    required double amount,
    String method = 'mobile_money',
    String currency = 'UGX',
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    await ensureWalletExists();

    final walletRef = _firestore.collection('wallets').doc(currentUid);
    final walletTxRef = walletRef.collection('transactions').doc();
    final paymentRef = _firestore.collection('payments').doc();

    await _firestore.runTransaction((transaction) async {
      final walletSnapshot = await transaction.get(walletRef);
      final currentBalance =
          (walletSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final nextBalance = currentBalance + amount;

      transaction.update(walletRef, {
        'balance': nextBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(walletTxRef, {
        'userId': currentUid,
        'type': 'credit',
        'amount': amount,
        'currency': currency,
        'method': method,
        'description': 'Wallet top up',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(paymentRef, {
        'userId': currentUid,
        'amount': amount,
        'currency': currency,
        'type': 'wallet_topup',
        'status': 'completed',
        'method': method,
        'reference': paymentRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await createNotification(
      userId: currentUid!,
      title: 'Wallet Updated',
      message:
          'Your wallet has been topped up with $currency ${amount.toStringAsFixed(0)}.',
      type: 'wallet',
      data: {'amount': amount, 'currency': currency, 'method': method},
    );
  }

  Future<void> sendMessage({
    required String providerId,
    required String message,
  }) async {
    await sendMessageToUser(recipientId: providerId, message: message);
  }

  Future<void> sendMessageToUser({
    required String recipientId,
    required String message,
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final chatId = _generateChatId(currentUid!, recipientId);

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUid, recipientId],
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUid,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });

    await createNotification(
      userId: recipientId,
      title: 'New Message',
      message: message.length > 80 ? '${message.substring(0, 80)}...' : message,
      type: 'chat',
      data: {'chatId': chatId, 'senderId': currentUid},
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderBookingsStream() {
    if (currentUid == null) return const Stream.empty();

    return _firestore
        .collection('bookings')
        .where('providerId', isEqualTo: currentUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderReviewsStream() {
    if (currentUid == null) return const Stream.empty();

    return _firestore
        .collection('reviews')
        .where('providerId', isEqualTo: currentUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderChatsStream() {
    if (currentUid == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProviderPaymentsStream() {
    if (currentUid == null) return const Stream.empty();

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: currentUid)
        .snapshots();
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> getReviewForBooking(
    String bookingId,
  ) async {
    if (currentUid == null) return null;

    final snap = await _firestore
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('customerId', isEqualTo: currentUid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<void> submitReview({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      throw Exception('Booking not found');
    }

    final booking = bookingSnap.data()!;
    if (booking['customerId'] != currentUid) {
      throw Exception('Unauthorized');
    }

    final bookingStatus = (booking['status']?.toString().toLowerCase() ?? '');
    if (bookingStatus != 'confirmed' && bookingStatus != 'completed') {
      throw Exception('You can review only confirmed/completed bookings');
    }

    final providerId = booking['providerId']?.toString();
    if (providerId == null || providerId.isEmpty) {
      throw Exception('Provider is missing for this booking');
    }

    final userSnap = await _firestore.collection('users').doc(currentUid).get();
    final customerName = userSnap.data()?['name']?.toString() ?? 'Customer';

    final reviewId = '${bookingId}_$currentUid';
    await _firestore.collection('reviews').doc(reviewId).set({
      'bookingId': bookingId,
      'providerId': providerId,
      'customerId': currentUid,
      'customerName': customerName,
      'serviceType': booking['serviceType'],
      'rating': rating,
      'comment': comment.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Best-effort aggregate update; keep review submission successful even if
    // provider_applications update is blocked by rules.
    try {
      final reviewsSnap = await _firestore
          .collection('reviews')
          .where('providerId', isEqualTo: providerId)
          .get();
      final ratings = reviewsSnap.docs
          .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0.0)
          .where((v) => v > 0)
          .toList();
      final reviewCount = ratings.length;
      final avgRating = reviewCount == 0
          ? 0.0
          : ratings.reduce((a, b) => a + b) / reviewCount;

      await _firestore.collection('provider_applications').doc(providerId).set({
        'rating': avgRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    // Best-effort notification; not critical for successful review save.
    try {
      await createNotification(
        userId: providerId,
        title: 'New Review',
        message:
            '$customerName rated your service ${rating.toStringAsFixed(1)} stars.',
        type: 'review',
        data: {
          'bookingId': bookingId,
          'providerId': providerId,
          'rating': rating,
        },
      );
    } catch (_) {}
  }

  Future<void> updateBookingStatusAsProvider({
    required String bookingId,
    required String status,
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw Exception('Booking not found');
    }

    final booking = bookingSnap.data()!;
    if (booking['providerId'] != currentUid) {
      throw Exception('Unauthorized');
    }

    final previousStatus = booking['status']?.toString().toLowerCase();

    await bookingRef.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Credit provider once when moving to confirmed.
    if (status == 'confirmed' && previousStatus != 'confirmed') {
      await _creditProviderForBooking(bookingId: bookingId, booking: booking);
    }

    final customerId = booking['customerId']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      final title = status == 'confirmed'
          ? 'Booking Confirmed'
          : status == 'completed'
          ? 'Booking Completed'
          : status == 'cancelled'
          ? 'Booking Cancelled'
          : 'Booking Updated';
      final message = status == 'confirmed'
          ? 'Your booking has been confirmed by the provider.'
          : status == 'completed'
          ? 'Your booking has been marked as completed.'
          : status == 'cancelled'
          ? 'Your booking was cancelled by the provider.'
          : 'Your booking status is now $status.';
      await createNotification(
        userId: customerId,
        title: title,
        message: message,
        type: 'booking',
        data: {'bookingId': bookingId, 'providerId': currentUid},
      );
    }
  }

  Future<void> _creditProviderForBooking({
    required String bookingId,
    required Map<String, dynamic> booking,
  }) async {
    if (currentUid == null) throw Exception('User not authenticated');

    await ensureWalletExists();

    final amount = (booking['estimatedAmount'] as num?)?.toDouble() ?? 2500.0;
    if (amount <= 0) return;

    final walletRef = _firestore.collection('wallets').doc(currentUid);
    final walletTxRef = walletRef
        .collection('transactions')
        .doc('booking_$bookingId');
    final paymentRef = _firestore
        .collection('payments')
        .doc('booking_earning_${currentUid}_$bookingId');

    await _firestore.runTransaction((tx) async {
      final existingPayment = await tx.get(paymentRef);
      if (existingPayment.exists) return;

      final walletSnap = await tx.get(walletRef);
      final balance =
          (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final next = balance + amount;

      tx.update(walletRef, {
        'balance': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(walletTxRef, {
        'userId': currentUid,
        'type': 'credit',
        'amount': amount,
        'currency': booking['currency'] ?? 'UGX',
        'method': 'booking_earning',
        'description': 'Booking earning',
        'bookingId': bookingId,
        'customerId': booking['customerId'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(paymentRef, {
        'userId': currentUid,
        'providerId': currentUid,
        'bookingId': bookingId,
        'customerId': booking['customerId'],
        'amount': amount,
        'currency': booking['currency'] ?? 'UGX',
        'type': 'booking_earning',
        'status': 'completed',
        'method': 'wallet_credit',
        'reference': paymentRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addProviderBusinessImage(String imageUrl) async {
    if (currentUid == null) throw Exception('User not authenticated');

    await _firestore.collection('provider_applications').doc(currentUid).set({
      'businessImages': FieldValue.arrayUnion([imageUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeProviderBusinessImage(String imageUrl) async {
    if (currentUid == null) throw Exception('User not authenticated');

    await _firestore.collection('provider_applications').doc(currentUid).set({
      'businessImages': FieldValue.arrayRemove([imageUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  getProviderApplicationStream() {
    if (currentUid == null) return const Stream.empty();
    return _firestore
        .collection('provider_applications')
        .doc(currentUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatStream(String providerId) {
    if (currentUid == null) {
      return const Stream.empty();
    }

    final chatId = _generateChatId(currentUid!, providerId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  String _generateChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
