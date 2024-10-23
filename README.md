# Receipt Reader

`Receipt Reader` is a Flutter package designed to help developers read and process receipt images using Google ML Kit's text recognition. The package extracts relevant data such as items, quantities, prices, and totals from receipts and returns a structured `Order` object for easy integration into your apps.

## Features

- Capture receipt images using the camera or select from the gallery.
- Recognize text from receipts using Google ML Kit's text recognition.
- Extract structured order information such as items, quantities, prices, and totals.
- Easily integrate extracted order data into your application.

## Installation

Add `receipt_reader` to your `pubspec.yaml` file:

```yaml
dependencies:
  receipt_reader: latest_version
```

Then run:

```bash
flutter pub get
```

## Usage

To use the `ReceiptUploader` widget, import it and handle the receipt upload and order extraction:

```dart
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
        onAdd: (Order order) {
          // Handle the added order
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order added: ${order.items.length} items'),
            ),
          );
        },
        geminiApi:
            '************************************************', // Replace with your API URL
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

```

### `ReceiptUploader` Widget Options

- **`onAdd`**: Callback that passes the extracted `Order` object when a receipt is processed.
- **`geminiApi`**: API key or URL for the backend to process the extracted text and return structured data.
- **`actionButtonStyle`** (optional): Customize the style of action buttons (e.g., upload or capture receipt buttons).
- **`orderSummaryTextStyle`** (optional): Style for the section headers like "Extracted Receipt Data."
- **`extractedDataTextStyle`** (optional): Style for the item name and details (e.g., price and quantity).
- **`imagePreviewHeight`** (optional): Height of the receipt image preview.
- **`imageBorderRadius`** (optional): BorderRadius of the receipt image preview.
- **`padding`** (optional): Padding around the entire widget.
- **`customProcessingIndicator`** (optional): Widget displayed when the image is being processed

## Order Object Structure

Once a receipt is processed, the extracted data is returned as an `Order` object, which has the following structure:

- `items`: A list of `OrderItem` objects, each containing:
  - `name`: The name of the item.
  - `quantity`: The quantity of the item.
  - `price`: The price of the item.
- `subtotal`: The subtotal of all items.
- `tax`: The calculated tax.
- `total`: The total cost including tax.

## Example Order Object

```dart
Order(
  items: [
    OrderItem(name: 'Item 1', quantity: 2, price: 10.00),
    OrderItem(name: 'Item 2', quantity: 1, price: 5.50),
  ],
  subtotal: 25.50,
  tax: 2.55,
  total: 28.05,
)
```
