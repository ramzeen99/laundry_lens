import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundry_lens/model/model.dart';
import 'package:laundry_lens/services/firebase_service.dart';
import 'package:laundry_lens/model/notification_model.dart';
import 'package:laundry_lens/providers/notification_provider.dart';
import 'package:laundry_lens/services/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundry_lens/services/background_notification_service.dart';
import 'package:laundry_lens/services/local_notification_service.dart';
import 'package:laundry_lens/providers/preferences_provider.dart';
import 'package:laundry_lens/services/background_notification_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// Запланировать таймер завершения работы машины / Schedule machine end timer
void scheduleMachineEndTimer(int machineDurationInSeconds) {
  AndroidAlarmManager.oneShot(
    Duration(seconds: machineDurationInSeconds),
    // Уникальный ID / Unique ID
    12345,
    timerFinishedCallback,
    wakeup: true,
    exact: true,
  );
}

class MachineTimer {
  final String machineId;
  final int totalMinutes;
  final DateTime startTime;
  bool isActive;
  final String? startedByUser;

  MachineTimer({
    required this.machineId,
    required this.totalMinutes,
    required this.startTime,
    required this.isActive,
    this.startedByUser,
  });

  int get remainingMinutes {
    if (!isActive) return 0;

    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMinutes;
    final remaining = totalMinutes - elapsed;

    return remaining > 0 ? remaining : 0;
  }

  bool get isFinished => remainingMinutes <= 0;

  Map<String, dynamic> toMap() {
    return {
      'machineId': machineId,
      'totalMinutes': totalMinutes,
      'startTime': startTime.millisecondsSinceEpoch,
      'isActive': isActive,
      'startedByUser': startedByUser,
    };
  }

  static MachineTimer fromMap(Map<String, dynamic> map) {
    return MachineTimer(
      machineId: map['machineId'],
      totalMinutes: map['totalMinutes'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      isActive: map['isActive'],
      startedByUser: map['startedByUser'],
    );
  }
}

class MachineProvider with ChangeNotifier {
  List<Machine> _machines = [];
  List<MachineTimer> _activeTimers = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timerChecker;

  List<Machine> get machines => _machines;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MachineTimer> get activeTimers => _activeTimers;

  StreamSubscription<QuerySnapshot>? _machinesSubscription;

  MachineProvider() {
    _initialize();
  }

  // 🚀 ПОЛНАЯ ИНИЦИАЛИЗАЦИЯ / COMPLETE INITIALIZATION
  Future<void> _initialize() async {
    await _loadTimersFromStorage();
    await loadMachines();
    _startTimerChecker();
    print(
      '✅ MachineProvider инициализирован с ${_activeTimers.length} активными таймерами / initialized with ${_activeTimers.length} active timers',
    );
  }

  // 💾 СОХРАНИТЬ таймеры локально / SAVE timers locally
  Future<void> _saveTimersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timersJson = _activeTimers.map((timer) => timer.toMap()).toList();
      await prefs.setString('active_machine_timers', json.encode(timersJson));
      print('💾 ${_activeTimers.length} таймеров сохранено / timers saved');
    } catch (e) {
      print('❌ Ошибка сохранения таймеров: $e / Error saving timers: $e');
    }
  }

  // 📥 ЗАГРУЗИТЬ таймеры из локального хранилища / LOAD timers from local storage
  Future<void> _loadTimersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timersJson = prefs.getString('active_machine_timers');

      if (timersJson != null) {
        final List<dynamic> timersList = json.decode(timersJson);
        _activeTimers = timersList.map((timerMap) {
          return MachineTimer.fromMap(timerMap);
        }).toList();

        // 🔄 Очистить завершенные таймеры / Clean up finished timers
        final initialCount = _activeTimers.length;
        _activeTimers = _activeTimers.where((timer) {
          if (timer.isFinished) {
            print('🗑️ Завершенный таймер удален: ${timer.machineId} / Finished timer removed: ${timer.machineId}');
            return false;
          }
          return true;
        }).toList();

        if (initialCount != _activeTimers.length) {
          await _saveTimersToStorage();
        }

        print(
          '📥 ${_activeTimers.length} таймеров загружено из локального хранилища / timers loaded from local storage',
        );
      }
    } catch (e) {
      print('❌ Ошибка загрузки таймеров: $e / Error loading timers: $e');
    }
  }

  // Загрузить машины из Firebase / Load machines from Firebase
  Future<void> loadMachines() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseService.initializeTestData();

      _machinesSubscription = FirebaseService.getMachinesStream().listen(
            (QuerySnapshot snapshot) {
          _machines = snapshot.docs.map((doc) {
            return Machine.fromFirebase(doc.data() as Map<String, dynamic>);
          }).toList();

          _machines.sort((a, b) => a.id.compareTo(b.id));

          // 🔄 Синхронизировать таймеры с машинами / Synchronize timers with machines
          _syncTimersWithMachines();

          _isLoading = false;
          notifyListeners();

          print('🔄 ${_machines.length} машин загружено из Firebase / machines loaded from Firebase');
        },
        onError: (error) {
          _error = 'Ошибка загрузки: $error / Loading error: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Ошибка: $e / Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔄 СИНХРОНИЗИРОВАТЬ локальные таймеры с машинами Firebase / SYNCHRONIZE local timers with Firebase machines
  void _syncTimersWithMachines() {
    for (final timer in _activeTimers) {
      final machineIndex = _machines.indexWhere((m) => m.id == timer.machineId);
      if (machineIndex != -1) {
        // Обновить оставшееся время в машине / Update remaining time in machine
        _machines[machineIndex] = Machine(
          id: _machines[machineIndex].id,
          nom: _machines[machineIndex].nom,
          emplacement: _machines[machineIndex].emplacement,
          statut: timer.isFinished
              ? MachineStatus.termine
              : MachineStatus.occupe,
          tempsRestant: timer.remainingMinutes,
          utilisateurActuel: timer.startedByUser,
        );
      }
    }
    notifyListeners();
  }

  // Запустить машину С ТАЙМЕРОМ / Start a machine WITH TIMER
  Future<void> demarrerMachine({
    required String machineId,
    required String utilisateur,
    required NotificationProvider notificationProvider,
    required PreferencesProvider preferencesProvider,
  }) async {
    try {
      final oldMachine = _machines.firstWhere((m) => m.id == machineId);

      // 🎯 СОЗДАТЬ ТАЙМЕР / CREATE A TIMER
      final newTimer = MachineTimer(
        machineId: machineId,
        totalMinutes: 5, // 5 минут для тестов / 5 minutes for tests
        startTime: DateTime.now(),
        isActive: true,
        startedByUser: utilisateur,
      );

      // Добавить локальный таймер / Add local timer
      _activeTimers.removeWhere((timer) => timer.machineId == machineId);
      _activeTimers.add(newTimer);
      await _saveTimersToStorage();

      // --- Сохранить запланированный будильник в SharedPreferences / Save scheduled alarm in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      const String alarmsKey = 'scheduled_machine_alarms';

      List<dynamic> scheduled = [];
      final raw = prefs.getString(alarmsKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          scheduled = json.decode(raw) as List<dynamic>;
        } catch (_) {
          scheduled = [];
        }
      }

      // Вычислить запланированное время (миллисекунды) / Calculate scheduled time (millis)
      final scheduledAt = DateTime.now()
          .add(Duration(minutes: newTimer.totalMinutes))
          .millisecondsSinceEpoch;

      // Добавить новый будильник / Add new alarm
      scheduled.add({
        'machineId': machineId,
        'machineName': oldMachine.nom,
        'location': oldMachine.emplacement,
        'scheduledAt': scheduledAt,
      });

      // Сохранить / Save
      await prefs.setString(alarmsKey, json.encode(scheduled));

      // Запланировать AndroidAlarmManager для вызова callback (верхнего уровня) / Schedule AndroidAlarmManager to call callback (top-level)
      // Использовать уникальный ID для каждой машины (machineId.hashCode) / Use unique ID per machine (machineId.hashCode)
      await AndroidAlarmManager.oneShot(
        Duration(minutes: newTimer.totalMinutes),
        machineId.hashCode,
        // здесь мы вызываем callback верхнего уровня, определенный в background_notification_service.dart / here we call the top-level callback defined in background_notification_service.dart
        // ВАЖНО: передать функцию без замыкания / IMPORTANT: pass function without closure
        timerFinishedCallback,
        exact: true,
        wakeup: true,
      );

      // Обновление Firebase / Firebase update
      final updatedMachine = Machine(
        id: oldMachine.id,
        nom: oldMachine.nom,
        emplacement: oldMachine.emplacement,
        statut: MachineStatus.occupe,
        tempsRestant: newTimer.remainingMinutes,
        utilisateurActuel: utilisateur,
      );

      _updateMachineLocally(updatedMachine);

      // 🔔 Запланировать напоминание / Schedule reminder
      ReminderService.scheduleReminder(
        machine: updatedMachine,
        notificationProvider: notificationProvider,
        preferencesProvider: preferencesProvider,
      );

      // 🔔 Уведомление о запуске / Startup notification
      _checkForNotifications(oldMachine, updatedMachine, notificationProvider);

      await FirebaseService.updateMachine(machineId, updatedMachine.toMap());

      print('✅ Машина ${updatedMachine.nom} запущена пользователем $utilisateur / Machine ${updatedMachine.nom} started by $utilisateur');
      print('⏰ Таймер создан: ${newTimer.totalMinutes} минут / Timer created: ${newTimer.totalMinutes} minutes');

      notifyListeners();
    } catch (e) {
      _error = 'Ошибка запуска: $e / Startup error: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Освободить машину / Release machine
  Future<void> libererMachine({
    required String machineId,
    required NotificationProvider notificationProvider,
  }) async {
    try {
      final oldMachine = _machines.firstWhere((m) => m.id == machineId);

      // 🗑️ УДАЛИТЬ ЛОКАЛЬНЫЙ ТАЙМЕР / DELETE LOCAL TIMER
      _activeTimers.removeWhere((timer) => timer.machineId == machineId);
      await _saveTimersToStorage();

      // Обновление Firebase / Firebase update
      final updatedMachine = Machine(
        id: oldMachine.id,
        nom: oldMachine.nom,
        emplacement: oldMachine.emplacement,
        statut: MachineStatus.libre,
        tempsRestant: null,
        utilisateurActuel: null,
      );

      _updateMachineLocally(updatedMachine);
      _checkForNotifications(oldMachine, updatedMachine, notificationProvider);
      ReminderService.cancelReminder(machineId);

      await FirebaseService.updateMachine(machineId, updatedMachine.toMap());

      print('✅ Машина ${updatedMachine.nom} освобождена / Machine ${updatedMachine.nom} released');
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка освобождения: $e / Release error: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 🔄 ПРОВЕРЩИК ТАЙМЕРОВ (независимый от пользователя) / TIMER CHECKER (independent of user)
  void _startTimerChecker() {
    _timerChecker = Timer.periodic(Duration(seconds: 10), (timer) {
      bool shouldNotify = false;
      bool shouldSave = false;

      for (int i = 0; i < _activeTimers.length; i++) {
        final machineTimer = _activeTimers[i];
        if (machineTimer.isFinished && machineTimer.isActive) {
          print('🔔 Таймер завершен: ${machineTimer.machineId} / Timer finished: ${machineTimer.machineId}');
          NotificationProvider.instance.addQuickNotification(
            title: "Машина завершила работу / Machine finished",
            message: "Ваше белье готово 🎉 / Your laundry is ready 🎉",
            type: NotificationType.machineFinished,
            context: null, // устанавливаем null / set null
            preferencesProvider: null, // или передать настройки, если они есть / or pass preferences if available
            showAsPush: true, // для принудительного системного уведомления / to force system notification
          );
          // Деактивировать таймер / Deactivate timer
          _activeTimers[i] = MachineTimer(
            machineId: machineTimer.machineId,
            totalMinutes: machineTimer.totalMinutes,
            startTime: machineTimer.startTime,
            isActive: false,
            startedByUser: machineTimer.startedByUser,
          );

          _sendTimerFinishedNotification(machineTimer.machineId);
          shouldNotify = true;
          shouldSave = true;
        }
      }

      // Обновить отображение машин / Update machine display
      if (shouldNotify) {
        _syncTimersWithMachines();
      }

      if (shouldSave) {
        _saveTimersToStorage();
      }
    });
  }

  // 🔔 УВЕДОМЛЕНИЕ о завершении таймера / NOTIFICATION timer finished
  void _sendTimerFinishedNotification(String machineId) {
    final machineIndex = _machines.indexWhere((m) => m.id == machineId);
    if (machineIndex != -1) {
      final machine = _machines[machineIndex];

      print('🎯 Таймер завершен - Машина: ${machine.nom} / Timer finished - Machine: ${machine.nom}');

      // Обновить статус Firebase / Update Firebase status
      final updatedMachine = Machine(
        id: machine.id,
        nom: machine.nom,
        emplacement: machine.emplacement,
        statut: MachineStatus.termine,
        tempsRestant: 0,
        utilisateurActuel: machine.utilisateurActuel,
      );

      _updateMachineLocally(updatedMachine);
      FirebaseService.updateMachine(machineId, updatedMachine.toMap());
    }
  }

  // Локальное обновление / Local update
  void _updateMachineLocally(Machine updatedMachine) {
    final index = _machines.indexWhere((m) => m.id == updatedMachine.id);
    if (index != -1) {
      _machines[index] = updatedMachine;
    }
  }

  // Проверить изменения, требующие уведомлений / Check for changes that require notifications
  void _checkForNotifications(
      Machine oldMachine,
      Machine newMachine,
      NotificationProvider notificationProvider,
      ) {
    if (oldMachine.statut != MachineStatus.termine &&
        newMachine.statut == MachineStatus.termine) {
      _sendMachineFinishedNotification(newMachine, notificationProvider);
    }

    if (oldMachine.statut != MachineStatus.libre &&
        newMachine.statut == MachineStatus.libre) {
      _sendMachineAvailableNotification(newMachine, notificationProvider);
    }

    if (oldMachine.statut != MachineStatus.occupe &&
        newMachine.statut == MachineStatus.occupe) {
      _sendMachineStartedNotification(newMachine, notificationProvider);
    }
  }

  // Уведомления / Notifications
  void _sendMachineFinishedNotification(
      Machine machine,
      NotificationProvider notificationProvider,
      ) {
    final notification = AppNotification(
      id: '${machine.id}_finished_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 Машина готова! / Machine ready!',
      message: 'Ваша ${machine.nom} (${machine.emplacement}) завершила работу / Your ${machine.nom} (${machine.emplacement}) is finished',
      timestamp: DateTime.now(),
      type: NotificationType.machineFinished,
      machineId: machine.id,
      userId: machine.utilisateurActuel,
    );

    notificationProvider.addNotification(notification, context: null);
  }

  void _sendMachineAvailableNotification(
      Machine machine,
      NotificationProvider notificationProvider,
      ) {
    final notification = AppNotification(
      id: '${machine.id}_available_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Машина доступна / Machine available',
      message: '${machine.nom} (${machine.emplacement}) теперь свободна / ${machine.nom} (${machine.emplacement}) is now free',
      timestamp: DateTime.now(),
      type: NotificationType.machineAvailable,
      machineId: machine.id,
    );

    notificationProvider.addNotification(notification, context: null);
  }

  void _sendMachineStartedNotification(
      Machine machine,
      NotificationProvider notificationProvider,
      ) {
    final notification = AppNotification(
      id: '${machine.id}_started_${DateTime.now().millisecondsSinceEpoch}',
      title: '🏁 Машина запущена / Machine started',
      message: '${machine.nom} (${machine.emplacement}) была запущена / ${machine.nom} (${machine.emplacement}) has been started',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      machineId: machine.id,
      userId: machine.utilisateurActuel,
    );

    notificationProvider.addNotification(notification, context: null);
  }

  // Вспомогательный метод: Получить оставшееся время из локального таймера / Utility method: Get remaining time from local timer
  int? getRemainingTime(String machineId) {
    try {
      final timer = _activeTimers.firstWhere(
            (timer) => timer.machineId == machineId && timer.isActive,
      );
      return timer.remainingMinutes;
    } catch (e) {
      return null;
    }
  }

  // Вспомогательный метод: Проверить, есть ли у машины активный таймер / Utility method: Check if machine has active timer
  bool hasActiveTimer(String machineId) {
    return _activeTimers.any(
          (timer) =>
      timer.machineId == machineId && timer.isActive && !timer.isFinished,
    );
  }

  // Вспомогательный метод: Найти машину по ID / Utility method: Find machine by ID
  Machine? getMachineById(String machineId) {
    try {
      return _machines.firstWhere((machine) => machine.id == machineId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _machinesSubscription?.cancel();
    _timerChecker?.cancel();
    ReminderService.cancelAllReminders();
    super.dispose();
  }
}