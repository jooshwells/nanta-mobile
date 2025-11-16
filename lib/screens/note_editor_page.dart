import 'package:flutter/material.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key});
  @override
  State<NoteEditorPage> createState() => _NoteEditorPage();
}

class _NoteEditorPage extends State<NoteEditorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notes Editor")),
      body: Center(
        child: Text(
          "This is the Note Editor page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
