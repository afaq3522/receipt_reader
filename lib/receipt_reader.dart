import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'models/order.dart';
import 'utils/chat_extractions.dart';

/// A widget that handles the uploading of receipt images and processing the
/// extracted data to generate an `Order` object.
///
/// This widget allows customization of the user interface elements, including
/// styles for buttons, text, and error handling. It also integrates with
/// Gemini API to process the receipt data.
class ReceiptUploader extends StatefulWidget {
  /// Callback function to handle the `Order` object once the receipt data is processed.
  final void Function(Order) onAdd;

  /// API key for Gemini AI used to extract data from the receipt.
  final String geminiApi;

  /// Optional list of categories that can be used to categorize receipt items.
  final List<String>? listOfCategories;

  /// Custom style for the action button that triggers receipt processing.
  final ButtonStyle? actionButtonStyle;

  /// Custom text style for displaying extracted data from the receipt.
  final TextStyle? extractedDataTextStyle;

  /// Custom text style for displaying the summary of the processed order.
  final TextStyle? orderSummaryTextStyle;

  /// Optional height for the receipt image preview widget.
  final double? imagePreviewHeight;

  /// Optional border radius for the receipt image preview.
  final double? imagePreviewBorderRadius;

  /// Custom message to be displayed while processing the receipt.
  final String? processingMessage;

  /// Custom widget to be shown as an indicator while the receipt is being processed.
  final Widget? customProcessingIndicator;

  /// Custom padding for the entire widget.
  final EdgeInsetsGeometry? padding;

  /// Custom box decoration for the error message container.
  final BoxDecoration? errorBoxStyle;

  /// Custom text style for the error message text.
  final TextStyle? errorTextStyle;

  /// Custom button style for the "Try Again" button shown when an error occurs.
  final ButtonStyle? errorButtonStyle;

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
    this.errorBoxStyle,
    this.errorTextStyle,
    this.errorButtonStyle,
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
        _extractedText = e.toString();
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
            _buildProcessingSection(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
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
          _buildVendor(),
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
          decoration: widget.errorBoxStyle ??
              BoxDecoration(
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
                style: widget.errorTextStyle ??
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
                    _receiptImage = null;
                  });
                }, // Your try again logic here
                style: widget.errorButtonStyle ??
                    ElevatedButton.styleFrom(
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

  Widget _buildVendor(){
    return Text("Vendor: ${_extractedOrder?.vendorName??"N/A"}");
  }

  Widget _buildOrderItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _extractedOrder?.items?.length ?? 0,
      itemBuilder: (context, index) {
        final item = _extractedOrder?.items?[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item?.name??""),
          subtitle: Text('Quantity: ${item?.quantity??0}'),
          trailing: Text('\$${item?.price.toStringAsFixed(2)??0}'),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtotal: \$${_extractedOrder?.subtotal?.toStringAsFixed(2)}',
          style: widget.orderSummaryTextStyle,
        ),
        Text(
          'Tax: \$${_extractedOrder?.tax?.toStringAsFixed(2)}',
          style: widget.orderSummaryTextStyle,
        ),
        Text(
          'Total: \$${_extractedOrder?.total?.toStringAsFixed(2)}',
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
