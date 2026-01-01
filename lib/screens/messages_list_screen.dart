import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  // Services
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final supabase = Supabase.instance.client;

  // State
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final chats = await _databaseService.getUserChats(user.id);

      // Fetch contact profiles for each chat
      final chatsWithContacts = <Map<String, dynamic>>[];
      for (final chat in chats) {
        try {
          final contactId = chat['renter_id'] == user.id
              ? chat['landlord_id']
              : chat['renter_id'];

          // Fetch contact profile
          final contactProfile = await supabase
              .from('profiles')
              .select('name, profile_image_url')
              .eq('id', contactId)
              .single();

          chatsWithContacts.add({
            ...chat,
            'contact_id': contactId,
            'contact_name': contactProfile['name'] ?? 'Unknown',
            'contact_avatar': contactProfile['profile_image_url'],
          });
        } catch (e) {
          debugPrint("Error fetching contact profile: $e");
          // Add chat without contact info
          chatsWithContacts.add({
            ...chat,
            'contact_id': chat['renter_id'] == user.id
                ? chat['landlord_id']
                : chat['renter_id'],
            'contact_name': 'Unknown',
            'contact_avatar': null,
          });
        }
      }

      if (mounted) {
        setState(() {
          _chats = chatsWithContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading chats: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: mediumGray,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final lastMessage = chat['last_message'] as String? ?? '';
                      final lastMessageAt = chat['last_message_at'] as String?;
                      final contactName = chat['contact_name'] as String? ?? 'Unknown';
                      final contactAvatar = chat['contact_avatar'] as String?;

                      return ChatTile(
                        contactName: contactName,
                        lastMessage: lastMessage,
                        timestamp: _formatTimestamp(lastMessageAt),
                        avatarUrl: contactAvatar,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat['id'] as String,
                                contactName: contactName,
                                contactAvatarUrl: contactAvatar,
                                propertyId: chat['property_id'] as String?,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
