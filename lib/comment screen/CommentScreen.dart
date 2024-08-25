import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CommentScreen extends StatefulWidget {
  final String videoUrl;

  const CommentScreen({required this.videoUrl});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late CollectionReference _commentsRef;

  @override
  void initState() {
    super.initState();
    String videoId = generateVideoId(widget.videoUrl);
    _commentsRef = FirebaseFirestore.instance.collection('videos').doc(videoId).collection('comments');
  }

  String generateVideoId(String videoUrl) {
    return md5.convert(utf8.encode(videoUrl)).toString();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    await _commentsRef.add({
      'userId': currentUserId,
      'comment': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  Future<void> _editComment(String commentId, String newComment) async {
    await _commentsRef.doc(commentId).update({'comment': newComment});
  }

  Future<void> _deleteComment(String commentId) async {
    await _commentsRef.doc(commentId).delete();
  }

  void _showEditDialog(String commentId, String currentComment) {
    _commentController.text = currentComment;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Comment'),
        content: TextField(
          controller: _commentController,
          decoration: InputDecoration(hintText: 'Edit your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.teal)),
          ),
          TextButton(
            onPressed: () {
              _editComment(commentId, _commentController.text.trim());
              _commentController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Save', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.teal)),
          ),
          TextButton(
            onPressed: () {
              _deleteComment(commentId);
              Navigator.of(context).pop();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _commentsRef.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No comments yet.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final commentDoc = snapshot.data!.docs[index];
                    final commentData = commentDoc.data() as Map<String, dynamic>;
                    final commentId = commentDoc.id;
                    final isCurrentUser = commentData['userId'] == currentUserId;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(commentData['userId'][0].toUpperCase(), style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.teal,
                      ),
                      title: Text(commentData['comment']),
                      subtitle: Text(
                        commentData['timestamp']?.toDate().toLocal().toString() ?? 'Just now',
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: isCurrentUser
                          ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(commentId, commentData['comment']);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(commentId);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
