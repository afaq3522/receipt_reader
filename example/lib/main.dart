import 'package:flutter/material.dart';
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
      home: const ReceiptUploaderScreen(),
    );
  }
}

class ReceiptUploaderScreen extends StatelessWidget {
  const ReceiptUploaderScreen({super.key});

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
        padding: const EdgeInsets.all(20.0),
      ),
    );
  }
}
