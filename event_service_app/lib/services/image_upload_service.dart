import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Uploads an image to Firebase Storage and returns the download URL
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Create a reference to the file in Firebase Storage
      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');

      // Upload the file
      final uploadTask = ref.putFile(File(imageFile.path));

      // Wait for the upload to complete
      await uploadTask;

      // Get the download URL
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Picks an image from gallery or camera
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
}