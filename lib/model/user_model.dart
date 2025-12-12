import 'package:firebase_auth/firebase_auth.dart';

// FR : Classe représentant un utilisateur de l'application
// RU : Класс, представляющий пользователя приложения
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool? emailVerified;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified,
  });

  // 🏭 Factory depuis Firebase User
  // 🏭 Фабрика из Firebase User
  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? 'Электронная почта не определена', // FR : Email non défini // RU : Email non défini traduit en russe
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  // 📝 Copie avec modifications
  // 📝 Копия с изменениями
  AppUser copyWith({String? displayName, String? photoURL}) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified,
    );
  }

  // 🎯 Getter pour le nom d'affichage
  // 🎯 Геттер для отображаемого имени
  String get displayNameOrEmail => displayName ?? email;

  // 🎯 Getter pour vérifier si l'utilisateur a une photo (CORRIGÉ)
  // 🎯 Геттер для проверки, есть ли у пользователя фото (ИСПРАВЛЕНО)
  bool get hasPhoto => photoURL != null && photoURL!.isNotEmpty;
}
