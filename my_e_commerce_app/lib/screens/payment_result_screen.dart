import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const PaymentResultScreen({super.key, required this.result});

  bool get success => (result['status'] == 'success') && (result['paymentStatus'] == null || result['paymentStatus'] == 'SUCCESS');

  @override
  Widget build(BuildContext context) {
    final paymentId = result['paymentId'] ?? result['basketId'] ?? '-';
    final status = result['paymentStatus'] ?? result['status'];
    final price = result['price'] ?? result['paidPrice'];
    final errorMessage = result['errorMessage'] ?? result['error'] ?? result['errorGroup'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Sonucu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.green : Colors.red, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success ? 'Ödeme Başarılı' : 'Ödeme Başarısız',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            _infoRow('Durum', status?.toString() ?? '-'),
            _infoRow('Payment ID', paymentId.toString()),
            _infoRow('Tutar', price?.toString() ?? '-'),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              const Text('Hata Mesajı', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(errorMessage.toString(), style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Ana Sayfaya Dön'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
