import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import '../EditProfileScreen/edit_profile_screen.dart';
import '../Reel screen/play reel.dart'; // Import your ReelScreen here
import '../followers screen/FollowersScreen.dart';
import '../followers screen/FollowingScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  String _profileImageUrl = '';
  String _name = 'No Name';
  int _followers = 0;
  int _following = 0;
  int _posts = 0;
  String _email = '';
  String _phone = '';
  String? _latestVideoUrl;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          _name = userDoc.get('name') ?? 'No Name';
          _profileImageUrl = userDoc.get('profileImageUrl') ?? '';
          _email = userDoc.get('email') ?? '';
          _phone = userDoc.get('phone') ?? '';
        });
      }

      QuerySnapshot followersSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('followers').get();
      QuerySnapshot followingSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('following').get();
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance.collection('reels').where('userId', isEqualTo: uid).get();

      setState(() {
        _followers = followersSnapshot.docs.length;
        _following = followingSnapshot.docs.length;
        _posts = postsSnapshot.docs.length; // Update posts count from reels collection
      });

      // Get latest video URL
      QuerySnapshot videoSnapshot = await FirebaseFirestore.instance.collection('reels').where('userId', isEqualTo: uid).orderBy('timestamp', descending: true).limit(1).get();
      if (videoSnapshot.docs.isNotEmpty) {
        final videoUrl = videoSnapshot.docs.first.get('videoUrl') as String;
        setState(() {
          _latestVideoUrl = videoUrl;
          _videoPlayerController = VideoPlayerController.network(videoUrl)
            ..initialize().then((_) {
              setState(() {});
              _videoPlayerController?.play();
            });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    }
  }

  Future<void> _uploadProfileImage(BuildContext context) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      try {
        final String uid = FirebaseAuth.instance.currentUser!.uid;
        final Reference storageReference = FirebaseStorage.instance.ref().child('profile_images').child('$uid.jpg');

        await storageReference.putFile(file);
        final String downloadUrl = await storageReference.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profileImageUrl': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image updated successfully!')),
        );

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile image: $e')),
        );
      }
    }
  }

  Future<void> _uploadReel(BuildContext context) async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      try {
        final String uid = FirebaseAuth.instance.currentUser!.uid;
        final String reelId = DateTime.now().millisecondsSinceEpoch.toString();
        final Reference storageReference = FirebaseStorage.instance.ref().child('reels').child('$uid/$reelId.mp4');

        await storageReference.putFile(file);
        final String downloadUrl = await storageReference.getDownloadURL();

        await FirebaseFirestore.instance.collection('reels').doc(reelId).set({
          'userId': uid,
          'videoUrl': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reel uploaded successfully!')),
        );

        // Refresh profile to update the post count
        await _refreshProfile();

        // Navigate to ReelsScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReelScreen(), // Navigate to ReelsScreen after uploading a reel
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload reel: $e')),
        );
      }
    }
  }

  void _navigateToFollowers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersScreen(uid: FirebaseAuth.instance.currentUser!.uid),
      ),
    );
  }

  void _navigateToFollowing(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowingScreen(userId: FirebaseAuth.instance.currentUser!.uid),
      ),
    );
  }

  // New method to navigate to ReelScreen
  void _navigateToReelScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReelScreen(), // Navigate to ReelsScreen when clicking on post count
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final bool confirmed = await _showLogoutConfirmationDialog(context);
    if (confirmed) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pop(); // Close the ProfileScreen after logout
    }
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing the dialog by tapping outside of it
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              color: Colors.teal, // Header color
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Confirm Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red, // Cancel button color
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // Logout button color
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0), // Adds space at the bottom
          ],
        ),
      ),
    );
  }

  void _showContactInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone'),
                subtitle: Text(_phone.isNotEmpty ? _phone : 'No phone number available'),
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text('Email'),
                subtitle: Text(_email.isNotEmpty ? _email : 'No email available'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.video_call),
            onPressed: () => _uploadReel(context),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Row(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: () => _uploadProfileImage(context),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _profileImageUrl.isNotEmpty ? NetworkImage(_profileImageUrl) : null,
                    child: _profileImageUrl.isEmpty ? Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                ),
                SizedBox(width: 30),
                // Posts, Followers, Following
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => _navigateToReelScreen(context), // Add navigation on tap
                        child: _buildStatColumn('Posts', _posts),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToFollowers(context),
                        child: _buildStatColumn('Followers', _followers),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToFollowing(context),
                        child: _buildStatColumn('Following', _following),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Username
            Text(
              _name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),

            // Edit Profile, Share Profile, Contact Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.teal, width: 2),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    _showContactInfo(context);
                  },
                  child: Text(
                    'Contact',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.teal, width: 2),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // Add any additional profile information here
          ],
        ),
      ),
    );
  }

  Column _buildStatColumn(String label, int count) {
    return Column(
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
