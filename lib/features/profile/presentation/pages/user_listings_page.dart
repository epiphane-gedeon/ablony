import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../product/domain/entities/entities.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../product/presentation/widgets/boost_bottom_sheet.dart';
import '../../../sell/presentation/widgets/sell_bottom_sheet.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

import '../../../../l10n/app_localizations.dart';

class UserListingsPage extends ConsumerWidget {
  const UserListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Center(child: Text(AppLocalizations.of(context)!.userNotConnected)),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(user.username),
              centerTitle: true,
              bottom: TabBar(
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.listings),
                  Tab(text: AppLocalizations.of(context)!.reviews),
                  Tab(text: AppLocalizations.of(context)!.aboutTab),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildAnnoncesTab(context, ref, user.uid),
                _buildEvaluationsTab(context),
                _buildAProposTab(context, user),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.errorGenericMsg(error.toString()))),
      ),
    );
  }

  Widget _buildAnnoncesTab(BuildContext context, WidgetRef ref, String userId) {
    final productsAsync = ref.watch(sellerProductsProvider(userId));
    final theme = Theme.of(context);

    return productsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ajoute des articles pour commencer à vendre',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fais du tri ! Vends ce que tu n\'utilises plus.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: AppLocalizations.of(context)!.addItems,
                  isFullWidth: false,
                  onPressed: () {
                     SellBottomSheet.show(context);
                  },
                ),
              ],
            ),
          );
        }

        return ResponsiveProductGrid<Product>(
          itemsBuilder: (_) => products,
          itemBuilder: (context, product) {
            return Stack(
              children: [
                ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                ),
                if (!product.isSold)
                  Positioned(
                    bottom: 40,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => BoostBottomSheet.show(context, product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(AppLocalizations.of(context)!.errorGenericMsg(error.toString()))),
    );
  }

  Widget _buildEvaluationsTab(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.noReviewsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              AppLocalizations.of(context)!.noReviewsSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAProposTab(BuildContext context, dynamic user) {
    final theme = Theme.of(context);
    
    return ListView(
      children: [
        // Mock Cover Photo / Avatar
        Container(
          height: 200,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          child: Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.headlineMedium,
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.verifiedInfo,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.check_circle_outline, 'Google', user.authProvider.toString().contains('google')),
              _buildInfoRow(context, Icons.check_circle_outline, 'E-mail', true),
              const SizedBox(height: 24),
              _buildInfoRow(context, Icons.location_on_outlined, user.country.name, true, color: theme.colorScheme.onSurface),
              _buildInfoRow(context, Icons.access_time, 'Dernière connexion il y a une minute', true, color: theme.colorScheme.onSurface),
              _buildInfoRow(context, Icons.rss_feed, '0 Abonné, 0 Abonnement', true, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, bool isVerified, {Color? color}) {
    if (!isVerified) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final rowColor = color ?? theme.colorScheme.onSurface.withOpacity(0.7);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: rowColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: rowColor,
            ),
          ),
        ],
      ),
    );
  }
}
