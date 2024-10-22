import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'models/order.dart';
import 'utils/chat_extractions.dart';

class ReceiptUploader extends StatefulWidget {
  final void Function(Order) onAdd;

  const ReceiptUploader({super.key, required this.onAdd});

  @override
  State<ReceiptUploader> createState() => _ReceiptUploaderState();
}

class _ReceiptUploaderState extends State<ReceiptUploader> {
  final ImagePicker _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  XFile? _receiptImage;
  String? _extractedText;
  Order? _extractedOrder;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _getImageFromCamera() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _receiptImage = pickedImage;
      });
      await _processReceiptImage();
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _receiptImage = pickedImage;
      });
      await _processReceiptImage();
    }
  }

  Future<void> _processReceiptImage() async {
    if (_receiptImage == null) return;

    setState(() {
      _isProcessing = true;
      _extractedText = null;
      _extractedOrder = null;
    });

    // Convert the picked image into InputImage for text recognition
    final inputImage = InputImage.fromFilePath(_receiptImage!.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    try {
      // Process recognized text to extract the order
      Order order = await processReceipt(recognizedText.text);

      setState(() {
        _extractedText = recognizedText.text;
        _extractedOrder = order;
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Error: Could not process receipt';
      });
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_receiptImage != null)
              Image.file(
                File(_receiptImage!.path),
                height: 200,
                fit: BoxFit.cover,
              )
            else
              const Placeholder(
                fallbackHeight: 200,
                child: Center(child: Text('No image selected')),
              ),
            const SizedBox(height: 16),
            if (_isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Processing receipt...')
            ] else if (_extractedText != null && _extractedOrder != null) ...[
              const Text('Extracted Receipt Data:'),
              Expanded(
                child: ListView.builder(
                  itemCount: _extractedOrder?.items.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = _extractedOrder!.items[index];
                    return ListTile(
                      title: Text('${item.name} (x${item.quantity})'),
                      trailing: Text(item.price.toStringAsFixed(2)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Subtotal: ${_extractedOrder!.subtotal.toStringAsFixed(2)}'),
              Text('Tax: ${_extractedOrder!.tax.toStringAsFixed(2)}'),
              Text('Total: ${_extractedOrder!.total.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Invoke the onAdd callback when the user confirms
                  widget.onAdd(_extractedOrder!);
                },
                child: const Text('Add'),
              )
            ] else ...[
              const Text('Please upload a receipt to extract data'),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _getImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Picture'),
                ),
                ElevatedButton.icon(
                  onPressed: _getImageFromGallery,
                  icon: const Icon(Icons.photo),
                  label: const Text('Upload Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
