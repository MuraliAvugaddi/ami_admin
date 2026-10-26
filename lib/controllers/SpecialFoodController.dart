import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AdminSpecialController extends GetxController {
  final box = GetStorage();
  var specialItems = <dynamic>[].obs;
  var isLoading = false.obs;
  
  // To store the picked image
  File? pickedImage;
  String base64Image = "";

  static const String _baseUrl = "http://10.13.76.23:5000/api/special-food";

  @override
  void onInit() {
    super.onInit();
    fetchAdminMenu();
  }

  Future<void> fetchAdminMenu() async {
    try {
      isLoading(true);
      final token = box.read('token');
      final response = await http.get(Uri.parse('$_baseUrl/menu'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        specialItems.assignAll(json.decode(response.body)['menu'] ?? []);
      }
    } finally {
      isLoading(false);
    }
  }

  // ✅ PICK IMAGE FROM GALLERY
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image != null) {
      pickedImage = File(image.path);
      // Convert to Base64 to send to Node.js
      List<int> imageBytes = await pickedImage!.readAsBytes();
      base64Image = base64Encode(imageBytes);
      update(); // Refresh UI
    }
  }

  // ✅ SEND TO USER APP BUTTON LOGIC
  Future<void> addNewItem(String name, double price) async {
    if (base64Image.isEmpty) {
      Get.snackbar("Error", "Please select an image first", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isLoading(true);
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/add-item'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'name': name,
          'price': price,
          'image': 'data:image/png;base64,$base64Image', // Proper format for backend
          'description': "Special Menu Item",
        }),
      );

      if (response.statusCode == 201) {
        Get.back(); // Close dialog
        base64Image = ""; pickedImage = null; // Reset
        fetchAdminMenu(); // Refresh list
        Get.snackbar("Success", "Sent to User App!", backgroundColor: Colors.green, colorText: Colors.white);
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteItem(String id) async {
    final token = box.read('token');
    await http.delete(Uri.parse('$_baseUrl/admin/delete-item/$id'), headers: {'Authorization': 'Bearer $token'});
    fetchAdminMenu();
  }
}