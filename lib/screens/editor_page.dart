import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:nanta_mobile/screens/home_page.dart';
import 'profile_page.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  // --- State Variables (equivalent to useState) ---
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _noteOpen = false; // Maps to [noteOpen, setNoteOpen]
  String _currentNoteId = "123"; // Mock ID. Set to "" to test the "Create a new note" UI
  String _currentNoteTitle = "Untitled Note";
  bool _saving = false;

  // --- Timer for Auto-Dismissing Alerts ---
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    // Initialize with mock content or fetch from API here
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }
Future<void> _handleLogout() async {
  try {
    var response = await http.post(
      Uri.http('aedogroupfour-lamp.xyz', '/api/auth/user/logout'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully!')),
      );
    } else {
      debugPrint('Logout failed: ${response.body}');
    }
  } catch (e) {
    debugPrint('Network error during logout: $e');
  } finally {

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(title: 'NANTA')),
      (route) => false,
    );
  }
}
  // --- API Handling (equivalent to handleSave) ---
  Future<void> _handleSave() async {
    if (_currentNoteId.isEmpty) return;

    setState(() => _saving = true);

    // Serialize Delta to JSON
    final contentJson = jsonEncode(_controller.document.toDelta().toJson());

    try {
      // Equivalent to fetch(`/api/notes/${currentNoteId}`, method: 'PUT')
      // Replace 'aedogroupfour-lamp.xyz' with your actual domain
      final response = await http.put(
        Uri.http('aedogroupfour-lamp.xyz', '/api/notes/$_currentNoteId'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          'title': _currentNoteTitle,
          'content': contentJson,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Error saving note: ${response.body}');
      }
    } catch (e) {
      debugPrint('Network error: $e');
    }

    // Equivalent to setTimeout(() => setSaving(false), 1000)
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _saving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- Keyboard Shortcuts (equivalent to useShortcut) ---
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _handleSave(),
        // Add Mac support (Cmd+S)
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => _handleSave(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          // --- Sidebar (equivalent to AppSidebar/SidebarProvider) ---
          drawer: const Drawer(child: Center(child: Text("Sidebar Content"))), 
          
          // --- Header ---
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu), // SidebarTrigger
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Row(
              children: [
                // Separator
                Container(width: 1, height: 16, color: Colors.grey, margin: const EdgeInsets.symmetric(horizontal: 8)),
                Text(_currentNoteTitle, style: const TextStyle(fontSize: 18)),
                const Spacer(),
                // Timer Component
                // const _TimerWidget(), 
              ],
            ),
            actions: [
              IconButton(
                // If saving, show a spinner. If not, show the Save icon.
                icon: _saving 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.save_outlined),
                tooltip: 'Save Note',
                // Disable the button if we are already saving
                onPressed: _saving ? null : _handleSave, 
              ),
        
              // profile button 
              IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: 'Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profilepage()),
                  );
                },
              ),

              // logout button
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Logout',
                onPressed: () { _handleLogout();},
              ),
              const SizedBox(width: 16),
            ],
          ),
          
          // --- Main Content (SidebarInset) ---
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  // Toolbar
                  if (_currentNoteId.isNotEmpty)
                    QuillSimpleToolbar(
                      controller: _controller,
                      config: const QuillSimpleToolbarConfig(
                        showFontFamily: false,
                        showFontSize: false,
                        showAlignmentButtons: false,
                        showIndent: false,
                        showInlineCode: false,
                        showClearFormat: false,
                        showListNumbers: false,
                        showListBullets: false,
                        showListCheck: false,
                        showBackgroundColorButton: false,
                        showColorButton: false,
                        showSuperscript: false,
                        showSubscript: false,
                        showUnderLineButton: false,
                        showUndo: false,
                        showStrikeThrough: false,
                        showCodeBlock: false,
                        showLink: false,
                        showQuote: false,
                        showRedo: false,
                      ),
                    ),
                  
                  // Editor Area
                  Expanded(
                    child: _currentNoteId.isEmpty
                        ? const Center(
                            child: Text(
                              "Create a new note or edit an existing one to start editing.",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: QuillEditor(
                              controller: _controller,
                              focusNode: _focusNode,
                              scrollController: _scrollController,
                              config: const QuillEditorConfig(
                                placeholder: 'Start writing...',
                              ),
                            ),
                          ),
                  ),
                ],
              ),

              // --- Saving Alert (Floating Overlay) ---
              AnimatedOpacity(
                opacity: _saving ? 0.9 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Success! Your changes have been saved", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Now get back to work!", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Mock Timer Widget ---
class _TimerWidget extends StatelessWidget {
  const _TimerWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text("00:00:00", style: TextStyle(fontFamily: 'Monospace')),
    );
  }
}