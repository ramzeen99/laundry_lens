import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_lens/model/user_model.dart';

class UserProvider with ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = true; // ✅ Начинается с true
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProvider() {
    print('🚀 UserProvider инициализирован');
    _initializeAuth();
  }

  // 🚀 АСИНХРОННАЯ ИНИЦИАЛИЗАЦИЯ / INITIALISATION ASYNCHRONE
  void _initializeAuth() {
    print('🔄 Инициализация аутентификации...');

    // Слушаем изменения аутентификации / Écouter les changements d'authentification
    _auth.authStateChanges().listen(
          (User? user) {
        print('🔄 Обнаружено изменение AuthStateChanges: ${user?.email}');

        if (user != null) {
          _currentUser = AppUser.fromFirebaseUser(user);
          print('✅ Пользователь вошёл через authStateChanges: ${user.email}');
        } else {
          _currentUser = null;
          print('ℹ️ Нет пользователя через authStateChanges');
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        print('❌ Ошибка authStateChanges: $e');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    // Загружаем текущего пользователя немедленно / Charger l'utilisateur courant immédiatement
    _loadCurrentUserImmediately();
  }

  // 🚀 НЕМЕДЛЕННАЯ ЗАГРУЗКА / CHARGEMENT IMMÉDIAT
  void _loadCurrentUserImmediately() {
    try {
      final User? currentUser = _auth.currentUser;
      print('🔍 Текущий пользователь Firebase: ${currentUser?.email}');

      if (currentUser != null) {
        _currentUser = AppUser.fromFirebaseUser(currentUser);
        print('✅ Пользователь загружен немедленно: ${_currentUser!.email}');
      } else {
        print('ℹ️ Нет пользователя в Firebase Auth');
      }
    } catch (e) {
      print('❌ Ошибка немедленной загрузки: $e');
      _error = e.toString();
    }
  }

  Future<void> waitForInitialization() async {
    // Если уже инициализировано, сразу возвращаем / If already initialized, return immediately
    if (!_isLoading) return;

    // Ждём завершения загрузки / Wait until loading is complete
    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));
      return _isLoading;
    });
  }

  // ✏️ Обновить отображаемое имя / Mettre à jour le nom d'affichage
  Future<void> updateDisplayName(String displayName) async {
    try {
      if (_auth.currentUser == null) return;

      await _auth.currentUser!.updateDisplayName(displayName);
      await _auth.currentUser!.reload();

      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        _currentUser = AppUser.fromFirebaseUser(refreshedUser);
      }

      notifyListeners();
      print('✅ Имя обновлено: $displayName');
    } catch (e) {
      _error = 'Ошибка обновления имени: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 🚪 Выход из системы / Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
      print('✅ Выход выполнен успешно');
    } catch (e) {
      _error = 'Ошибка выхода: $e';
      notifyListeners();
      rethrow;
    }
  }
}