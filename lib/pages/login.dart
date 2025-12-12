import 'package:flutter/material.dart';
import 'package:laundry_lens/components/title_app_design.dart';
import 'package:laundry_lens/constants.dart';
import 'package:laundry_lens/components/forms.dart';
import 'package:laundry_lens/components/button_login_signup.dart';
import 'package:laundry_lens/pages/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:laundry_lens/pages/forgot_password.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  static const String id = 'Login';
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool showSpinner = false;
  final _auth = FirebaseAuth.instance;
  late String email;
  late String password;
  String? errorMessage;
  bool showError = false;

  // Controller для управления скроллом / Contrôleur pour gérer le scroll
  final ScrollController _scrollController = ScrollController();

  // Метод для отображения ошибки / Méthode pour afficher l'erreur
  void _showError(String message) {
    setState(() {
      errorMessage = message;
      showError = true;
    });

    // Автоматически скрыть через 5 секунд / Masquer automatiquement après 5 secondes
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showError = false;
        });
      }
    });
  }

  // Метод для перевода ошибок Firebase / Méthode pour traduire les erreurs Firebase
  String _translateFirebaseError(String errorCode) {
    return firebaseErrorMessages[errorCode] ??
        'Произошла ошибка. Код: $errorCode'; // Произошла ошибка. Код: = Une erreur est survenue. Code:
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ГИБКОЕ ПРОСТРАНСТВО В НАЧАЛЕ / ESPACE FLEXIBLE AU DÉBUT
                      Flexible(flex: 1, child: SizedBox(height: 20)),

                      // ЗАГОЛОВКИ / TITRES
                      Column(
                        children: [
                          TitleAppDesign(textTitle: 'ДОБРО ПОЖАЛОВАТЬ'),
                          TitleAppDesign(textTitle: 'В LAUNDRY LENS'),
                        ],
                      ),

                      SizedBox(height: 20.0),

                      // СООБЩЕНИЕ ОБ ОШИБКЕ / MESSAGE D'ERREUR
                      if (showError && errorMessage != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
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
                                Icon(Icons.error, color: Colors.red),
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
                                  icon: Icon(Icons.close, size: 18),
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

                      // ФОРМЫ / FORMULAIRES
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmailField(
                              onChanged: (value) {
                                email = value;
                                // Скрыть ошибку, когда пользователь исправляет / Masquer l'erreur quand l'utilisateur corrige
                                if (showError) {
                                  setState(() {
                                    showError = false;
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 16.0),
                            PasswordField(
                              onChanged: (value) {
                                password = value;
                                // Скрыть ошибку, когда пользователь исправляет / Masquer l'erreur quand l'utilisateur corrige
                                if (showError) {
                                  setState(() {
                                    showError = false;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // КНОПКА ВХОДА / BOUTON DE CONNEXION
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            child: ButtonLoginSignup(
                              textButton: 'Войти', // Войти = Se connecter
                              colorButton: Color(0xFF1E40AF),
                              sizeButton: 40.0,
                              colorText: Colors.white,
                              onPressed: () async {
                                // Базовая валидация / Validation basique
                                if (email.isEmpty || password.isEmpty) {
                                  _showError(
                                    'Пожалуйста, заполните все поля', // Пожалуйста, заполните все поля = Veuillez remplir tous les champs
                                  );
                                  return;
                                }

                                setState(() {
                                  showSpinner = true;
                                  showError = false;
                                });

                                try {
                                  final user = await _auth
                                      .signInWithEmailAndPassword(
                                    email: email.trim(),
                                    password: password,
                                  );

                                  if (user != null) {
                                    saveFcmToken();
                                    Navigator.pushNamed(context, IndexPage.id);
                                  }

                                  setState(() {
                                    showSpinner = false;
                                  });
                                } on FirebaseAuthException catch (e) {
                                  // Обработка специфических ошибок Firebase / Gestion des erreurs Firebase spécifiques
                                  String message = _translateFirebaseError(
                                    e.code,
                                  );
                                  _showError(message);
                                  print(
                                    '🔥 Ошибка Firebase: ${e.code} - ${e.message}', // Ошибка Firebase = Erreur Firebase
                                  );

                                  setState(() {
                                    showSpinner = false;
                                  });
                                } catch (e) {
                                  // Общие ошибки / Erreurs générales
                                  _showError(
                                    'Произошла непредвиденная ошибка', // Произошла непредвиденная ошибка = Une erreur inattendue est survenue
                                  );
                                  print('❌ Общая ошибка: $e'); // Общая ошибка = Erreur générale

                                  setState(() {
                                    showSpinner = false;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    ForgotPasswordPage.id,
                                  );
                                },
                                child: Text(
                                  'Забыли пароль?', // Забыли пароль? = Mot de passe oublié?
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white70,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // РЕГИСТРАЦИЯ / INSCRIPTION
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 30.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Нет аккаунта?', // Нет аккаунта? = Pas de compte?
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      ' Регистрация', // Регистрация = S'inscrire
                                      style: sousTitreStyle.copyWith(
                                        color: Colors.lightBlueAccent,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.lightBlueAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

void saveFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': fcmToken,
    });
  }
}