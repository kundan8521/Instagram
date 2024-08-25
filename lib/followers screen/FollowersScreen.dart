import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FollowersScreen extends StatelessWidget {
  final String uid;

  const FollowersScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('followers')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          var followersDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: followersDocs.length,
            itemBuilder: (context, index) {
              var followerId = followersDocs[index].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followerId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(Icons.person, color: Colors.grey.shade400),
                      ),
                      title: Text('Loading...', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  var followerData = snapshot.data!.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: followerData['profileImageUrl'] != null
                            ? NetworkImage(followerData['profileImageUrl'])
                            : AssetImage('assets/default_profile.png') as ImageProvider,
                      ),
                      title: Text(
                        followerData['name'],
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      subtitle: Text(
                        followerData['email'],
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'remove') {
                            _removeFollower(followerId, context);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.remove_circle, color: Colors.redAccent),
                                  SizedBox(width: 10),
                                  Text('Remove', style: TextStyle(color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ];
                        },
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
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

  void _removeFollower(String followerId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('followers')
          .doc(followerId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Follower removed successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove follower: $e', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
      );
    }
  }
}
