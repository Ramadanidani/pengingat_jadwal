import 'package:flutter/material.dart';

class AddReminderPage extends StatefulWidget {
  final String? oldTitle;
  final String? oldDescription;
  final String? oldTime; // Menambahkan oldTime untuk menyimpan waktu yang sudah ada

  const AddReminderPage({this.oldTitle, this.oldDescription, this.oldTime, super.key});

  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.oldTitle ?? '';
    _descriptionController.text = widget.oldDescription ?? '';

    // Inisialisasi waktu jika ada
    if (widget.oldTime != null) {
      DateTime oldDateTime = DateTime.parse(widget.oldTime!);
      _selectedDate = oldDateTime;
      _selectedTime = TimeOfDay(hour: oldDateTime.hour, minute: oldDateTime.minute);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _simpanData() {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi semua field!')),
      );
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    Navigator.pop(context, {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'time': combinedDateTime.toIso8601String(), // Menggunakan format ISO
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.oldTitle == null ? 'Tambah Pengingat' : 'Edit Pengingat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Deskripsi'),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedDate == null
                      ? 'Tanggal belum dipilih'
                      : 'Tanggal: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),

                ),
                ElevatedButton(
                  onPressed: _pickDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Pilih Tanggal'),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedTime == null
                      ? 'Waktu belum dipilih'
                      : 'Waktu: ${_selectedTime!.format(context)}'),
                ),
                ElevatedButton(
                  onPressed: _pickTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white
                  ),
                  child: Text('Pilih Waktu'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _simpanData,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white
              ),
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
