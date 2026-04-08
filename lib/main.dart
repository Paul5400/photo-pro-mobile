import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/gallery_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/upload_provider.dart';
import 'services/api_service.dart';
import 'views/login_screen.dart';
import 'views/profile_screen.dart';
import 'views/gallery_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
      ],
      child: const PhotoProApp(),
    ),
  );
}

class PhotoProApp extends StatelessWidget {
  const PhotoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoPro.net',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
          primary: const Color(0xFF2C3E50),
          secondary: const Color(0xFF18BC9C),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2C3E50),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF18BC9C), width: 2),
          ),
        ),
      ),
      home: const PublicGalleryScreen(),
    );
  }
}

class PublicGalleryScreen extends StatefulWidget {
  const PublicGalleryScreen({super.key});

  @override
  State<PublicGalleryScreen> createState() => _PublicGalleryScreenState();
}

class _PublicGalleryScreenState extends State<PublicGalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadPublicGalleries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'PhotoPro.net',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.lock_outline_rounded),
                onPressed: () => _showAccessCodeDialog(context),
                tooltip: 'Accès Galerie Privée',
              ),
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return IconButton(
                    icon: Icon(
                      auth.isAuthenticated
                          ? Icons.account_circle_rounded
                          : Icons.person_outline_rounded,
                    ),
                    onPressed: () {
                      if (auth.isAuthenticated) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          Consumer<GalleryProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (provider.errorMessage != null &&
                  provider.publicGalleries.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => provider.loadPublicGalleries(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (provider.publicGalleries.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune galerie publique',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    mainAxisExtent: 340,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final gallery = provider.publicGalleries[index];
                    return GalleryCard(gallery: gallery);
                  }, childCount: provider.publicGalleries.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<GalleryProvider>().loadPublicGalleries(),
        label: const Text('Actualiser'),
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  void _showAccessCodeDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Accès Galerie Privée'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saisissez le code fourni par votre photographe.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    labelText: 'Code d\'accès',
                    hintText: 'Ex: MARIAGE_2026',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final provider = context.read<GalleryProvider>();
                  final success = await provider.accessPrivateGallery(
                    codeController.text.trim(),
                  );
                  if (success && mounted) {
                    Navigator.pop(context); // Ferme le dialogue
                    // Navigue vers la galerie débloquée
                    if (provider.currentPrivateGallery != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => GalleryDetailScreen(
                                gallery: provider.currentPrivateGallery!,
                                accessCodeOverride:
                                    provider.lastPrivateAccessCode,
                              ),
                        ),
                      );
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(provider.errorMessage ?? 'Code invalide'),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Accéder'),
              ),
            ],
          ),
    );
  }
}

class GalleryCard extends StatelessWidget {
  final dynamic gallery;
  const GalleryCard({super.key, required this.gallery});

  @override
  Widget build(BuildContext context) {
    // On utilise la première photo comme image de couverture si coverUrl est vide
    final String effectiveCoverUrl =
        gallery.coverPhotoUrl.isNotEmpty
            ? gallery.coverPhotoUrl
            : (gallery.photos.isNotEmpty ? gallery.photos.first.url : '');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () async {
          try {
            // Pour les galeries publiques, l'accès se fait par l'ID simple
            final fullGallery = await ApiService().fetchGalleryWithAccess(
              gallery.id,
            );
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => GalleryDetailScreen(gallery: fullGallery),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Erreur lors du chargement des photos"),
                ),
              );
            }
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  effectiveCoverUrl.isNotEmpty
                      ? Image.network(
                        effectiveCoverUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  if (gallery.isPrivate)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Privé',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gallery.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    gallery.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${gallery.photosCount ?? gallery.photos.length} photos',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Détails',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
