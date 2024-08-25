import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FollowingScreen extends StatelessWidget {
  final String userId;

  FollowingScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Following', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white))),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('following')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No following.', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final followedUserId = snapshot.data!.docs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(followedUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text('Unknown User', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final String username = userData['name'] ?? 'No Name';
                  final String profileImageUrl = userData['profileImageUrl'] ?? '';

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty ? Icon(Icons.person, size: 30) : null,
                      ),
                      title: Text(
                        username,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'unfollow') {
                            _unfollowUser(followedUserId, context);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'unfollow',
                              child: Text('Unfollow', style: TextStyle(color: Colors.red)),
                            ),
                          ];
                        },
                        icon: Icon(Icons.more_vert, color: Colors.teal),
                      ),
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

  void _unfollowUser(String followedUserId, BuildContext context) async {
    try {
      // Remove the user from the current user's following collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(followedUserId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unfollowed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfollow: $e')),
      );
    }
  }
}
