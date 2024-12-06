import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:receipt_reader/models/order.dart';

/// Processes a receipt text using the Google Generative AI API and returns
/// the structured [Order] object.
///
/// This function sends the receipt text to the AI model, which extracts items,
/// their quantity, price, subtotal, tax, and total. It also assigns categories
/// to each item based on the provided list.
///
/// The AI expects the data in the following JSON format:
/// ```json
/// {
///   "invoice_number": "Invoice Number",
///   "date": "Date",
///   "payment_method":"Payment Method",
///   "items": [
///     {
///       "name": "Item Name",
///       "quantity": Quantity,
///       "price": Price,
///       "category": "category"
///     },
///     ...
///   ],
///   "subtotal": Subtotal,
///   "tax": Tax,
///   "total": Total
/// }
/// ```
///
/// If the response does not contain valid JSON or an error occurs during the
/// request, an exception is thrown.
///
/// Parameters:
/// - [receiptText]: The raw text from the receipt to be processed.
/// - [api]: The API key for accessing the Google Generative AI model.
/// - [categories]: A list of categories to classify the items.
///
/// Returns:
/// A future that resolves to an [Order] object containing the extracted information.
///
/// Throws:
/// - [Exception] if there is an error processing the receipt or the API response is invalid.
Future<Order> processReceipt(
  String receiptText,
  String api,
  List<String> categories,
) async {
  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: api,
    );

    final List<String> formattedList = ['unkown'];

    for (String category in categories) {
      formattedList.add(category.toLowerCase());
    }

    String prompt = """
      Extract the invoice number, date, payment method, items, their quantity, price, subtotal, total, and tax from the following receipt:
      $receiptText And give each item a category strictly from this list of categories $categories. If the invoice number, payment method, date, can't be extracted please put the string "UNKNOWN"

      Please return the response in the following JSON format:
      ```json
      {
        "invoice_number": "Invoice Number",
        "date": "Date",
        "payment_method":"Payment Method",
        "items": [
          {
            "name": "Item Name",
            "quantity": Quantity,
            "price": Price,
            "category": "category"
          },
          ...
        ],
        "subtotal": Subtotal,
        "tax": Tax,
        "total": Total
      }
      ```""";

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    // Extract the generated text which contains the JSON wrapped in ```json ```
    String generatedText = response.text ?? '';

    // Extract the JSON part from the wrapped ```json ``` text
    String jsonString = extractJsonFromText(generatedText);

    // Convert the response into a JSON structure
    Map<String, dynamic> extractedData = jsonDecode(jsonString);

    Order order = Order.fromJson(extractedData);

    // Return the extracted JSON data
    return order;
  } catch (error) {
    // Handle any errors that may occur during the request
    throw Exception("Error processing receipt: $error");
  }
}

/// Extracts a valid JSON string from a block of text.
///
/// This function looks for a JSON block between ` ```json ` and ` ``` ` markers
/// and attempts to extract and clean the JSON content.
///
/// Parameters:
/// - [text]: The raw text containing the JSON.
///
/// Returns:
/// A valid JSON string extracted from the input text.
///
/// Throws:
/// - [FormatException] if valid JSON is not found within the text.
String extractJsonFromText(String text) {
  // Find the position of the first ```json``` block
  final jsonStart = text.indexOf('```json');
  // Find the position of the closing ```
  final jsonEnd = text.indexOf('```', jsonStart + 6);

  // Check if both the start and end markers were found
  if (jsonStart != -1 && jsonEnd != -1) {
    // Extract the potential JSON text between the markers
    String jsonString = text.substring(jsonStart + 6, jsonEnd).trim();

    // Now clean up the JSON string to remove any unwanted characters
    // Ensure the string starts with '{' and ends with '}' (valid JSON structure)
    final validJsonStart = jsonString.indexOf('{');
    final validJsonEnd = jsonString.lastIndexOf('}');

    if (validJsonStart != -1 && validJsonEnd != -1) {
      jsonString = jsonString.substring(validJsonStart, validJsonEnd + 1);
      return jsonString;
    } else {
      throw const FormatException(
          "Valid JSON not found within the extracted text");
    }
  } else {
    throw const FormatException("JSON format not found in the response");
  }
}
