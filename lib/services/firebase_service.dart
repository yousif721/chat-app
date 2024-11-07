import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<UserModel?> registerUser(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set(userModel.toMap());
        return userModel;
      }
    } catch (e) {
      print("Error in registration: ${e.toString()}");
    }
    return null;
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("User logged in: ${userCredential.user?.uid}");
      return userCredential.user;
    } catch (e) {
      print("Login failed: $e");
      return null;
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => user.uid != _auth.currentUser!.uid)
          .toList();
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    if (_auth.currentUser == null) {
      print("Error: No user is currently signed in.");
      return;
    }

    final String senderId = _auth.currentUser!.uid;
    final timestamp = DateTime.now();

    MessageModel messageModel = MessageModel(
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    String chatRoomId = getChatRoomId(senderId, receiverId);

    try {
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(messageModel.toMap());
      print("Message sent successfully");
    } catch (e) {
      print("Error in sending message: ${e.toString()}");
    }
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final String currentUserId = _auth.currentUser!.uid;
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  String getChatRoomId(String user1, String user2) {
    if (user1.hashCode <= user2.hashCode) {
      return '$user1-$user2';
    } else {
      return '$user2-$user1';
    }
  }
}

