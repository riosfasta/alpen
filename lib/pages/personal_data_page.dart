import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../widgets/app_widgets.dart';
import 'family_data_page.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key, required this.user});
  final Map<String, dynamic> user;
  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  late final name = TextEditingController(text: widget.user['name']?.toString() ?? '');
  late final email = TextEditingController(text: widget.user['email']?.toString() ?? '');
  late final employeeNumber = TextEditingController(text: widget.user['username']?.toString() ?? '');
  final phone = TextEditingController(), address = TextEditingController(), birth = TextEditingController(), bank = TextEditingController(), account = TextEditingController(), accountOwner = TextEditingController();
  bool waiting = false;
  String gender = 'Pria', maritalStatus = 'Menikah';

  Future<void> _next() async {
    final required = [name, email, employeeNumber, phone, address, birth, bank, account, accountOwner];
    if (required.any((item) => item.text.trim().isEmpty)) return showMessage(context, 'Lengkapi seluruh data pribadi.');
    setState(() => waiting = true);
    try {
      await MongoService.instance.updateProfile(widget.user['_id'] as ObjectId, {
        'name': name.text.trim(), 'email': email.text.trim().toLowerCase(), 'employeeNumber': employeeNumber.text.trim(),
        'phone': phone.text.trim(), 'address': address.text.trim(), 'birthDate': birth.text.trim(),
        'gender': gender, 'maritalStatus': maritalStatus, 'bankName': bank.text.trim(),
        'accountNumber': account.text.trim(), 'accountOwner': accountOwner.text.trim(),
      });
      if (mounted) pushPage(context, FamilyDataPage(user: widget.user));
    } catch (error) { if (mounted) showMessage(context, friendlyError(error)); }
    finally { if (mounted) setState(() => waiting = false); }
  }

  @override void dispose() { for (final item in [name, email, employeeNumber, phone, address, birth, bank, account, accountOwner]) { item.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => FormScaffold(title: 'Lengkapi Data Diri', subtitle: '', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SectionTitle('Data Pribadi'),
    AppField(label: 'Nama Lengkap', controller: name, hint: 'Masukkan Nama Lengkap Anda'),
    AppField(label: 'Nomor Induk Pegawai', controller: employeeNumber, hint: 'Masukkan Nomor Induk Pegawai Anda', keyboard: TextInputType.number),
    AppField(label: 'Email', controller: email, hint: 'Masukkan Email Aktif Anda', keyboard: TextInputType.emailAddress),
    AppField(label: 'Nomor Handphone', controller: phone, hint: 'Masukkan Nomor yang bisa dihubungi', keyboard: TextInputType.phone),
    AppField(label: 'Alamat Lengkap', controller: address, hint: 'Masukkan Alamat Lengkap Anda', maxLines: 2),
    DateField(label: 'Tanggal Lahir', controller: birth),
    _Choice(label: 'Jenis Kelamin', value: gender, options: const ['Pria', 'Wanita'], onChanged: (value) => setState(() => gender = value)),
    _Choice(label: 'Status Pernikahan', value: maritalStatus, options: const ['Menikah', 'Tidak Menikah'], onChanged: (value) => setState(() => maritalStatus = value)),
    AppField(label: 'Nama Bank', controller: bank, hint: 'Masukkan Nama Bank Anda'),
    AppField(label: 'No Rekening', controller: account, hint: 'Masukkan Nomor Rekening Anda', keyboard: TextInputType.number),
    AppField(label: 'Nama Pemilik Rekening', controller: accountOwner, hint: 'Masukkan Nama Pemilik Rekening Anda'),
    const SizedBox(height: 8), PrimaryButton(label: 'Selanjutnya', waiting: waiting, onTap: _next),
  ]));
}

class _SectionTitle extends StatelessWidget { const _SectionTitle(this.text); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(text, style: const TextStyle(color: alpenGreen, fontSize: 20, fontWeight: FontWeight.w800))); }
class _Choice extends StatelessWidget { const _Choice({required this.label, required this.value, required this.options, required this.onChanged}); final String label, value; final List<String> options; final ValueChanged<String> onChanged; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 6), color: alpenBlue), Wrap(children: options.map((option) => SizedBox(width: 120, child: RadioListTile<String>(contentPadding: EdgeInsets.zero, dense: true, activeColor: alpenBlue, title: Text(option, style: const TextStyle(fontSize: 14)), value: option, groupValue: value, onChanged: (item) { if (item != null) onChanged(item); }))).toList())])); }
