import 'package:flutter/material.dart';

void main() {
  runApp(const FalpetaApp());
}

class Receipt {
  final String shop;
  final String date;
  final int total;
  final int notebookPage;

  const Receipt({
    required this.shop,
    required this.date,
    required this.total,
    required this.notebookPage,
  });
}

class FalpetaApp extends StatelessWidget {
  const FalpetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'falpeta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ReceiptListPage(),
    );
  }
}

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  final List<Receipt> receipts = [
    const Receipt(
      shop: 'セブンイレブン',
      date: '2026/09/27',
      total: 580,
      notebookPage: 12,
    ),
    const Receipt(
      shop: 'スーパー',
      date: '2026/09/26',
      total: 1280,
      notebookPage: 11,
    ),
    const Receipt(
      shop: 'ドラッグストア',
      date: '2026/09/25',
      total: 980,
      notebookPage: 11,
    ),
  ];

  int get totalAmount {
    return receipts.fold(0, (sum, receipt) => sum + receipt.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('falpeta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {},
            tooltip: '集計',
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今月の合計',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '¥$totalAmount',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt),
                  ),
                  title: Text(receipt.shop),
                  subtitle: Text(
                    '${receipt.date}  /  ノート P.${receipt.notebookPage}',
                  ),
                  trailing: Text(
                    '¥${receipt.total}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ここからレシートを撮影します'),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('レシート'),
      ),
    );
  }
}