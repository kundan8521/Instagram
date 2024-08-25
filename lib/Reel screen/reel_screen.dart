import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../comment screen/CommentScreen.dart';

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String profileImageUrl;
  final String username;
  final String userId;

  const ReelVideoPlayer({
    required this.videoUrl,
    required this.profileImageUrl,
    required this.username,
    required this.userId,
  });

  @override
  _ReelVideoPlayerState createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _showControls = true;
  bool _isFollowing = false;
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  Timer? _hideControlsTimer;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
      _controller.setLooping(true);
    });
    _checkIfFollowing();
    _fetchLikeAndCommentData();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _checkIfFollowing() async {
    final followingDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(widget.userId)
        .get();

    setState(() {
      _isFollowing = followingDoc.exists;
    });
  }

  Future<void> _toggleFollow() async {
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final userToFollowRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    if (_isFollowing) {
      await currentUserRef.collection('following').doc(widget.userId).delete();
      await userToFollowRef.collection('followers').doc(currentUserId).delete();
    } else {
      await currentUserRef.collection('following').doc(widget.userId).set({});
      await userToFollowRef.collection('followers').doc(currentUserId).set({});
    }

    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  String generateVideoId(String videoUrl) {
    return md5.convert(utf8.encode(videoUrl)).toString();
  }

  Future<void> _fetchLikeAndCommentData() async {
    final videoId = generateVideoId(widget.videoUrl);
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(videoId);
    final likeDoc = await videoRef.collection('likes').doc(currentUserId).get();
    final videoDoc = await videoRef.get();

    setState(() {
      _isLiked = likeDoc.exists;
      _likeCount = videoDoc['likeCount'] ?? 0;
      _commentCount = videoDoc['commentCount'] ?? 0;
    });
  }

  Future<void> _refreshData() async {
    await _fetchLikeAndCommentData();
  }

  Future<void> _toggleLike() async {
    final videoId = generateVideoId(widget.videoUrl);
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(videoId);

    setState(() {
      if (_isLiked) {
        _likeCount--;
      } else {
        _likeCount++;
      }
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      await videoRef.collection('likes').doc(currentUserId).set({});
      await videoRef.update({'likeCount': FieldValue.increment(1)});
    } else {
      await videoRef.collection('likes').doc(currentUserId).delete();
      await videoRef.update({'likeCount': FieldValue.increment(-1)});
    }
  }

  Future<void> _addComment(String comment) async {
    final videoId = generateVideoId(widget.videoUrl);
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(videoId);

    await videoRef.collection('comments').add({
      'userId': currentUserId,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update comment count
    await videoRef.update({'commentCount': FieldValue.increment(1)});

    // Refresh data
    await _refreshData();
  }

  void _openCommentScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(videoUrl: widget.videoUrl),
      ),
    );
    // Refresh data after returning from the comment screen
    await _refreshData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
              if (_showControls) {
                _startHideControlsTimer();
              }
            },
            child: Stack(
              children: [
                Center(
                  child: _controller.value.isInitialized
                      ? SizedBox(
                    width: screenSize.width,
                    height: screenSize.height,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                      : CircularProgressIndicator(),
                ),
                if (_showControls)
                  Center(
                    child: IconButton(
                      iconSize: 60,
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                            _startHideControlsTimer();
                          }
                        });
                      },
                    ),
                  ),
                Positioned(
                  bottom: 100,
                  right: 10,
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.white,
                          size: 30,
                        ),
                        onPressed: _toggleLike,
                      ),

                      SizedBox(height: 10),
                      IconButton(
                        icon: Icon(
                          Icons.comment,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _openCommentScreen,
                      ),

                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 10,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.profileImageUrl.isNotEmpty
                            ? NetworkImage(widget.profileImageUrl)
                            : null,
                        child: widget.profileImageUrl.isEmpty
                            ? Icon(Icons.person, size: 20, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.username,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        height: 30,
                        child: OutlinedButton(
                          onPressed: _toggleFollow,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            side: BorderSide(
                              color: Colors.white,
                            ),
                          ),
                          child: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading video: ${snapshot.error}'));
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  strokeWidth: 6.0,
                ),
                SizedBox(height: 10),
                Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

