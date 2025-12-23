import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image/image.dart' as image_lib;
import 'dart:typed_data';
import '../../business_logic/providers/auth_provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _displayNameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom ne peut pas être vide')),
      );
      return;
    }

    try {
      await AuthService().currentFirebaseUser
          ?.updateDisplayName(_displayNameController.text.trim());
      await AuthService().currentFirebaseUser?.reload();
      
      if (!mounted) return;
      setState(() => _isEditingName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')),
      );
      return;
    }

    try {
      await AuthService().currentFirebaseUser
          ?.updatePassword(_newPasswordController.text);
      
      if (!mounted) return;
      setState(() {
        _isEditingPassword = false;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload en cours...')),
      );

      // Compress image to max 500x500
      final image_lib.Image? originalImage = image_lib.decodeImage(file.bytes!);
      if (originalImage == null) {
        throw 'Image invalide';
      }

      // Resize if too large
      final image_lib.Image resized = image_lib.copyResize(
        originalImage,
        width: originalImage.width > 500 ? 500 : originalImage.width,
        height: originalImage.height > 500 ? 500 : originalImage.height,
      );

      // Encode as JPEG
      final List<int> compressedBytes = image_lib.encodeJpg(resized, quality: 85);

       // Upload to Storage
      final storageService = StorageService();
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;

      final downloadUrl = await storageService.uploadAvatar(
        user.uid,
        Uint8List.fromList(compressedBytes),
      );

      // Update Firebase Auth photoURL
      await AuthService().currentFirebaseUser?.updatePhotoURL(downloadUrl);
      await AuthService().currentFirebaseUser?.reload();

      if (!mounted) return;
      
      // Refresh AuthProvider to update UI everywhere
      await context.read<AuthProvider>().refreshCurrentUser();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Trigger rebuild to show new avatar
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
          children: [
            // Avatar Section
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null || user.photoURL!.isEmpty
                      ? Text(
                          user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 18),
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                      onPressed: _pickAndUploadAvatar,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Display Name Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nom d\'affichage',
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: Icon(_isEditingName ? Icons.close : Icons.edit),
                          onPressed: () {
                            setState(() {
                              _isEditingName = !_isEditingName;
                              if (!_isEditingName) {
                                _displayNameController.text = user.displayName ?? '';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingName) ...[
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          hintText: 'Entrez votre nom',
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _updateDisplayName,
                        child: const Text('Enregistrer'),
                      ),
                    ] else
                      Text(user.displayName ?? 'Non défini'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Email',
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: Icon(_isEditingEmail ? Icons.close : Icons.edit),
                          onPressed: () {
                            setState(() {
                              _isEditingEmail = !_isEditingEmail;
                              if (!_isEditingEmail) {
                                _emailController.text = user.email;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingEmail) ...[
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Nouvel email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          // Show re-authentication dialog
                          final password = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final passwordController = TextEditingController();
                              return AlertDialog(
                                title: const Text('Ré-authentification requise'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Pour changer votre email, veuillez entrer votre mot de passe actuel.'),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Mot de passe actuel',
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.pop(context, passwordController.text);
                                    },
                                    child: const Text('Confirmer'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (password == null || password.isEmpty) return;

                          try {
                            // Re-authenticate
                            final authService = AuthService();
                            await authService.currentFirebaseUser?.reauthenticateWithCredential(
                              firebase_auth.EmailAuthProvider.credential(
                                email: user.email,
                                password: password,
                              ),
                            );

                            // Update email - sends verification to new email
                            await authService.currentFirebaseUser?.verifyBeforeUpdateEmail(_emailController.text.trim());
                            
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email mis à jour ! Vous allez être déconnecté.'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Sign out after email change
                            await Future.delayed(const Duration(seconds: 2));
                            if (!mounted) return;
                            await context.read<AuthProvider>().signOut();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Changer l\'email'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vous serez déconnecté après le changement',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ] else
                      Text(user.email),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mot de passe',
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: Icon(_isEditingPassword ? Icons.close : Icons.edit),
                          onPressed: () {
                            setState(() {
                              _isEditingPassword = !_isEditingPassword;
                              if (!_isEditingPassword) {
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isEditingPassword) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          hintText: 'Min. 6 caractères',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _updatePassword,
                        child: const Text('Modifier le mot de passe'),
                      ),
                    ] else
                      const Text('••••••••'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Danger Zone
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zone dangereuse',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                        // First confirmation
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer le compte'),
                            content: const Text(
                              'Êtes-vous sûr de vouloir supprimer votre compte ? '
                              'Cette action est irréversible et toutes vos données seront perdues.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                ),
                                child: const Text('Continuer'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        // Re-authentication required for account deletion
                        final password = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final passwordController = TextEditingController();
                            return AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Pour supprimer votre compte, veuillez entrer votre mot de passe.',
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Mot de passe',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context, passwordController.text);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                  child: const Text('Supprimer mon compte'),
                                ),
                              ],
                            );
                          },
                        );

                        if (password == null || password.isEmpty) return;

                        try {
                          // Re-authenticate
                          final authService = AuthService();
                          await authService.currentFirebaseUser?.reauthenticateWithCredential(
                            firebase_auth.EmailAuthProvider.credential(
                              email: user.email,
                              password: password,
                            ),
                          );

                          // Delete account
                          await authService.currentFirebaseUser?.delete();
                          
                          if (!mounted) return;
                          
                          // Close profile screen first
                          Navigator.of(context).pop();
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Compte supprimé avec succès'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Sign out (will automatically redirect to sign in screen)
                          await context.read<AuthProvider>().signOut();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de la suppression: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Supprimer le compte'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
