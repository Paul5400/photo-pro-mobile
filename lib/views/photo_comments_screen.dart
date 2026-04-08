import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/photo.dart';
import '../models/comment.dart';
import '../services/api_service.dart';

class PhotoCommentsScreen extends StatefulWidget {
  final Photo photo;
  final String? galleryId;
  final bool isPrivateGallery;
  final String? accessCode;

  const PhotoCommentsScreen({
    super.key,
    required this.photo,
    this.galleryId,
    this.isPrivateGallery = false,
    this.accessCode,
  });

  @override
  State<PhotoCommentsScreen> createState() => _PhotoCommentsScreenState();
}

class _PhotoCommentsScreenState extends State<PhotoCommentsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Comment> _comments = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _comments = List<Comment>.from(widget.photo.comments);
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isSending = true);
    bool success = false;

    try {
      if (widget.galleryId == null || widget.galleryId!.isEmpty) {
        throw Exception('Identifiant galerie manquant');
      }

      await _apiService.addComment(
        widget.galleryId!,
        widget.photo.id.toString(),
        _nameController.text.trim(),
        _commentController.text.trim(),
        accessCode:
            widget.isPrivateGallery ? (widget.accessCode ?? '').trim() : null,
      );
      success = true;
    } catch (e) {
      success = false;
    }

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        final newComment = Comment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          photoId: widget.photo.id,
          authorName: _nameController.text.trim(),
          content: _commentController.text.trim(),
          createdAt: DateTime.now(),
        );

        _commentController.clear();
        setState(() {
          _comments = [..._comments, newComment];
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Commentaire ajouté !')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            // On rend l'image flexible aussi pour éviter qu'elle ne prenne trop de place
            // si le clavier est ouvert ou sur un petit écran
            Flexible(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: Image.network(
                    widget.photo.url,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                          ),
                        ),
                  ),
                ),
              ),
            ),

            // Liste des commentaires (prend le reste de la place disponible)
            Expanded(
              flex: 3,
              child:
                  _comments.isEmpty
                      ? const Center(
                        child: Text('Aucun commentaire pour le moment.'),
                      )
                      : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final c = _comments[index];
                          return ListTile(
                            title: Text(
                              c.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(c.content),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(c.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),

            // Formulaire d'ajout (fixe en bas)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Votre pseudo',
                      prefixIcon: Icon(Icons.person_outline),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines:
                              1, // On limite à 1 ligne pour économiser de l'espace
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : IconButton(
                            onPressed: _submitComment,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Color(0xFF18BC9C),
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
