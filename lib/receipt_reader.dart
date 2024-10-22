import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'models/order.dart';
import 'utils/chat_extractions.dart';

class ReceiptUploader extends StatefulWidget {
  final void Function(Order) onAdd;
  final String geminiApi;

  const ReceiptUploader({
    Key? key,
    required this.onAdd,
    required this.geminiApi,
  }) : super(key: key);

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
      setState(() => _receiptImage = pickedImage);
      await _processReceiptImage();
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _receiptImage = pickedImage);
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

    try {
      final inputImage = InputImage.fromFilePath(_receiptImage!.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final order = await processReceipt(recognizedText.text, widget.geminiApi);

      setState(() {
        _extractedText = recognizedText.text;
        _extractedOrder = order;
      });
    } catch (e) {
      setState(() => _extractedText = 'Error: Could not process receipt');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImagePreview(),
          const SizedBox(height: 16),
          _buildProcessingSection(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return _receiptImage != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_receiptImage!.path),
              height: 200,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No image selected'),
            ),
          );
  }

  Widget _buildProcessingSection() {
    if (_isProcessing) {
      return const Column(
        children: [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Text('Processing receipt...'),
        ],
      );
    }

    if (_extractedText != null && _extractedOrder != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Extracted Receipt Data:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildOrderItemsList(),
          const SizedBox(height: 16),
          _buildOrderSummary(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.onAdd(_extractedOrder!),
            child: const Text('Add Order'),
          ),
        ],
      );
    }

    return const Text('Please upload a receipt to extract data');
  }

  Widget _buildOrderItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _extractedOrder?.items.length ?? 0,
      itemBuilder: (context, index) {
        final item = _extractedOrder!.items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.name),
          subtitle: Text('Quantity: ${item.quantity}'),
          trailing: Text('\$${item.price.toStringAsFixed(2)}'),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subtotal: \$${_extractedOrder!.subtotal.toStringAsFixed(2)}'),
        Text('Tax: \$${_extractedOrder!.tax.toStringAsFixed(2)}'),
        Text(
          'Total: \$${_extractedOrder!.total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
    );
  }
}
