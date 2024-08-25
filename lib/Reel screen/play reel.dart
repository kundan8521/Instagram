import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram/Reel%20screen/reel_screen.dart';

class ReelScreen extends StatefulWidget {
  @override
  _ReelScreenState createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reels')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
            return Center(child: Text('No reels available.'));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: snapshot.data?.docs.length ?? 0,
            itemBuilder: (context, index) {
              final reel = snapshot.data?.docs[index];
              final videoUrl = reel?.get('videoUrl') as String?;
              final userId = reel?.get('userId') as String?;

              if (videoUrl == null || userId == null) {
                return Center(child: Text('Invalid reel data.'));
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError) {
                    return Center(child: Text('Error: ${userSnapshot.error}'));
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Center(child: Text('No user data found.'));
                  }

                  final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final String profileImageUrl = userData?['profileImageUrl'] ?? '';
                  final String username = userData?['name'] ?? 'No Name';

                  return SafeArea(
                    child: ReelVideoPlayer(
                      videoUrl: videoUrl,
                      profileImageUrl: profileImageUrl,
                      username: username,
                      userId: userId,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}