import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'alpen_mark.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.showBack = false});
  final Widget child;
  final bool showBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 46, 16, 28),
        child: Column(children: [if (showBack) Align(alignment: Alignment.centerLeft, child: SizedBox(width: 30, height: 30, child: DecoratedBox(decoration: const BoxDecoration(color: alpenBlue, shape: BoxShape.circle), child: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 30, height: 30), icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => Navigator.maybePop(context))))), child]),
      ),
    ),
  );
}

class FormScaffold extends StatelessWidget {
  const FormScaffold({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const BackButton()),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Center(child: AlpenMark()),
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(color: alpenGreen, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Color(0xFF667085), height: 1.45)),
        const SizedBox(height: 26),
        child,
      ]),
    )),
  );
}

class AppField extends StatefulWidget {
  const AppField({super.key, required this.label, required this.controller, this.hint, this.obscure = false, this.maxLines = 1, this.keyboard, this.icon});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboard;
  final IconData? icon;
  @override
  State<AppField> createState() => _AppFieldState();
}
class _AppFieldState extends State<AppField> {
  late bool hidden = widget.obscure;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF282828), fontSize: 16)),
      Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 11), color: alpenBlue),
      TextField(
        controller: widget.controller,
        obscureText: hidden,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        keyboardType: widget.keyboard,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFF767676), fontSize: 14),
          prefixIcon: widget.icon == null ? null : Icon(widget.icon, color: alpenBlue),
          suffixIcon: widget.obscure ? IconButton(icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => hidden = !hidden)) : null,
        ),
      ),
    ]),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.waiting, required this.onTap});
  final String label;
  final bool waiting;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
    onPressed: waiting ? null : onTap,
    style: ElevatedButton.styleFrom(backgroundColor: alpenBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    child: waiting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  ));
}

class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.controller});
  final String label;
  final TextEditingController controller;
  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(context: context, initialDate: DateTime.tryParse(controller.text) ?? now, firstDate: DateTime(1900), lastDate: DateTime(now.year + 10));
    if (selected != null) controller.text = '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
  }
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF282828), fontSize: 16)), Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 11), color: alpenBlue), TextField(controller: controller, readOnly: true, onTap: () => _pick(context), decoration: const InputDecoration(hintText: 'DD/MM/YYYY', suffixIcon: Icon(Icons.calendar_month_outlined, color: alpenBlue))) ]));
}

class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;
  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  final controllers = List.generate(4, (_) => TextEditingController());
  final focusNodes = List.generate(4, (_) => FocusNode());
  void update(int index, String value) {
    if (value.length > 1) controllers[index].text = value.substring(value.length - 1);
    if (controllers[index].text.isNotEmpty && index < 3) focusNodes[index + 1].requestFocus();
    widget.onChanged(controllers.map((item) => item.text).join());
  }
  @override void dispose() { for (final item in controllers) { item.dispose(); } for (final item in focusNodes) { item.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      4,
      (index) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 25),
            decoration: const InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 24),
            ),
            onChanged: (value) => update(index, value),
          ),
        ),
      ),
    ),
  );
}

Future<void> successDialog(BuildContext context, String title, String body, {String actionLabel = 'OK', VoidCallback? onAction}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    icon: const CircleAvatar(radius: 34, backgroundColor: alpenBlue, child: Icon(Icons.check_rounded, color: Colors.white, size: 38)),
    title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
    content: Text(body, textAlign: TextAlign.center),
    actions: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAction ?? () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: alpenBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(actionLabel),
          ),
        ),
      ),
    ],
  ),
);
