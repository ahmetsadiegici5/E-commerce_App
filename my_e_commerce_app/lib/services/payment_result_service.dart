import '../utils/logger.dart';

class PaymentResultService {
	static Map<String, dynamic> normalizeRetrieveResponse(Map<String, dynamic> raw) {
		Logger.debug('Retrieve normalize ediliyor: $raw');
		// İyzico checkoutForm.retrieve tipik alanlar: status, paymentStatus, price, paidPrice, basketId, paymentId
		return {
			'status': raw['status'],
			'paymentStatus': raw['paymentStatus'],
			'price': raw['price'] ?? raw['paidPrice'],
			'paymentId': raw['paymentId'],
			'basketId': raw['basketId'],
			'errorMessage': raw['errorMessage'],
			'raw': raw,
		};
	}
}
