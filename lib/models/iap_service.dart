import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ─── Product IDs ─────────────────────────────────────────────────────────────
// These must match EXACTLY what you create in App Store Connect & Google Play.
const kProductPdfExport = 'split_fair_pdf_export';     // $1.99 — skip video ad for PDF
const kProductRemoveAds = 'split_fair_remove_ads';     // $2.99 — remove ALL ads
const kProductSavedConfigs = kProductPdfExport;         // saved configs bundled with Tier 1

/// Manages all in-app purchase logic for Split Fair.
///
/// Tier 1: PDF Export ($1.99) — removes rewarded video gate, banners stay
/// Tier 2: Remove All Ads ($2.99) — no banners, no video gate, includes PDF
class IapService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _storeAvailable = false;
  bool _pdfUnlocked = false;
  bool _removeAdsUnlocked = false;
  bool _configsUnlocked = false;
  bool _loading = false;
  String? _errorMessage;

  ProductDetails? _pdfProduct;
  ProductDetails? _removeAdsProduct;
  ProductDetails? _configsProduct;

  bool get storeAvailable => _storeAvailable;
  bool get pdfUnlocked => _pdfUnlocked || _removeAdsUnlocked;
  bool get removeAdsUnlocked => _removeAdsUnlocked;
  bool get configsUnlocked => _configsUnlocked;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  /// Call once from AppState or main(). Connects to the store and loads products.
  Future<void> init({
    required bool pdfAlreadyUnlocked,
    required bool removeAdsAlreadyUnlocked,
    required bool configsAlreadyUnlocked,
    required Future<void> Function() onPdfPurchased,
    required Future<void> Function() onRemoveAdsPurchased,
    required Future<void> Function() onConfigsPurchased,
  }) async {
    _pdfUnlocked = pdfAlreadyUnlocked;
    _removeAdsUnlocked = removeAdsAlreadyUnlocked;
    _configsUnlocked = configsAlreadyUnlocked;

    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) return;

    // Listen for purchase updates
    _sub = _iap.purchaseStream.listen(
      (purchases) => _handlePurchases(purchases, onPdfPurchased, onRemoveAdsPurchased, onConfigsPurchased),
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );

    // Load product details
    final response = await _iap.queryProductDetails({kProductPdfExport, kProductRemoveAds, kProductSavedConfigs});
    if (response.error != null) {
      _errorMessage = response.error!.message;
      notifyListeners();
      return;
    }
    for (final p in response.productDetails) {
      if (p.id == kProductPdfExport) _pdfProduct = p;
      if (p.id == kProductRemoveAds) _removeAdsProduct = p;
      if (p.id == kProductSavedConfigs) _configsProduct = p;
    }
    notifyListeners();
  }

  /// Trigger a purchase for the PDF export feature (Tier 1).
  void purchasePdfExport() => _buy(_pdfProduct);

  /// Trigger a purchase for removing all ads (Tier 2).
  void purchaseRemoveAds() => _buy(_removeAdsProduct);

  /// Trigger a purchase for the Saved Configs feature.
  void purchaseSavedConfigs() => _buy(_configsProduct);

  /// Restore previous purchases (required by App Store guidelines).
  Future<void> restorePurchases() async {
    _loading = true;
    notifyListeners();
    await _iap.restorePurchases();
    _loading = false;
    notifyListeners();
  }

  void _buy(ProductDetails? product) {
    if (product == null) {
      _errorMessage = 'Product not available. Check your connection.';
      notifyListeners();
      return;
    }
    final param = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _handlePurchases(
    List<PurchaseDetails> purchases,
    Future<void> Function() onPdfPurchased,
    Future<void> Function() onRemoveAdsPurchased,
    Future<void> Function() onConfigsPurchased,
  ) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.pending) {
        _loading = true;
        notifyListeners();
      } else {
        _loading = false;

        if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
          if (p.productID == kProductPdfExport && !_pdfUnlocked) {
            _pdfUnlocked = true;
            await onPdfPurchased();
          }
          if (p.productID == kProductRemoveAds && !_removeAdsUnlocked) {
            _removeAdsUnlocked = true;
            _pdfUnlocked = true; // Tier 2 includes Tier 1
            await onRemoveAdsPurchased();
          }
          if (p.productID == kProductSavedConfigs && !_configsUnlocked) {
            _configsUnlocked = true;
            await onConfigsPurchased();
          }
        }

        if (p.status == PurchaseStatus.error) {
          _errorMessage = p.error?.message ?? 'Purchase failed.';
        }

        // Always complete the purchase to close the transaction.
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }

        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
