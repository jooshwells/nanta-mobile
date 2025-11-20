import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanta_mobile/screens/home_page.dart';
import 'profile_page.dart';

class NoteEditorPage extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  final dynamic initialContent;

  const NoteEditorPage({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String? _currentNoteId;
  
  // UI State
  bool _isSaving = false;        
  bool _showSuccess = false;     
  Timer? _successTimer;

  List<dynamic> _sidebarNotes = [];
  final String _baseUrl = 'aedogroupfour-lamp.xyz'; // Extracted for reuse

  @override
  void initState() {
    super.initState();
    _currentNoteId = widget.noteId;
    _titleController.text = widget.initialTitle ?? "Untitled Note";

    _loadContent();
    _fetchNotes();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  // --- Initialization Helpers ---

  void _loadContent() {
    if (widget.initialContent != null) {
      try {
        var contentJSON = widget.initialContent;
        if (contentJSON is String) {
          contentJSON = jsonDecode(contentJSON);
        }
        _controller = QuillController(
          document: Document.fromJson(contentJSON),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        debugPrint("Error parsing note content: $e");
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // --- CRUD Operations (Matching Web Implementation) ---

  Future<void> _fetchNotes() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.https(_baseUrl, '/api/notes/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notes = data['notes'];

        if (mounted) {
          setState(() {
            if (notes.isNotEmpty) {
              _sidebarNotes = notes;
            } else {
              _sidebarNotes = [
                {'title': "No notes created", '_id': "#", 'content': "{}"}
              ];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Network error fetching notes: $e');
    }
  }

  // Emulates createNote from web
  Future<void> _createNote(String title) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      await http.post(
        Uri.https(_baseUrl, '/api/notes/create'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'title': title,
          // Web implementation sends empty ops structure
          'content': jsonEncode({'ops': []}), 
        }),
      );
      await _fetchNotes(); // Refresh list
    } catch (e) {
      debugPrint('Error creating note: $e');
    }
  }

  // Emulates handleRenameNote from web
  Future<void> _renameNote(String id, String newTitle, dynamic content) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      await http.put(
        Uri.https(_baseUrl, '/api/notes/$id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'title': newTitle,
          'content': content, // Pass existing content
        }),
      );
      await _fetchNotes();
      
      // If we renamed the currently open note, update the title in the AppBar
      if (id == _currentNoteId) {
        setState(() {
          _titleController.text = newTitle;
        });
      }
    } catch (e) {
      debugPrint('Error renaming note: $e');
    }
  }

  // Emulates handleDeleteNote from web
  Future<void> _deleteNote(String id) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      // Optimistic UI update (optional, but matches web logic of filtering first)
      setState(() {
        _sidebarNotes.removeWhere((note) => note['_id'] == id);
      });

      await http.delete(
        Uri.https(_baseUrl, '/api/notes/$id'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (_currentNoteId == id) {
        setState(() {
          _currentNoteId = null;
          _titleController.text = "Untitled Note";
          _controller.clear();
        });
      }
      
      await _fetchNotes(); // Final refresh
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final token = await _getToken();
    if (token == null) {
      setState(() => _isSaving = false);
      return;
    }

    final contentJson = jsonEncode(_controller.document.toDelta().toJson());
    final String title = _titleController.text.isEmpty
        ? "Untitled Note"
        : _titleController.text;

    try {
      http.Response response;

      if (_currentNoteId == null) {
        response = await http.post(
          Uri.https(_baseUrl, '/api/notes/create'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode({
            'title': title,
            'content': contentJson,
          }),
        );
      } else {
        response = await http.put(
          Uri.https(_baseUrl, '/api/notes/$_currentNoteId'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode({
            'title': title,
            'content': contentJson,
          }),
        );
      }

      if (response.statusCode == 200) {
        _triggerSuccessAlert();
        await _fetchNotes();

        // If created, grab the ID of the newest note (index 0)
        if (_currentNoteId == null && _sidebarNotes.isNotEmpty) {
           final newestNote = _sidebarNotes[0];
           if (newestNote['_id'] != "#") {
             setState(() {
               _currentNoteId = newestNote['_id'];
             });
           }
        }
      } 
    } catch (e) {
      debugPrint('Network error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _triggerSuccessAlert() {
    if (mounted) setState(() => _showSuccess = true);
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  Future<void> _handleLogout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await http.post(
          Uri.https(_baseUrl, '/api/auth/logout'),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
    } catch (e) {
      debugPrint('Logout Error: $e');
    } finally {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage(title: 'NANTA')),
        (route) => false,
      );
    }
  }

  // --- Dialogs ---

  Future<void> _showCreateNoteDialog() async {
    String newTitle = "Note Title";
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create new note'),
          content: TextField(
            onChanged: (value) => newTitle = value,
            decoration: const InputDecoration(hintText: "Choose the title"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createNote(newTitle);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(String id, String currentTitle, dynamic content) async {
    String updatedTitle = currentTitle;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Note'),
          content: TextField(
            controller: TextEditingController(text: currentTitle),
            onChanged: (value) => updatedTitle = value,
            decoration: const InputDecoration(hintText: "Enter new title"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _renameNote(id, updatedTitle, content);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- UI Construction ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _handleSave(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => _handleSave(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          // --- Functional Sidebar matching Web ---
          drawer: Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: const Text(
                    "My Notes",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: null,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color.fromARGB(255, 20, 71, 230)
                        : const Color.fromARGB(255, 171, 199, 240),
                  ),
                ),
                Expanded(
                  child: _sidebarNotes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _sidebarNotes.length,
                          itemBuilder: (context, index) {
                            final note = _sidebarNotes[index];
                            final isPlaceholder = note['_id'] == "#";
                            final isActive = note['_id'] == _currentNoteId;

                            return ListTile(
                              selected: isActive,
                              selectedTileColor: isDark ? Colors.white10 : Colors.grey.shade200,
                              leading: Icon(
                                isPlaceholder
                                    ? Icons.info_outline
                                    : Icons.article_outlined,
                              ),
                              title: Text(
                                note['title'] ?? "Untitled",
                                style: TextStyle(
                                  color: isPlaceholder ? Colors.grey : null,
                                  fontStyle: isPlaceholder ? FontStyle.italic : null,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              // Edit and Delete Actions
                              trailing: isPlaceholder
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _showRenameDialog(
                                              note['_id'], note['title'], note['content']),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          onPressed: () => _deleteNote(note['_id']),
                                        ),
                                      ],
                                    ),
                              onTap: isPlaceholder
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      // Load Note logic without page replacement for smoother feel
                                      setState(() {
                                        _currentNoteId = note['_id'];
                                        _titleController.text = note['title'];
                                      });
                                      // Re-parse content
                                      if (note['content'] != null) {
                                         try {
                                            var contentJSON = note['content'];
                                            if (contentJSON is String) {
                                              contentJSON = jsonDecode(contentJSON);
                                            }
                                            _controller.document = Document.fromJson(contentJSON);
                                         } catch (e) {
                                            _controller.document = Document();
                                         }
                                      }
                                    },
                            );
                          },
                        ),
                ),
                const Divider(),
                // "New Note" button at bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Create New Note"),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateNoteDialog();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            title: TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
            actions: [
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                tooltip: 'Save Note',
                onPressed: _isSaving ? null : _handleSave,
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
                onPressed: _handleLogout,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  QuillSimpleToolbar(
                    controller: _controller,
                    config: const QuillSimpleToolbarConfig(
                      showFontFamily: false,
                      showFontSize: false,
                      showSearchButton: false,
                      showInlineCode: false,
                      showSubscript: false,
                      showSuperscript: false,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: QuillEditor.basic(
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
              AnimatedOpacity(
                opacity: _showSuccess ? 1.0 : 0.0, 
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        "Saved!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
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