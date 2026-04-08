import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gallery.dart';
import '../models/photo.dart';
import 'photo_comments_screen.dart';

class GalleryDetailScreen extends StatelessWidget {
  final Gallery gallery;
  final String? accessCodeOverride;

  const GalleryDetailScreen({
    super.key,
    required this.gallery,
    this.accessCodeOverride,
  });

  @override
  Widget build(BuildContext context) {
    final List<Photo> photos = gallery.photos;

    return Scaffold(
      appBar: AppBar(title: Text(gallery.title), centerTitle: true),
      body:
          photos.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('Cette galerie ne contient aucune photo.'),
                  ],
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gallery.description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gallery.publicationDate != null
                              ? 'Publié le ${DateFormat('dd/MM/yyyy').format(gallery.publicationDate!)}'
                              : 'Non publié',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const Divider(height: 32),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(context, photo),
                          child: Hero(
                            tag: photo.id,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photo.url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  void _showFullScreenImage(BuildContext context, Photo photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => FullScreenImageViewer(
              initialPhoto: photo,
              photos: gallery.photos,
              isPrivate: gallery.isPrivate,
              galleryId: gallery.id,
              accessCode: accessCodeOverride ?? gallery.accessCode,
            ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final Photo initialPhoto;
  final List<Photo> photos;
  final bool isPrivate;
  final String? galleryId;
  final String? accessCode;

  const FullScreenImageViewer({
    super.key,
    required this.initialPhoto,
    required this.photos,
    this.isPrivate = false,
    this.galleryId,
    this.accessCode,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.photos.indexOf(widget.initialPhoto);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.photos[_currentIndex].title != null &&
                  widget.photos[_currentIndex].title!.isNotEmpty
              ? widget.photos[_currentIndex].title!
              : "Photo",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PhotoCommentsScreen(
                        photo: widget.photos[_currentIndex],
                        galleryId: widget.galleryId,
                        isPrivateGallery: widget.isPrivate,
                        accessCode: widget.accessCode,
                      ),
                ),
              );
            },
            tooltip: 'Voir les commentaires',
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return Center(
                child: Hero(
                  tag: photo.id,
                  child: Image.network(
                    photo.url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 50,
                        ),
                  ),
                ),
              );
            },
          ),
          // Flèche gauche
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white70,
                    size: 40,
                  ),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          // Flèche droite
          if (_currentIndex < widget.photos.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 40,
                  ),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
