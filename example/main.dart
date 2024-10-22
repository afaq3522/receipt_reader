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
      title: 'Receipt Reader Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ReceiptReaderHomePage(),
    );
  }
}

class ReceiptReaderHomePage extends StatefulWidget {
  const ReceiptReaderHomePage({super.key});

  @override
  State<ReceiptReaderHomePage> createState() => _ReceiptReaderHomePageState();
}

class _ReceiptReaderHomePageState extends State<ReceiptReaderHomePage> {
  List<Order> orders = [];

  // Callback to handle adding the extracted order
  void _addOrder(Order order) {
    setState(() {
      orders.add(order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order added!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Reader Home'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ReceiptUploader widget
          ReceiptUploader(onAdd: _addOrder),
          const Divider(),

          // Display the list of added orders
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                        'Order ${index + 1} - Total: \$${order.total.toStringAsFixed(2)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: order.items.map((item) {
                        return Text(
                            '${item.name} (x${item.quantity}) - \$${item.price.toStringAsFixed(2)}');
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
