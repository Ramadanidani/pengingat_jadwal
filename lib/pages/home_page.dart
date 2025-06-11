import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../utils/storage_helper.dart';
import 'add_reminder_page.dart';
import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notifPlugin;
  HomePage({required this.notifPlugin});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> reminders = [];
  String _userName = '';

  @override
  void initState() {
    super.initState();
    loadReminders();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final name = await StorageHelper.getUserName();
    setState(() {
      _userName = name ?? '';
    });
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
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Colors.black,
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: Colors.white),
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
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              'Hello, $_userName',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[200],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Siap Memulai Hari Mu ?',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
          ...reminders.asMap().entries.map((entry) {
            final index = entry.key;
            final reminder = entry.value;
            return Card(
              color: Colors.grey[850],
              elevation: 5,
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text(
                  reminder['title'] ?? 'Tanpa Judul',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder['description'] ?? 'Tanpa Deskripsi',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      formatDateTime(reminder['time'] ?? ''),
                      style: TextStyle(color: Colors.white70),
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
                        backgroundColor: Colors.blue[200],
                        title: Text(
                          'Hapus Pengingat',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Yakin ingin menghapus pengingat ini?',
                          style: TextStyle(color: Colors.white70),
                        ),
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
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
