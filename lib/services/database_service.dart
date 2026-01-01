import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property.dart';
import '../models/message.dart';
import '../models/user.dart' as models;

// Get the global Supabase client
final supabase = Supabase.instance.client;

class DatabaseService {
  /// Get all properties with ratings
  Future<List<Property>> getProperties({String? searchQuery}) async {
    try {
      late final List<dynamic> data;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Use search function if query provided
        data = await supabase.rpc(
          'search_properties',
          params: {'search_term': searchQuery},
        );
      } else {
        // Fetch all properties from view
        data = await supabase
            .from('properties_with_avg_rating')
            .select('*')
            .order('created_at', ascending: false);
      }

      final properties = data
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint("Fetched ${properties.length} properties");
      return properties;
    } catch (e) {
      debugPrint("Error getting properties: $e");
      return [];
    }
  }

  /// Get property by ID
  Future<Property?> getPropertyById(String id) async {
    try {
      final response = await supabase
          .from('properties_with_avg_rating')
          .select('*')
          .eq('id', id)
          .single();

      return Property.fromJson(response);
    } catch (e) {
      debugPrint("Error getting property by ID: $e");
      return null;
    }
  }

  /// Create a new property
  Future<void> createProperty(Property property) async {
    try {
      final propertyMap = property.toJson();
      // Remove fields that don't exist in the table
      propertyMap.remove('average_rating');
      propertyMap.remove('rating_count');
      // Remove id if empty - database will auto-generate it
      if (propertyMap['id'] == null || propertyMap['id'] == '') {
        propertyMap.remove('id');
      }
      // Remove timestamps - database will set them
      propertyMap.remove('created_at');
      propertyMap.remove('updated_at');

      final newProperty =
          await supabase.from('properties').insert(propertyMap).select().single();
      debugPrint("Property created successfully with ID: ${newProperty['id']}");
    } catch (e) {
      debugPrint("Error creating property: $e");
      rethrow;
    }
  }

  /// Update an existing property
  Future<void> updateProperty(Property property) async {
    try {
      if (property.id.isEmpty) {
        throw Exception("Property ID cannot be empty when updating.");
      }

      final propertyMap = property.toJson();
      // Remove fields that don't exist in the table
      propertyMap.remove('average_rating');
      propertyMap.remove('rating_count');
      propertyMap.remove('id'); // Don't update the ID

      await supabase
          .from('properties')
          .update(propertyMap)
          .eq('id', property.id);
      debugPrint("Property ${property.id} updated successfully!");
    } catch (e) {
      debugPrint("Error updating property: $e");
      rethrow;
    }
  }

  /// Delete a property
  Future<void> deleteProperty(String propertyId) async {
    try {
      await supabase.from('properties').delete().eq('id', propertyId);
      debugPrint("Property $propertyId deleted successfully!");
    } catch (e) {
      debugPrint("Error deleting property: $e");
      rethrow;
    }
  }

  /// Get or create a chat between renter and landlord for a property
  Future<Map<String, dynamic>> getOrCreateChat({
    required String renterId,
    required String landlordId,
    required String propertyId,
  }) async {
    try {
      debugPrint("Getting or creating chat for property: $propertyId");

      // Check if chat already exists
      final existingChat = await supabase
          .from('chats')
          .select('id')
          .eq('property_id', propertyId)
          .or('renter_id.eq.$renterId,landlord_id.eq.$renterId')
          .maybeSingle();

      if (existingChat != null) {
        debugPrint("Chat already exists: ${existingChat['id']}");
        return {
          'chatId': existingChat['id'].toString(),
          'isNewChat': false,
        };
      }

      // Create new chat
      final newChat = await supabase.from('chats').insert({
        'renter_id': renterId,
        'landlord_id': landlordId,
        'property_id': propertyId,
      }).select('id').single();

      debugPrint("Created new chat: ${newChat['id']}");
      return {
        'chatId': newChat['id'].toString(),
        'isNewChat': true,
      };
    } catch (e) {
      debugPrint("Error getting or creating chat: $e");
      rethrow;
    }
  }

  /// Get all chats for a user
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      debugPrint("Getting chats for user: $userId");

      final chats = await supabase
          .from('chats')
          .select('''
            id,
            last_message,
            last_message_at,
            property:properties (name, address, image_urls),
            renter_id,
            landlord_id
          ''')
          .or('renter_id.eq.$userId,landlord_id.eq.$userId')
          .order('last_message_at', ascending: false);

      debugPrint("Fetched ${chats.length} chats");
      return List<Map<String, dynamic>>.from(chats);
    } catch (e) {
      debugPrint("Error getting user chats: $e");
      return [];
    }
  }

  /// Get messages for a specific chat (real-time stream)
  Stream<List<Message>> getChatMessages(String chatId) {
    debugPrint("Setting up message stream for chat: $chatId");

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('sent_at', ascending: true)
        .map((data) {
          debugPrint("Received ${data.length} messages");
          return data.map((msg) => Message.fromJson(msg)).toList();
        });
  }

  /// Send a message in a chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? text,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    try {
      debugPrint("Sending message to chat: $chatId");

      if (text == null && attachmentUrl == null) {
        throw Exception("Message must have either text or an attachment.");
      }

      String lastMessageText = text ?? "Sent an attachment";

      // Create the message
      final messageData = {
        'chat_id': chatId,
        'sender_id': senderId,
        'text': text,
        'sent_at': DateTime.now().toIso8601String(),
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        if (attachmentType != null) 'attachment_type': attachmentType,
      };

      await supabase.from('messages').insert(messageData);

      // Update the chat's last message details
      await supabase.from('chats').update({
        'last_message_at': DateTime.now().toIso8601String(),
        'last_message': lastMessageText,
      }).eq('id', chatId);

      debugPrint("Message sent successfully");
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // First get unread messages
      final unreadMessages = await supabase
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);

      if (unreadMessages.isNotEmpty) {
        // Update all unread messages
        for (final msg in unreadMessages) {
          await supabase
              .from('messages')
              .update({'read_at': DateTime.now().toIso8601String()})
              .eq('id', msg['id']);
        }
      }
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  /// Add or update property rating
  Future<void> addPropertyRating({
    required String propertyId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      await supabase.from('property_ratings').upsert({
        'property_id': propertyId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      }, onConflict: 'user_id,property_id');
      debugPrint(
          "Rating added/updated successfully for property $propertyId by user $userId");
    } catch (e) {
      debugPrint("Error adding/updating rating: $e");
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(models.User user) async {
    try {
      final userMap = user.toJson();
      // Remove non-updatable fields
      userMap.remove('id');
      userMap.remove('created_at');
      userMap.remove('updated_at');

      await supabase
          .from('profiles')
          .update(userMap)
          .eq('id', user.id);
      debugPrint("User profile ${user.id} updated successfully!");
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      rethrow;
    }
  }

  /// Add a property to user's favorites
  Future<void> addFavorite(String userId, String propertyId) async {
    try {
      await supabase.from('favorites').insert({
        'user_id': userId,
        'property_id': propertyId,
      });
      debugPrint("Favorite added successfully for user $userId, property $propertyId");
    } catch (e) {
      debugPrint("Error adding favorite: $e");
      rethrow;
    }
  }

  /// Remove a property from user's favorites
  Future<void> removeFavorite(String userId, String propertyId) async {
    try {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('property_id', propertyId);
      debugPrint("Favorite removed successfully for user $userId, property $propertyId");
    } catch (e) {
      debugPrint("Error removing favorite: $e");
      rethrow;
    }
  }

  /// Check if a property is favorited by a user
  Future<bool> isFavorite(String userId, String propertyId) async {
    try {
      final result = await supabase
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('property_id', propertyId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      debugPrint("Error checking favorite status: $e");
      return false;
    }
  }

  /// Get all favorite properties for a user
  Future<List<Property>> getUserFavorites(String userId) async {
    try {
      // First, fetch favorite property IDs from the favorites table
      final favoritesData = await supabase
          .from('favorites')
          .select('property_id')
          .eq('user_id', userId);

      // Extract property IDs
      final favoriteIds = favoritesData
          .map((item) => item['property_id'] as String)
          .toList();

      // If no favorites, return empty list
      if (favoriteIds.isEmpty) {
        debugPrint("No favorite properties found for user $userId");
        return [];
      }

      // Fetch full property details with ratings from the view
      final data = await supabase
          .from('properties_with_avg_rating')
          .select('*')
          .inFilter('id', favoriteIds);

      // Map the results to Property objects
      final properties = data
          .map((json) => Property.fromJson(json))
          .toList();

      debugPrint("Fetched ${properties.length} favorite properties for user $userId");
      return properties;
    } catch (e) {
      debugPrint("Error getting user favorites: $e");
      return [];
    }
  }
}

