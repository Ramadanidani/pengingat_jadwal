import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../utils/storage_helper.dart';
import 'add_reminder_page.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notifPlugin;
  HomePage({required this.notifPlugin});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Map<String, dynamic>> reminders = [];
  String _userName = '';
  Set<String> _shownAlerts = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await loadReminders(); // Tunggu dulu reminders selesai dimuat
      _startScheduleChecker();
    });
    loadUserName();
  }


  void dispose() {
    _timer?.cancel(); // Hentikan timer saat halaman dibuang
    super.dispose();
  }

  Future<void> loadUserName() async {
    final name = await StorageHelper.getUserName();
    setState(() {
      _userName = name ?? '';
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playAlarmSound() async {
    await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
  }

  Future<void> loadReminders() async {
    reminders = await StorageHelper.loadReminders();
    setState(() {});
  }

  Future<void> saveReminders() async {
    await StorageHelper.saveReminders(reminders);
  }

  void addReminder(String title, String description, String time) {
    setState(() {
      reminders.add({'title': title, 'description': description, 'time': time});
      saveReminders();
      scheduleNotification(title, time);
    });
  }

  void deleteReminder(int index) {
    setState(() {
      reminders.removeAt(index);
      saveReminders();
    });
  }

  void _startScheduleChecker() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      final now = DateTime.now();

      for (var reminder in reminders) {
        final title = reminder['title'] ?? '';
        final timeStr = reminder['time'] ?? '';
        if (!_shownAlerts.contains(title)) {
          try {
            final reminderTime = DateTime.parse(timeStr);
            if (_isSameMinute(now, reminderTime)) {
              _shownAlerts.add(title); // Gunakan title sebagai ID unik
              _showAlert(title);
            }
          } catch (e) {
            // ignore format error
          }
        }
      }
    });
  }

  bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  void _showAlert(String title) async {
    await _playAlarmSound(); // Putar alarm

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Pengingat Jadwal"),
        content: Text("Saatnya untuk: $title"),
        actions: [
          TextButton(
            onPressed: () {
              _audioPlayer.stop(); // Stop suara saat user tekan OK
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> scheduleNotification(String title, String time) async {
    final scheduledTime = tz.TZDateTime.parse(tz.local, time);

    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Pengingat Jadwal',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await widget.notifPlugin.zonedSchedule(
      0,
      'Pengingat Jadwal',
      'Waktunya $title!',
      scheduledTime,
      platformDetails,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  String formatDateTime(String dateTime) {
    try {
      final DateTime parsedDate = DateTime.parse(dateTime);
      final DateFormat formatter = DateFormat('d MMMM yyyy, HH:mm');
      return formatter.format(parsedDate);
    } catch (e) {
      return 'Waktu tidak valid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Image.asset(
                    'assets/PJ.png',
                    height: 50,
                    width: 50,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Daftar Pengingat',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 100, // mengatur height menu
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              color: Theme.of(context).colorScheme.primary,
              alignment: Alignment.centerLeft,
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return SwitchListTile(
                        title: Text("Mode Gelap"),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                        secondary: Icon(Icons.brightness_6),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10),
            child: Text(
              'Hello, $_userName',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.blue[200]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'Siap Memulai Hari Mu ?',
              style: theme.textTheme.bodySmall,
            ),
          ),
          ...reminders.asMap().entries.map((entry) {
            final index = entry.key;
            final reminder = entry.value;
            return Card(
              color: theme.cardColor,
              elevation: 5,
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text(
                  reminder['title'] ?? 'Tanpa Judul',
                  style: theme.textTheme.bodyLarge,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder['description'] ?? 'Tanpa Deskripsi',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      formatDateTime(reminder['time'] ?? ''),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddReminderPage(
                        oldTitle: reminder['title'],
                        oldDescription: reminder['description'],
                        oldTime: reminder['time'],
                      ),
                    ),
                  );
                  if (result != null && result is Map<String, String>) {
                    setState(() {
                      reminders[index] = {
                        'title': result['title']!,
                        'description': result['description']!,
                        'time': result['time']!,
                      };
                      saveReminders();
                    });
                  }
                },
                trailing: IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: theme.dialogBackgroundColor,
                        title: Text('Hapus Pengingat'),
                        content: Text('Yakin ingin menghapus pengingat ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteReminder(index);
                              Navigator.pop(context);
                            },
                            child: Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReminderPage()),
          );
          if (result != null && result is Map<String, String>) {
            addReminder(result['title']!, result['description']!, result['time']!);
          }
        },
        child: Icon(Icons.add),
        backgroundColor: theme.floatingActionButtonTheme.backgroundColor ?? Colors.deepPurple,
      ),
    );
  }
}
