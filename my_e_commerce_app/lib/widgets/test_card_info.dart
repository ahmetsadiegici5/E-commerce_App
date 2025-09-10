import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestCardInfo extends StatelessWidget {
  const TestCardInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İyzico Resmi Test Kartları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Başarılı Ödeme Test Kartları:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            _buildSuccessCardSection(),
            const SizedBox(height: 16),
            const Text(
              'Hata Testi Kartları:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            _buildErrorCardSection(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '💡 İpucu:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Kartlara tıklayarak kart numarasını kopyalayabilirsiniz'),
            const Text('• Başarılı kartlar ile ödeme işlemi tamamlanır'),
            const Text('• Hata kartları farklı hata senaryolarını simüle eder'),
            const Text('• Tüm kartlar İyzico sandbox ortamında çalışır'),
            const Text('• Son kullanma tarihi: 12/30, CVC: 123 kullanın'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCardSection() {
    final successCards = [
      {'number': '5528790000000008', 'bank': 'Halkbank', 'type': 'Master Card'},
      {'number': '5400360000000003', 'bank': 'Garanti', 'type': 'Master Card'},
      {'number': '4766620000000001', 'bank': 'Denizbank', 'type': 'Visa'},
      {'number': '4987490000000002', 'bank': 'Finansbank', 'type': 'Visa'},
      {'number': '5890040000000016', 'bank': 'Akbank', 'type': 'Master Card'},
      {'number': '5170410000000004', 'bank': 'Garanti', 'type': 'Master Card'},
    ];

    return Column(
      children: successCards.map((card) => 
        _buildCardTile(
          card['number']!,
          '${card['bank']} - ${card['type']}',
          Colors.green.shade50,
          Colors.green,
        )
      ).toList(),
    );
  }

  Widget _buildErrorCardSection() {
    final errorCards = [
      {'number': '4111111111111129', 'description': 'Yetersiz bakiye'},
      {'number': '4129111111111111', 'description': 'İşlem reddedildi'},
      {'number': '4125111111111115', 'description': 'Kartın süresi dolmuş'},
      {'number': '4124111111111116', 'description': 'Geçersiz CVC'},
      {'number': '4123111111111117', 'description': 'Kart sahibine izin verilmez'},
      {'number': '4127111111111113', 'description': 'Kayıp kart'},
    ];

    return Column(
      children: errorCards.map((card) => 
        _buildCardTile(
          card['number']!,
          card['description']!,
          Colors.orange.shade50,
          Colors.orange,
        )
      ).toList(),
    );
  }

  Widget _buildCardTile(String cardNumber, String description, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withAlpha(77)), // 0.3 * 255 ≈ 77
      ),
      child: ListTile(
        dense: true,
        title: Text(
          cardNumber,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Courier',
            color: textColor,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: textColor.withAlpha(204), // 0.8 * 255 ≈ 204
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.copy, color: textColor, size: 20),
          onPressed: () => _copyToClipboard(cardNumber),
          tooltip: 'Kopyala',
        ),
        onTap: () => _copyToClipboard(cardNumber),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // Snackbar göstermek için context'e ihtiyaç var ama bu widget'ta yok
    // Bu yüzden sadece kopyalama yapıyoruz
  }
}
