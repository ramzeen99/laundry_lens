import 'dart:async';
import 'package:flutter/material.dart';
import 'package:laundry_lens/components/title_app_design.dart';
import 'notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_lens/pages/onboarding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/machine_provider.dart';
import '../providers/notification_provider.dart';
import '../model/model.dart';
import '../components/machine_card.dart';
import '../services/firebase_service.dart';
import 'package:laundry_lens/providers/preferences_provider.dart';
import 'package:laundry_lens/providers/user_provider.dart';
import 'profil_page.dart';
import 'package:laundry_lens/pages/help_page.dart';
//import 'package:laundry_lens/services/background_notification_service.dart';

class IndexPage extends StatefulWidget {
  static const String id = 'Index';
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  Timer? _timer;
  bool _isRefreshing = false;
  bool _isCheckingAuth = true; // ✅ НОВОЕ: Проверка аутентификации
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  @override
  void initState() {
    super.initState();
    _checkAuthAndInitialize();
  }

  // ✅ НОВЫЙ МЕТОД ДЛЯ ПРОВЕРКИ АУТЕНТИФИКАЦИИ
  void _checkAuthAndInitialize() async {
    //print('🔄 IndexPage - Проверка аутентификации...');

    // Ожидание инициализации UserProvider
    final userProvider = context.read<UserProvider>();
    //await userProvider.waitForInitialization();

    // Проверка, авторизован ли пользователь
    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      //print('❌ Пользователь не авторизован, перенаправление на onboarding');
      if (mounted) {
        Navigator.pushReplacementNamed(context, OnboardingPage.id);
        return;
      }
    }

    // Если авторизован, нормальная инициализация
    //print('✅ Пользователь авторизован: ${userProvider.currentUser!.email}');

    setState(() {
      _isCheckingAuth = false;
    });

    _startTimer();
    _initializeData();

    //print('✅ IndexPage успешно инициализирован');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeData() async {
    try {
      final userProvider = context.read<UserProvider>();
      final utilisateur = userProvider.currentUser;
      if (utilisateur == null) return;

      final dormPath = utilisateur.dormPath;

      final machineProvider = context.read<MachineProvider>();
      await machineProvider.loadMachines(dormPath!);

    } catch (e) {}
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // ✅ ПРИНУДИТЕЛЬНОЕ ОБНОВЛЕНИЕ ДЛЯ ОТОБРАЖЕНИЯ ТАЙМЕРОВ В РЕАЛЬНОМ ВРЕМЕНИ
      if (mounted) {
        setState(() {
          // Просто принудительная перерисовка для обновления таймеров
        });
      }
      //print('⏰ Обновление интерфейса - ${DateTime.now()}');
    });
  }

  Future<void> _refreshData() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await context.read<MachineProvider>().loadMachines();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      messenger.showSnackBar(
        SnackBar(
          content: const Text('✅ Данные обновлены'), // Данные обновлены
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: ${e.toString()}'), // Ошибка
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // МЕТОД ДЛЯ ЗАПУСКА МАШИНЫ
  Future<void> _startMachine(Machine machine) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser!;
      final dormPath = user.dormPath;

      await context.read<MachineProvider>().demarrerMachine(
        machineId: machine.id,
        dormPath: dormPath,
        utilisateur: user.email,
        notificationProvider: context.read<NotificationProvider>(),
        preferencesProvider: context.read<PreferencesProvider>(), userProvider: null,
      );

      messenger.showSnackBar(
        SnackBar(content: Text('✅ ${machine.nom} démarrée'), backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }


  // МЕТОД ДЛЯ ОСВОБОЖДЕНИЯ МАШИНЫ
  Future<void> _releaseMachine(Machine machine) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final machineProvider = context.read<MachineProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      //print('🔄 Освобождение машины: ${machine.nom}');

      await machineProvider.libererMachine(
        machineId: machine.id,
        notificationProvider: notificationProvider,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ ${machine.nom} освобождена'), // Машина освобождена
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      //print('❌ Ошибка освобождения машины: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: ${e.toString()}'), // Ошибка
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMachineAction(Machine machine) {
    //print('🎯 Действие с машиной: ${machine.nom} - Статус: ${machine.statut}');

    switch (machine.statut) {
      case MachineStatus.libre:
        _showStartDialog(machine);
        break;
      case MachineStatus.termine:
        _showReleaseDialog(machine);
        break;
      case MachineStatus.occupe:
        _showMachineInfo(machine);
        break;
    }
  }

  void _showStartDialog(Machine machine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Запустить машину'), // Запустить машину
          content: Text('Запустить ${machine.nom}? (40 минут)'), // Запустить машину? (5 минут)
          actions: [
            TextButton(
              child: const Text('Отмена'), // Отмена
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Запустить'), // Запустить
              onPressed: () async {
                Navigator.of(context).pop();
                await _startMachine(machine);
              },
            ),
          ],
        );
      },
    );
  }

  void _showReleaseDialog(Machine machine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Освободить машину'), // Освободить машину
          content: Text('Освободить ${machine.nom}?'), // Освободить машину?
          actions: [
            TextButton(
              child: const Text('Отмена'), // Отмена
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Освободить'), // Освободить
              onPressed: () async {
                Navigator.of(context).pop();
                await _releaseMachine(machine);
              },
            ),
          ],
        );
      },
    );
  }

  void _showMachineInfo(Machine machine) {
    final machineProvider = context.read<MachineProvider>();
    final remainingTime = machineProvider.getRemainingTime(machine.id);
    final hasActiveTimer = machineProvider.hasActiveTimer(machine.id);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(machine.nom),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статус: Занята', // Статус: Занята
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (remainingTime != null)
                Text(
                  'Осталось времени: $remainingTime минут', // Осталось времени
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              if (remainingTime == null && hasActiveTimer)
                Text(
                  'Таймер активен, но время недоступно', // Таймер активен, но время недоступно
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
              if (!hasActiveTimer)
                Text(
                  'Нет активного таймера', // Нет активного таймера
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              SizedBox(height: 10),
              Text('Пользователь: ${machine.utilisateurActuel ?? 'Неизвестно'}'), // Пользователь
              SizedBox(height: 10),
              Text(
                '⏰ Таймер независимый и постоянный', // Таймер независимый и постоянный
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Закрыть'), // Закрыть
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getCurrentUser() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user != null) {
      return user.email; // Неизвестный пользователь
    }

    return 'Тестовый пользователь'; // Тестовый пользователь
  }

  void _showNotifications() {
    Navigator.pushNamed(context, NotificationsPage.id);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из системы'), // Выход из системы
          content: const Text('Вы уверены, что хотите выйти?'), // Вы уверены, что хотите выйти?
          actions: [
            TextButton(
              child: const Text('Отмена'), // Отмена
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Выйти', // Выйти
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                _performLogout();
                Navigator.pushNamed(context, OnboardingPage.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    final userProvider = context.read<UserProvider>();
    userProvider.signOut();
    //print('Пользователь вышел из системы'); // Пользователь вышел из системы
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ПОКАЗЫВАТЬ ЗАГРУЗКУ, ЕСЛИ ПРОВЕРЯЕТСЯ АУТЕНТИФИКАЦИЯ
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Color(0xFF459380),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Проверка подключения...', // Проверка подключения...
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF459380),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const TitleAppDesign(textTitle: 'LAUNDRY LENS'), // Название остается без изменений
        actions: [
          _isRefreshing
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Обновить', // Обновить
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showNotifications,
                tooltip: 'Уведомления', // Уведомления
              ),
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  if (notificationProvider.unreadCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          notificationProvider.unreadCount > 9
                              ? '9+'
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
        backgroundColor: const Color(0xFF459380),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: Consumer<MachineProvider>(
        builder: (context, machineProvider, child) {
          if (machineProvider.isLoading && !_isRefreshing) {
            return _buildLoadingScreen();
          }

          if (machineProvider.machines.isEmpty) {
            return _buildEmptyScreen();
          }

          return _buildBody(machineProvider.machines, machineProvider);
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.currentUser;
                    final hasUserPhoto =
                        user?.photoURL != null && user!.photoURL!.isNotEmpty;

                    return UserAccountsDrawerHeader(
                      accountName: Text(
                        user?.displayName ?? user?.email ?? 'Пользователь', // Пользователь
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      accountEmail: user != null
                          ? Text(user.email) // Email недоступен
                          : const Text('Не подключен'), // Не подключен
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: hasUserPhoto
                            ? NetworkImage(user.photoURL!)
                            : null,
                        backgroundColor: Colors.blueGrey[300],
                        child: hasUserPhoto
                            ? null
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                      decoration: const BoxDecoration(color: Color(0xFF459380)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Мой профиль'), // Мой профиль
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, ProfilePage.id);
                  },
                ),
                // ИЗМЕНИТЬ LISTTILE "ПОМОЩЬ" В DRAWER
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Помощь'), // Помощь
                  onTap: () {
                    Navigator.pop(context); // Закрыть drawer
                    Navigator.pushNamed(
                      context,
                      HelpPage.id,
                    ); // Перейти на страницу помощи
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 100.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Выход', // Выход
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Удалить аккаунт', // Supprimer le compte
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Fermer le drawer
                    _showDeleteAccountDialog(context);
                  },
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Machine> machines, MachineProvider machineProvider) {
    return Container(
      color: const Color(0xFF459380),
      child: Column(
        children: [
          _buildStatsHeader(machines, machineProvider),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildMachinesGrid(machines, machineProvider),
            ),
          ),
          // В классе _IndexPageState, в методе build, добавь:
          /*  FloatingActionButton(
            onPressed: () async {
              // Простой тест уведомлений
              await SimpleBackgroundService.showNotification(
                title: 'Test Machine',
                body: 'Timer démarré pour Machine 1',
              );

              // Запланированный тест (30 секунд)
              await SimpleBackgroundService.scheduleNotification(
                title: '⏰ Rappel',
                body: 'Vérifiez votre machine',
                delay: Duration(seconds: 30),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notifications test envoyées!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Icon(Icons.notifications),
            backgroundColor: Color(0xFF459380),
          ),*/
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
      List<Machine> machines,
      MachineProvider machineProvider,
      ) {
    final machinesLibres = machines
        .where((m) => m.statut == MachineStatus.libre)
        .length;
    final machinesOccupees = machines
        .where((m) => m.statut == MachineStatus.occupe)
        .length;
    final machinesTerminees = machines
        .where((m) => m.statut == MachineStatus.termine)
        .length;
    final activeTimers = machineProvider.activeTimers
        .where((t) => t.isActive)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Всего', // Всего
                machines.length.toString(),
                Icons.local_laundry_service,
              ),
              _buildStatItem(
                'Свободны', // Свободны
                machinesLibres.toString(),
                Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatItem(
                'Заняты', // Заняты
                machinesOccupees.toString(),
                Icons.timer,
                color: Colors.orange,
              ),
              _buildStatItem(
                'Завершены', // Завершены
                machinesTerminees.toString(),
                Icons.done_all,
                color: Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 10),
          // ✅ ОТОБРАЖЕНИЕ АКТИВНЫХ ТАЙМЕРОВ
          if (activeTimers > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '$activeTimers активный(е) таймер(ы)', // активный(е) таймер(ы)
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title,
      String value,
      IconData icon, {
        Color color = Colors.blue,
      }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Загрузка машин...', // Загрузка машин...
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_laundry_service,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет доступных машин', // Нет доступных машин
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Попробовать снова'), // Попробовать снова
          ),
        ],
      ),
    );
  }

  Widget _buildMachinesGrid(
      List<Machine> machines,
      MachineProvider machineProvider,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.4,
        ),
        itemCount: machines.length,
        itemBuilder: (context, index) {
          final machine = machines[index];
          final remainingTime = machineProvider.getRemainingTime(machine.id);
      //    final hasActiveTimer = machineProvider.hasActiveTimer(machine.id);

          // ✅ СОЗДАТЬ КОПИЮ МАШИНЫ С РЕАЛЬНЫМ ВРЕМЕНЕМ
          final machineWithRealTime = Machine(
            id: machine.id,
            nom: machine.nom,
            emplacement: machine.emplacement,
            statut: machine.statut,
            tempsRestant: remainingTime, // ✅ РЕАЛЬНОЕ ВРЕМЯ таймера
            utilisateurActuel: machine.utilisateurActuel,
          );

          return MachineCard(
            machine:
            machineWithRealTime, // ✅ ИСПОЛЬЗОВАТЬ МАШИНУ С РЕАЛЬНЫМ ВРЕМЕНЕМ
            onActionPressed: _handleMachineAction,
          );
        },
      ),
    );
  }
}
// 1️⃣ Fonction pour supprimer le compte Firebase et les données Firestore
Future<void> deleteAccount(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Пользователь не найден'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String uid = user.uid;

    // Supprimer les données Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    // Supprimer le compte Firebase Authentication
    await user.delete();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('✅ Аккаунт успешно удален'),
        backgroundColor: Colors.green,
      ),
    );

    // Rediriger vers OnboardingPage
    navigator.pushReplacementNamed(OnboardingPage.id);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              '⚠ Для удаления аккаунта необходимо заново войти в систему'),
          backgroundColor: Colors.orange,
        ),
      );
      // Ici, tu peux demander la re-authentification de l’utilisateur
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка Firebase: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Ошибка при удалении аккаунта: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// 2️⃣ Dialog pour confirmer la suppression
void _showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Подтвердите удаление'), // Confirmer la suppression
        content: const Text(
            'Вы уверены, что хотите удалить свой аккаунт и все данные? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            child: const Text('Отмена'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();
              await deleteAccount(context);
            },
          ),
        ],
      );
    },
  );
}
