import 'package:flutter/material.dart';
import 'package:laundry_lens/components/title_app_design.dart';
import 'package:laundry_lens/constants.dart';
import 'package:laundry_lens/components/button_login_signup.dart';
import 'package:laundry_lens/pages/login.dart';
import 'package:laundry_lens/components/forms.dart';
import 'package:laundry_lens/pages/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Registration extends StatefulWidget {
  static const String id = 'Registration';
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;
  String email = '';
  String password = '';
  String name = '';
  String? errorMessage;
  bool showError = false;

  // Méthode pour afficher l'erreur / Метод отображения ошибок
  void _showError(String message) {
    setState(() {
      errorMessage = message;
      showError = true;
    });

    // Masquer automatiquement après 5 secondes / Автоматически скрыть через 5 секунд
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showError = false;
        });
      }
    });
  }

  // Méthode pour traduire les erreurs Firebase / Метод перевода ошибок Firebase
  String _translateFirebaseError(String errorCode) {
    // Messages d'erreur en français / Сообщения об ошибках на русском
    const Map<String, String> firebaseErrorMessages = {
      // Erreurs d'inscription / Ошибки регистрации
      'email-already-in-use': 'Этот адрес электронной почты уже используется.',
      'invalid-email': 'Неверный адрес электронной почты.',
      'operation-not-allowed': 'Регистрация по email не активирована.',
      'weak-password':
      'Пароль слишком слабый (минимум 6 символов).',

      // Erreurs générales / Общие ошибки
      'network-request-failed': 'Ошибка соединения. Проверьте интернет.',
      'user-disabled': 'Эта учетная запись отключена.',
      'user-not-found': 'Пользователь не найден.',
      'wrong-password': 'Неверный пароль.',
      'too-many-requests': 'Слишком много попыток. Попробуйте позже.',
    };

    return firebaseErrorMessages[errorCode] ??
        'Произошла ошибка. Код: $errorCode';
  }

  // Validation des champs / Проверка полей
  bool _validateFields() {
    if (name.isEmpty) {
      _showError('Пожалуйста, введите ваше имя');
      return false;
    }

    if (name.length < 2) {
      _showError('Имя должно содержать не менее 2 символов');
      return false;
    }

    if (email.isEmpty) {
      _showError('Пожалуйста, введите ваш email');
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError('Пожалуйста, введите действительный адрес электронной почты');
      return false;
    }

    if (password.isEmpty) {
      _showError('Пожалуйста, введите пароль');
      return false;
    }

    if (password.length < 6) {
      _showError('Пароль должен содержать не менее 6 символов');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF459380),
      appBar: AppBar(
        title: TitleAppDesign(textTitle: 'LAUNDRY LENS'),
        backgroundColor: Color(0xFF459380),
        centerTitle: true,
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20.0),
                  TitleAppDesign(textTitle: 'ДОБРО ПОЖАЛОВАТЬ '),
                  TitleAppDesign(textTitle: 'В LAUNDRY LENS'),

                  // MESSAGE D'ERREUR / СООБЩЕНИЕ ОБ ОШИБКЕ
                  if (showError && errorMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 16),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  showError = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 20.0),

                  NameField(
                    onChanged: (value) {
                      setState(() {
                        name = value;
                        if (showError) showError = false;
                      });
                    },
                  ),
                  SizedBox(height: 20.0),
                  EmailField(
                    onChanged: (value) {
                      setState(() {
                        email = value;
                        if (showError) showError = false;
                      });
                    },
                  ),
                  SizedBox(height: 20.0),
                  PasswordField(
                    onChanged: (value) {
                      setState(() {
                        password = value;
                        if (showError) showError = false;
                      });
                    },
                  ),

                  // INDICATEUR DE FORCE DU MOT DE PASSE / ИНДИКАТОР СЛОЖНОСТИ ПАРОЛЯ
                  if (password.isNotEmpty) ...[
                    SizedBox(height: 10),
                    _buildPasswordStrengthIndicator(),
                    SizedBox(height: 10),
                  ],

                  SizedBox(height: 30.0),

                  Container(
                    width: double.infinity,
                    child: ButtonLoginSignup(
                      textButton: 'ЗАРЕГИСТРИРОВАТЬСЯ',
                      colorButton: Color(0xFF1E40AF),
                      sizeButton: 25.0,
                      colorText: Colors.white,
                      onPressed: () async {
                        // Fermer le clavier / Закрыть клавиатуру
                        FocusScope.of(context).unfocus();

                        // Valider les champs / Проверить поля
                        if (!_validateFields()) {
                          return;
                        }

                        setState(() {
                          showSpinner = true;
                          showError = false;
                        });

                        try {
                          final newUser = await _auth
                              .createUserWithEmailAndPassword(
                            email: email.trim(),
                            password: password,
                          );

                          // ✅ SAUVEGARDER LE NOM DANS LE PROFIL UTILISATEUR / СОХРАНИТЬ ИМЯ В ПРОФИЛЕ ПОЛЬЗОВАТЕЛЯ
                          if (newUser.user != null && name.isNotEmpty) {
                            try {
                              await newUser.user!.updateDisplayName(
                                name.trim(),
                              );
                              // Recharger pour obtenir les données mises à jour / Перезагрузить для получения обновленных данных
                              await newUser.user!.reload();
                              print('✅ Имя сохранено: $name');
                            } catch (e) {
                              print('⚠️ Ошибка сохранения имени: $e');
                              // Continuer même si le nom n'est pas sauvegardé / Продолжить, даже если имя не сохранено
                            }
                          }

                          if (newUser.user != null) {
                            print(
                              '✅ Учетная запись успешно создана: ${newUser.user!.email}',
                            );
                            Navigator.pushNamed(context, IndexPage.id);
                          }

                          setState(() {
                            showSpinner = false;
                          });
                        } on FirebaseAuthException catch (e) {
                          // Gestion spécifique des erreurs Firebase / Обработка ошибок Firebase
                          String message = _translateFirebaseError(e.code);
                          _showError(message);
                          print('🔥 Ошибка Firebase: ${e.code} - ${e.message}');

                          setState(() {
                            showSpinner = false;
                          });
                        } catch (e) {
                          // Erreurs générales / Общие ошибки
                          String errorMsg = 'Ошибка при регистрации';
                          if (e.toString().contains('no internet')) {
                            errorMsg = 'Нет подключения к интернету';
                          } else if (e.toString().contains('timeout')) {
                            errorMsg = 'Время ожидания истекло';
                          }
                          _showError(errorMsg);
                          print('❌ Ошибка регистрации: $e');

                          setState(() {
                            showSpinner = false;
                          });
                        }
                      },
                    ),
                  ),

                  SizedBox(height: 30.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Уже есть аккаунт?',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Login.id);
                        },
                        child: Text(
                          ' Войти',
                          style: sousTitreStyle.copyWith(
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // INDICATEUR VISUEL DE FORCE DU MOT DE PASSE / ВИЗУАЛЬНЫЙ ИНДИКАТОР СЛОЖНОСТИ ПАРОЛЯ
  Widget _buildPasswordStrengthIndicator() {
    Color color;
    String text;
    int strength = _calculatePasswordStrength(password);

    if (strength == 0) {
      color = Colors.red;
      text = 'Очень слабый';
    } else if (strength == 1) {
      color = Colors.orange;
      text = 'Слабый';
    } else if (strength == 2) {
      color = Colors.yellow[700]!;
      text = 'Средний';
    } else {
      color = Colors.green;
      text = 'Сильный';
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сложность пароля: $text',
            style: TextStyle(color: color, fontSize: 14),
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: (strength + 1) / 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  // CALCUL SIMPLE DE LA FORCE DU MOT DE PASSE / ПРОСТОЙ РАСЧЕТ СЛОЖНОСТИ ПАРОЛЯ
  int _calculatePasswordStrength(String password) {
    int score = 0;

    // Longueur / Длина
    if (password.length >= 8) score++;

    // Contient des chiffres / Содержит цифры
    if (password.contains(RegExp(r'[0-9]'))) score++;

    // Contient des majuscules / Содержит заглавные буквы
    if (password.contains(RegExp(r'[A-Z]'))) score++;

    // Contient des caractères spéciaux / Содержит специальные символы
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score.clamp(0, 3);
  }
}