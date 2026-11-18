import 'package:shared_preferences/shared_preferences.dart';

/// Display-only cache of last successful StoreKit prices for paywall cards.
/// Does not affect purchase / restore / product IDs.
class PaywallPriceCache {
  PaywallPriceCache._();

  static String _key(String productId) =>
      'paywall_display_price_${productId.trim()}';

  static Future<void> save(String productId, String price) async {
    final id = productId.trim();
    final p = price.trim();
    if (id.isEmpty || p.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(id), p);
  }

  static Future<String?> read(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key(id));
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  static Future<void> saveProduct(ProductPriceSnapshot? snap) async {
    if (snap == null) return;
    await save(snap.productId, snap.price);
  }
}

class ProductPriceSnapshot {
  const ProductPriceSnapshot({
    required this.productId,
    required this.price,
  });

  final String productId;
  final String price;
}
