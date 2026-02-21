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
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final chatId = _generateChatId(currentUid!, providerId);

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUid,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
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
