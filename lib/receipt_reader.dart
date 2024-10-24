import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'models/order.dart';
import 'utils/chat_extractions.dart';

class ReceiptUploader extends StatefulWidget {
  final void Function(Order) onAdd;
  final String geminiApi;
  final List<String>? listOfCategories;

  // Customization parameters
  final ButtonStyle? actionButtonStyle;
  final TextStyle? extractedDataTextStyle;
  final TextStyle? orderSummaryTextStyle;
  final double? imagePreviewHeight;
  final double? imagePreviewBorderRadius;
  final String? processingMessage;
  final Widget? customProcessingIndicator;
  final EdgeInsetsGeometry? padding;

  const ReceiptUploader({
    super.key,
    required this.onAdd,
    required this.geminiApi,
    this.listOfCategories,
    this.actionButtonStyle,
    this.extractedDataTextStyle,
    this.orderSummaryTextStyle,
    this.imagePreviewHeight,
    this.imagePreviewBorderRadius,
    this.processingMessage,
    this.customProcessingIndicator,
    this.padding,
  });

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
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = widget.listOfCategories ?? [];
  }

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
      final order = await processReceipt(
        recognizedText.text,
        widget.geminiApi,
        _categories,
      );

      setState(() {
        _extractedText = recognizedText.text;
        _extractedOrder = order;
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Error: Could not process receipt';
        _extractedOrder = null;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
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
            borderRadius:
                BorderRadius.circular(widget.imagePreviewBorderRadius ?? 8),
            child: Image.file(
              File(_receiptImage!.path),
              height: widget.imagePreviewHeight ?? 200,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            height: widget.imagePreviewHeight ?? 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius:
                  BorderRadius.circular(widget.imagePreviewBorderRadius ?? 8),
            ),
            child: const Center(
              child: Text('No image selected'),
            ),
          );
  }

  Widget _buildProcessingSection() {
    if (_isProcessing) {
      return Column(
        children: [
          widget.customProcessingIndicator ?? const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(widget.processingMessage ?? 'Processing receipt...'),
        ],
      );
    }

    if (_extractedText != null && _extractedOrder != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Extracted Receipt Data:',
            style: widget.extractedDataTextStyle ??
                const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildOrderItemsList(),
          const SizedBox(height: 16),
          _buildOrderSummary(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.onAdd(_extractedOrder!),
            style: widget.actionButtonStyle,
            child: const Text('Add Order'),
          ),
        ],
      );
    } else if (_extractedText != null && _extractedOrder == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16.0), // Add some padding
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
            color: Colors.deepOrangeAccent
                .withOpacity(0.8), // Reddish-orange color
            borderRadius: BorderRadius.circular(12), // Rounded edges
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Make the column only as tall as its content
            children: [
              Text(
                'Couldn\'t read receipt: $_extractedText',
                style: widget.extractedDataTextStyle ??
                    const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .white, // White text to contrast with the background
                    ),
                textAlign: TextAlign.center, // Center-align the text
              ),
              const SizedBox(
                  height: 12), // Add some space between the text and the button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _extractedText = null;
                    _extractedOrder = null;
                  });
                }, // Your try again logic here
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.deepOrangeAccent,
                  backgroundColor: Colors.white, // Button text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        8), // Slightly rounded edges for the button
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
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
        Text(
          'Subtotal: \$${_extractedOrder!.subtotal.toStringAsFixed(2)}',
          style: widget.orderSummaryTextStyle,
        ),
        Text(
          'Tax: \$${_extractedOrder!.tax.toStringAsFixed(2)}',
          style: widget.orderSummaryTextStyle,
        ),
        Text(
          'Total: \$${_extractedOrder!.total.toStringAsFixed(2)}',
          style: widget.orderSummaryTextStyle
                  ?.copyWith(fontWeight: FontWeight.bold) ??
              const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10.0, // Spacing between the buttons
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _getImageFromCamera,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera'),
          style: widget.actionButtonStyle,
        ),
        ElevatedButton.icon(
          onPressed: _getImageFromGallery,
          icon: const Icon(Icons.photo),
          label: const Text('Upload'),
          style: widget.actionButtonStyle,
        ),
      ],
    );
  }
}
