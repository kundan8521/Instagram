import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Reels',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

        ),
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ),
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No videos available.'));
          }

          final videos = snapshot.data!.docs.where((doc) {
            final videoUrl = doc['videoUrl'].toString().toLowerCase();
            return videoUrl.contains(_searchQuery);
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Three items per row
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final videoData = video.data() as Map<String, dynamic>;
              final videoUrl = videoData['videoUrl'];
              final thumbnailUrl = videoData.containsKey('thumbnailUrl')
                  ? videoData['thumbnailUrl']
                  : 'https://via.placeholder.com/150'; // Placeholder image

              return VideoThumbnail(
                videoUrl: videoUrl,
                thumbnailUrl: thumbnailUrl,
              );
            },
          );
        },
      ),
    );
  }
}

class VideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final String thumbnailUrl;

  VideoThumbnail({required this.videoUrl, required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoReelScreen(initialVideoUrl: videoUrl),
          ),
        );
      },
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: thumbnailUrl,
            placeholder: (context, url) =>
                Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.error),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 50,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class VideoReelScreen extends StatelessWidget {
  final String initialVideoUrl;

  VideoReelScreen({required this.initialVideoUrl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('reels').orderBy('timestamp', descending: true).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white))),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text('No videos available.', style: TextStyle(color: Colors.white))),
          );
        }

        final videos = snapshot.data!.docs;

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            final videoData = video.data() as Map<String, dynamic>;
            final videoUrl = videoData['videoUrl'];
            return VideoPlayerScreen(videoUrl: videoUrl);
          },
        );
      },
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  VideoPlayerScreen({required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Ensure the video is displayed when ready
        _controller.play(); // Start playing the video
        _hideControlsAfterDelay(); // Hide controls after delay
      });
  }

  void _hideControlsAfterDelay() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
              if (_showControls) {
                _hideControlsAfterDelay();
              }
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              if (_showControls)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}
