import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_reader/models/order.dart';
import 'package:receipt_reader/receipt_reader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Uploader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return  _buildActionButtons();
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _getImageFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
        ),
        SizedBox(width: 10,),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _getImageFromGallery,
            icon: const Icon(Icons.photo),
            label: const Text('Upload'),
          ),
        ),
      ],
    );
  }

  Future<void> _getImageFromCamera() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      navigate(pickedImage);
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      navigate(pickedImage);
    }
  }

  void navigate(XFile file){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  ReceiptUploaderScreen(file: file,)),
    );
  }
}

class ReceiptUploaderScreen extends StatelessWidget {
  final XFile file;
  const ReceiptUploaderScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Receipt'),
      ),
      body: ReceiptUploader(
        onAdd: (Order? order,_) {
          // Handle the added order
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order added: ${order?.items?.length} items'),
            ),
          );
        },
        geminiApi:
        '****************************', // Replace with your API URL
        listOfCategories: <String>["food", "clothes"],
        actionButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Button color
          textStyle: const TextStyle(fontSize: 16),
        ),
        orderSummaryTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        extractedDataTextStyle:
        const TextStyle(fontSize: 14, color: Colors.grey),
        imagePreviewHeight: 250.0,
        padding: const EdgeInsets.all(20.0), receipt: File(file.path),
      ),
    );
  }
}
