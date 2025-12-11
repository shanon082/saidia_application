import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/screens/admin/adminDashboard.dart';
import 'package:saidia_app/screens/customers/customerDashboard.dart';
import 'package:saidia_app/screens/provider/providerDashboard.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final role = snapshot.data!.get('role') as String;

        if (role == 'admin') {
          return const AdminDashboard();
        } else if (role == 'provider') {
          return const ProviderDashboard();
        } else {
          return const CustomerDashboard();
        }
      },
    );
  }
}