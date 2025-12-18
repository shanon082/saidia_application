import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // Create user profile after successful signup
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First, try to create the document
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

      print('User profile created successfully for UID: $currentUid');
    } catch (e, stackTrace) {
      print('Error creating user profile: $e');
      print('Stack trace: $stackTrace');

      // Check if document already exists
      final doc = await _firestore.collection('users').doc(currentUid).get();
      if (doc.exists) {
        print('Document already exists, updating instead');
        await _firestore.collection('users').doc(currentUid).update({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // If document doesn't exist and creation failed, rethrow
        rethrow;
      }
    }
  }

  // Check if email already exists
  Future<bool> isEmailTaken(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Check if phone already exists
  Future<bool> isPhoneTaken(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone: $e');
      return false;
    }
  }

  // Submit provider application
  // Future<void> submitProviderApplication({
  //   required String serviceCategory,
  //   required String specialization,
  //   required String experience,
  //   required String description,
  //   required String phonenumber,
  //   required String imageUrl,
  //   required String city,
  //   required String address,
  //   required String hourlyRate,
  //   required List<String> serviceAreas,
  //   required List<String> workingDays,
  //   required String idFront,
  //   required String idBack,
  //   required String certificate,
  // }) async {
  //   if (currentUid == null) {
  //     throw Exception('User not authenticated');
  //   }

  //   try {
  //     final user = _auth.currentUser!;

  //     await _firestore.collection('provider_applications').doc(currentUid).set({
  //       'userId': currentUid,
  //       'userEmail': user.email ?? '',
  //       'serviceCategory': serviceCategory,
  //       'specialization': specialization,
  //       'experience': experience,
  //       'description': description,
  //       'phonenumber': phonenumber,
  //       'imageUrl': imageUrl,
  //       'city': city,
  //       'address': address,
  //       'hourlyRate': hourlyRate,
  //       'serviceAreas': serviceAreas,
  //       'workingDays': workingDays,
  //       'idFront': idFront,
  //       'idBack': idBack,
  //       'certificate': certificate,
  //       'status': 'pending',
  //       'appliedAt': FieldValue.serverTimestamp(),
  //     });

  //     print('Provider application submitted for UID: $currentUid');
  //   } catch (e, stackTrace) {
  //     print('Error submitting provider application: $e');
  //     print('Stack trace: $stackTrace');
  //     rethrow;
  //   }
  // }

  // Apply as provider (update user document)
  Future<void> applyAsProvider() async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('users').doc(currentUid).update({
        'providerStatus': 'pending',
        'providerApplicationDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('User provider status updated to pending for UID: $currentUid');
    } catch (e, stackTrace) {
      print('Error applying as provider: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get user document stream
  Stream<DocumentSnapshot> getUserStream() {
    if (currentUid == null) {
      return Stream.empty();
    }

    try {
      return _firestore
          .collection('users')
          .doc(currentUid)
          .snapshots()
          .handleError((error) {
            print('Error in getUserStream: $error');
          });
    } catch (e) {
      print('Error creating user stream: $e');
      return Stream.empty();
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    if (currentUid == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Create admin account (only for initial setup)
  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // First create the user in Firebase Auth
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = authResult.user!;

      // Create admin profile in Firestore
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

      print('Admin account created successfully for: $email');
    } catch (e) {
      print('Error creating admin account: $e');
      rethrow;
    }
  }

  // Get all provider applications
  Stream<QuerySnapshot> getAllProviderApplications() {
    return _firestore
        .collection('provider_applications')
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }

  // Get all users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String userId, String newRole) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Only admins can update user roles');
    }

    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update provider application status
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

    // Also update the user's providerStatus
    await _firestore.collection('users').doc(userId).update({
      'providerStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If approved, update user role to provider
    if (status == 'approved') {
      await _firestore.collection('users').doc(userId).update({
        'role': 'provider',
      });
    }
  }

  // Get statistics
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
    required List<String> businessImages, // New parameter
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    try {
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
        'businessImages': businessImages, // New field
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      print('Provider application submitted for UID: $currentUid');
    } catch (e, stackTrace) {
      print('Error submitting provider application: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // New: Create a booking
  Future<void> createBooking({
    required String providerId,
    required String date,
    required String time,
    required String details,
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('bookings').add({
        'customerId': currentUid,
        'providerId': providerId,
        'date': date,
        'time': time,
        'details': details,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Booking created successfully');
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  // New: Send a chat message
  Future<void> sendMessage({
    required String providerId,
    required String message,
  }) async {
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    final chatId = _generateChatId(currentUid!, providerId);

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': currentUid,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // New: Get chat messages stream
  Stream<QuerySnapshot> getChatStream(String providerId) {
    if (currentUid == null) {
      return Stream.empty();
    }

    final chatId = _generateChatId(currentUid!, providerId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Helper to generate unique chat ID
  String _generateChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
