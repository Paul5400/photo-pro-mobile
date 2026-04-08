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
    // Nous ne forçons pas le rafraîchissement depuis l'API ici pour ne pas écraser 
    // les galeries débloquées stockées localement.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Galeries'),
        centerTitle: true,
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          final galleries = provider.allPhotographerGalleries;

          if (provider.isLoading && galleries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (galleries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vous n\'avez aucune galerie.\nDébloquez une galerie privée avec un code pour l\'ajouter ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Accéder à une galerie'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadPhotographerGalleries(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: galleries.length,
              itemBuilder: (context, index) {
                final gallery = galleries[index];
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
                      '${gallery.photosCount ?? gallery.photos.length} photos • ${gallery.isPrivate ? "Privée" : "Publique"}',
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
