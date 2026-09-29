import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';

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
      locale: const Locale('ja', 'JP'),
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
  final ImagePicker _picker = ImagePicker();

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

  // 撮影した写真に何枚のレシートがあるか入力
  Future<int?> askReceiptCount() async {
    final controller = TextEditingController();

    final int? count = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('何枚のレシートがありますか？'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '例：3', suffixText: '枚'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final count = int.tryParse(controller.text);

                if (count != null && count > 0) {
                  Navigator.of(context).pop(count);
                }
              },
              child: const Text('開始'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return count;
  }

  Future<void> scanReceipt() async {
    // --------------------------------------------------
    // 1. カメラ or ファイルを選択
    // --------------------------------------------------
    final String? imagePath = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 100,
                  );

                  if (image != null && context.mounted) {
                    Navigator.of(context).pop(image.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('ファイルから選択'),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );

                  if (result != null &&
                      result.files.single.path != null &&
                      context.mounted) {
                    Navigator.of(context).pop(result.files.single.path!);
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    if (imagePath == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    // --------------------------------------------------
    // 2. この写真に何枚のレシートがあるか入力
    // --------------------------------------------------
    final int? count = await askReceiptCount();

    if (count == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    // --------------------------------------------------
    // 3. 同じ写真を指定回数だけトリミング
    // --------------------------------------------------
    final List<String> croppedPaths = [];

    for (int i = 0; i < count; i++) {
      if (!mounted) {
        return;
      }

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'レシート ${i + 1} / $count をトリミング',
            lockAspectRatio: false,
            initAspectRatio: CropAspectRatioPreset.original,
            hideBottomControls: false,
          ),
        ],
      );

      // トリミングをキャンセルした場合
      if (croppedFile == null) {
        return;
      }

      croppedPaths.add(croppedFile.path);
    }

    if (!mounted) {
      return;
    }

    // --------------------------------------------------
    // 4. 全ての切り出しが終わってからOCR
    // --------------------------------------------------
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.japanese,
    );

    try {
      final List<OcrResult> results = [];

      for (int i = 0; i < croppedPaths.length; i++) {
        if (!mounted) {
          return;
        }

        final inputImage = InputImage.fromFilePath(croppedPaths[i]);

        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );

        results.add(
          OcrResult(imagePath: croppedPaths[i], text: recognizedText.text),
        );
      }

      if (!mounted) {
        return;
      }

      // --------------------------------------------------
      // 5. 全レシートのOCR結果を表示
      // --------------------------------------------------
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OcrResultPage(results: results),
        ),
      );
    } finally {
      await textRecognizer.close();
    }
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
                      const Text('今月の合計', style: TextStyle(fontSize: 14)),
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
                  leading: const CircleAvatar(child: Icon(Icons.receipt)),
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
        onPressed: scanReceipt,
        icon: const Icon(Icons.camera_alt),
        label: const Text('レシート'),
      ),
    );
  }
}

/// OCR結果1枚分
class OcrResult {
  final String imagePath;
  final String text;

  const OcrResult({required this.imagePath, required this.text});
}

/// 複数レシートのOCR結果
class OcrResultPage extends StatelessWidget {
  final List<OcrResult> results;

  const OcrResultPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OCR結果（${results.length}枚）')),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'レシート ${index + 1} / ${results.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(result.imagePath),
                      width: double.infinity,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    '認識結果',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        result.text.isEmpty ? '文字を認識できませんでした。' : result.text,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
