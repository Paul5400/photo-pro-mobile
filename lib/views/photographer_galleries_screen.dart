import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import 'gallery_detail_screen.dart';

class PhotographerGalleriesScreen extends StatefulWidget {
  const PhotographerGalleriesScreen({super.key});

  @override
  State<PhotographerGalleriesScreen> createState() =>
      _PhotographerGalleriesScreenState();
}

class _PhotographerGalleriesScreenState
    extends State<PhotographerGalleriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadPhotographerGalleries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Galeries Privées'),
        centerTitle: true,
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allPhotographerGalleries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null &&
              provider.allPhotographerGalleries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadPhotographerGalleries(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.allPhotographerGalleries.isEmpty) {
            return const Center(
              child: Text('Vous n\'avez aucune galerie pour le moment.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadPhotographerGalleries(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.allPhotographerGalleries.length,
              itemBuilder: (context, index) {
                final gallery = provider.allPhotographerGalleries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Hero(
                      tag: 'gallery-icon-${gallery.id}',
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              !gallery.isPrivate
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          !gallery.isPrivate
                              ? Icons.public_rounded
                              : Icons.lock_rounded,
                          color:
                              !gallery.isPrivate ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    title: Text(
                      gallery.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${gallery.photosCount ?? 0} photos • ${gallery.publicationDate?.toLocal().toString().split(' ')[0] ?? 'Date inconnue'}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  GalleryDetailScreen(gallery: gallery),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité de création de galerie à venir.'),
            ),
          );
        },
        label: const Text('Nouvelle Galerie'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}
