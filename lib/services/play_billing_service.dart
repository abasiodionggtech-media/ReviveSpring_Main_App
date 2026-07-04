import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

class PlayBillingException implements Exception {
  const PlayBillingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlayBillingResult {
  const PlayBillingResult({required this.product, required this.purchase});

  final ProductDetails product;
  final PurchaseDetails purchase;
}

class PlayBillingService {
  PlayBillingService._();

  static final PlayBillingService instance = PlayBillingService._();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  ProductDetails? _cachedProduct;
  String? _cachedProductId;

  Future<ProductDetails> loadProduct(String productId) async {
    if (_cachedProduct != null && _cachedProductId == productId) {
      return _cachedProduct!;
    }

    if (!Platform.isAndroid) {
      throw const PlayBillingException(
        'Google Play Billing only works on Android devices.',
      );
    }

    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw const PlayBillingException(
        'Google Play Billing is unavailable on this device. Install the app from a Google Play testing track or production, then try again.',
      );
    }

    final response = await _inAppPurchase.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      final notFound = response.notFoundIDs.contains(productId)
          ? ' Product ID not found: $productId.'
          : '';
      throw PlayBillingException(
        response.error?.message ??
            'The Google Play product could not be found. Make sure the product is active in Play Console, the ID matches exactly, and this app was installed from Google Play.$notFound',
      );
    }

    _cachedProductId = productId;
    _cachedProduct = response.productDetails.first;
    return _cachedProduct!;
  }

  Future<void> restorePurchases() => _inAppPurchase.restorePurchases();

  Future<PlayBillingResult> purchaseProduct(String productId) async {
    final product = await loadProduct(productId);
    final completer = Completer<PlayBillingResult>();

    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = _inAppPurchase.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases.where(
          (item) => item.productID == product.id,
        )) {
          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }

          if (purchase.status == PurchaseStatus.error) {
            await subscription.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                PlayBillingException(
                  purchase.error?.message ??
                      'Google Play could not complete the purchase.',
                ),
              );
            }
            return;
          }

          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            await subscription.cancel();
            if (purchase.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchase);
            }
            if (!completer.isCompleted) {
              completer.complete(
                PlayBillingResult(product: product, purchase: purchase),
              );
            }
            return;
          }

          if (purchase.status == PurchaseStatus.canceled) {
            await subscription.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                const PlayBillingException('Purchase cancelled.'),
              );
            }
            return;
          }
        }
      },
      onError: (error) async {
        await subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            PlayBillingException(
              error.toString().replaceFirst('Exception: ', ''),
            ),
          );
        }
      },
    );

    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );

    if (!started) {
      await subscription.cancel();
      throw const PlayBillingException(
        'Google Play Billing could not start the purchase flow. Confirm you are using the Play-installed app with a tester account.',
      );
    }

    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () async {
        await subscription.cancel();
        throw const PlayBillingException(
          'Purchase timed out before Google Play returned a result. Please try again from the Play-installed build.',
        );
      },
    );
  }

  Future<PlayBillingResult> restoreProductPurchase(String productId) async {
    final product = await loadProduct(productId);
    final completer = Completer<PlayBillingResult>();

    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = _inAppPurchase.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases.where(
          (item) => item.productID == product.id,
        )) {
          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }

          if (purchase.status == PurchaseStatus.error) {
            await subscription.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                PlayBillingException(
                  purchase.error?.message ??
                      'Google Play could not restore the purchase.',
                ),
              );
            }
            return;
          }

          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            await subscription.cancel();
            if (purchase.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchase);
            }
            if (!completer.isCompleted) {
              completer.complete(
                PlayBillingResult(product: product, purchase: purchase),
              );
            }
            return;
          }

          if (purchase.status == PurchaseStatus.canceled) {
            await subscription.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                const PlayBillingException('Purchase cancelled.'),
              );
            }
            return;
          }
        }
      },
      onError: (error) async {
        await subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            PlayBillingException(
              error.toString().replaceFirst('Exception: ', ''),
            ),
          );
        }
      },
    );

    await _inAppPurchase.restorePurchases();

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () async {
        await subscription.cancel();
        throw const PlayBillingException(
          'No active Google Play purchase was found. If you already completed payment, make sure you are signed into the same Play account and installed the app from Google Play.',
        );
      },
    );
  }

  Future<void> completeIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  void clearCache() {
    _cachedProduct = null;
    _cachedProductId = null;
  }
}
