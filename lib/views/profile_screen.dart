import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'upload_screen.dart';
import 'upload_history_screen.dart';
import 'photographer_galleries_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil Photographe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Normalement on arrive ici seulement si authentifié,
          // mais on ajoute une sécurité.
          if (!auth.isAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Veuillez vous connecter.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar / Photo de profil stylisée
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Informations principales
                Text(
                  'Bienvenue, ${auth.userEmail?.split('@').first ?? 'Photographe'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez vos galeries et vos clichés',
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 40),

                // Cartes d'actions
                _buildInfoTile(
                  context,
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: auth.userEmail ?? 'Non renseigné',
                ),
                const SizedBox(height: 16),
                _buildInfoTile(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: 'Mes galeries',
                  subtitle: 'Gérer vos dossiers de photos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const PhotographerGalleriesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoTile(
                  context,
                  icon: Icons.cloud_upload_outlined,
                  title: 'Upload Photo (Option B)',
                  subtitle: 'Ajouter du contenu à vos galeries',
                  isPrimary: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoTile(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Historique des Uploads',
                  subtitle: 'Voir vos derniers envois',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadHistoryScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Bouton déconnexion secondaire
                OutlinedButton.icon(
                  onPressed: () {
                    auth.logout();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return Card(
      elevation: isPrimary ? 4 : 0,
      color:
          isPrimary
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
              : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          icon,
          color:
              isPrimary
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing:
            onTap != null
                ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
                : null,
        onTap: onTap,
      ),
    );
  }
}
