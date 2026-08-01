import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/receipt_repository.dart';
import '../../domain/models/receipt.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository();
});

final receiptByIdProvider = FutureProvider.family<Receipt, String>((
  ref,
  receiptId,
) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getReceiptById(receiptId);
});

/// Reçu d'un produit vendu, vu par son vendeur — utilisé pour la remise en
/// main propre par QR code. [StreamProvider] pour rester à jour dès que
/// l'achat est finalisé, même si la fiche produit était déjà ouverte avant.
final receiptForSellerProvider = StreamProvider.family<Receipt?, (String productId, String sellerId)>((
  ref,
  params,
) {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.watchReceiptAsSeller(params.$1, params.$2);
});

/// Reçu d'un produit vendu, vu par son acheteur — émet `null` si
/// l'utilisateur courant n'est pas l'acheteur de ce produit.
final receiptForBuyerProvider = StreamProvider.family<Receipt?, (String productId, String buyerId)>((
  ref,
  params,
) {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.watchReceiptAsBuyer(params.$1, params.$2);
});
