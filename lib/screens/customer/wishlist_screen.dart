import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/firebase_storage_image.dart';
import '../../models/service_model.dart';
import '../../services/favorites_service.dart';
import 'service_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  static final FavoritesService _favoritesService = FavoritesService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Favorites'),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting &&
              !authSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = authSnapshot.data;
          if (user == null) {
            return const _MessageState(message: 'Please sign in again.');
          }
          return StreamBuilder<List<String>>(
            stream: _favoritesService.favoriteServiceIds(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _MessageState(
                  message: 'Could not load favorites. Please try again.',
                );
              }
              final ids = snapshot.data ?? const <String>[];
              if (ids.isEmpty) return const _EmptyFavorites();
              return _FavoriteServices(serviceIds: ids);
            },
          );
        },
      ),
    );
  }
}

class _FavoriteServices extends StatefulWidget {
  final List<String> serviceIds;
  const _FavoriteServices({required this.serviceIds});

  @override
  State<_FavoriteServices> createState() => _FavoriteServicesState();
}

class _FavoriteServicesState extends State<_FavoriteServices> {
  late Future<List<ServiceModel>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _loadServices();
  }

  @override
  void didUpdateWidget(covariant _FavoriteServices oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameIds(oldWidget.serviceIds, widget.serviceIds)) {
      _servicesFuture = _loadServices();
    }
  }

  Future<List<ServiceModel>> _loadServices() async {
    final services = await Future.wait(
      widget.serviceIds.map((id) async {
        final document = await FirebaseFirestore.instance
            .collection('services')
            .doc(id)
            .get();
        final data = document.data();
        if (!document.exists || data == null) return null;
        return ServiceModel.fromMap(document.id, data);
      }),
    );
    return services
        .whereType<ServiceModel>()
        .where((service) => service.isActive)
        .toList();
  }

  bool _sameIds(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceModel>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _MessageState(
            message: 'Could not load saved services. Please try again.',
          );
        }
        final services = snapshot.data ?? const <ServiceModel>[];
        if (services.isEmpty) return const _EmptyFavorites();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          itemCount: services.length,
          itemBuilder: (context, index) => _FavoriteCard(
            key: ValueKey(services[index].id),
            service: services[index],
          ),
        );
      },
    );
  }
}

class _FavoriteCard extends StatefulWidget {
  final ServiceModel service;
  const _FavoriteCard({super.key, required this.service});

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isRemoving = false;

  Future<void> _remove() async {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);
    try {
      await _favoritesService.removeFromFavorites(widget.service.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRemoving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove this favorite.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final imageUrl = service.imageUrls.isEmpty ? '' : service.imageUrls.first;
    final price = service.price > 0
        ? 'Starting from Rs. ${service.price.toStringAsFixed(0)}'
        : 'Price not provided';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(serviceId: service.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: imageUrl.isEmpty
                      ? const _ImagePlaceholder()
                      : FirebaseStorageImage(
                          source: imageUrl,
                          fit: BoxFit.cover,
                          enablePreview: true,
                          errorBuilder: (_) => const _ImagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.vendorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from favorites',
                onPressed: _isRemoving ? null : _remove,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.selectedSurface,
      child: const Icon(Icons.image_outlined, color: AppColors.primary),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 54,
              color: AppColors.primary,
            ),
            SizedBox(height: 14),
            Text(
              'No favorites yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 7),
            Text(
              'Services you save will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  const _MessageState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
