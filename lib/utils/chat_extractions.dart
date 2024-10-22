// Function to process the receipt text and return structured JSON
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:receipt_reader/models/order.dart';

Future<Order> processReceipt(
  String receiptText,
  String api,
) async {
  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: api,
    );

    String prompt = """
      Extract the items, their quantity, price, subtotal, total, and tax from the following receipt:
      $receiptText

      Please return the response in the following JSON format:
      ```json
      {
        "items": [
          {
            "name": "Item Name",
            "quantity": Quantity,
            "price": Price
          },
          ...
        ],
        "subtotal": Subtotal,
        "tax": Tax,
        "total": Total
      }
      ```
    """;

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
