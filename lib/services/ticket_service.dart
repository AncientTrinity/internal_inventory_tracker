// filename: lib/services/ticket_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';
import '../models/ticket_comment.dart';
import '../utils/api_config.dart';

class TicketService {
  
  dynamic _handleResponse(http.Response response) {
    print('🔍 Ticket Response - Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');
    
    if (response.headers['content-type']?.contains('text/plain') == true) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return json.decode(response.body);
        } catch (e) {
          return response.body;
        }
      } else {
        throw Exception(response.body);
      }
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic responseBody = json.decode(response.body);
        
        if (responseBody is List) {
          return responseBody;
        } else if (responseBody is Map) {
          return responseBody['data'] ?? responseBody['ticket'] ?? responseBody;
        } else {
          return responseBody;
        }
      } catch (e) {
        print('❌ JSON decode error: $e');
        throw Exception('Invalid JSON response: ${response.body}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Get all tickets
  Future<List<Ticket>> getTickets(String token) async {
    try {
      print('📡 Fetching tickets');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      List<dynamic> ticketsList;
      
      if (responseData is List) {
        ticketsList = responseData;
      } else if (responseData is Map && responseData.containsKey('tickets')) {
        ticketsList = responseData['tickets'];
      } else {
        ticketsList = [responseData];
      }
      
      print('📦 Parsed ${ticketsList.length} tickets');
      return ticketsList.map<Ticket>((ticket) {
        return Ticket.fromJson(Map<String, dynamic>.from(ticket));
      }).toList();
    } catch (e) {
      print('❌ Failed to load tickets: $e');
      throw Exception('Failed to load tickets: $e');
    }
  }

  // Get ticket by ID
  Future<Ticket> getTicket(int id, String token) async {
    try {
      print('📡 Fetching ticket $id');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$id'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      if (responseData is Map) {
        return Ticket.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to load ticket: $e');
      throw Exception('Failed to load ticket: $e');
    }
  }

  // Create new ticket
  Future<Ticket> createTicket(Ticket ticket, String token) async {
    try {
      print('📡 Creating ticket: ${ticket.title}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(ticket.toJson()),
      );

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Ticket.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Failed to create ticket: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to create ticket: $e');
      throw Exception('Failed to create ticket: $e');
    }
  }

  // Update ticket
  Future<Ticket> updateTicket(Ticket ticket, String token) async {
    try {
      print('📡 Updating ticket ${ticket.id}');
      print('📤 Request Body: ${ticket.toJson()}');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets/${ticket.id}'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(ticket.toJson()),
      );

      print('🔍 Update Response Status: ${response.statusCode}');
      print('🔍 Update Response Body: ${response.body}');

      final responseData = _handleResponse(response);
      
      if (responseData is Map) {
        return Ticket.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to update ticket: $e');
      throw Exception('Failed to update ticket: $e');
    }
  }

  // Update ticket status
  Future<Ticket> updateTicketStatus(int ticketId, String status, double completion, int? assignedTo, String token) async {
    try {
      print('📡 Updating ticket $ticketId status to $status');
      
      // Convert status to lowercase for Go API
      String apiStatus = status.toLowerCase();
      if (apiStatus == 'in_progress') {
        apiStatus = 'in_progress'; // Ensure it matches your Go enum
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/status'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': apiStatus, // Use lowercase for Go API
          'completion': completion,
          'assigned_to': assignedTo,
        }),
      );

      final responseData = _handleResponse(response);
      
      if (responseData is Map) {
        return Ticket.fromJson(Map<String, dynamic>.from(responseData));
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to update ticket status: $e');
      throw Exception('Failed to update ticket status: $e');
    }
  }

  // Delete ticket
  Future<void> deleteTicket(int ticketId, String token) async {
    try {
      print('📡 Deleting ticket $ticketId');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 Delete Response Status: ${response.statusCode}');
      print('🔍 Delete Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Success - parse the response to ensure it worked
        final responseData = json.decode(response.body);
        print('✅ Ticket deleted successfully: $responseData');
        return;
      } else {
        throw Exception('Failed to delete ticket: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to delete ticket: $e');
      throw Exception('Failed to delete ticket: $e');
    }
  }

Future<Ticket> reassignTicket(int ticketId, int? assigneeId, String token) async {
  try {
    print('📡 Reassigning ticket $ticketId to user $assigneeId');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/reassign'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'assigned_to': assigneeId,
      }),
    );

    final responseData = _handleResponse(response);
    
    if (responseData is Map) {
      return Ticket.fromJson(Map<String, dynamic>.from(responseData));
    } else {
      throw Exception('Unexpected response format: $responseData');
    }
  } catch (e) {
    print('❌ Failed to reassign ticket: $e');
    throw Exception('Failed to reassign ticket: $e');
  }
}

  // Get ticket comments
  Future<List<TicketComment>> getComments(int ticketId, String token) async {
    try {
      print('📡 Fetching comments for ticket $ticketId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/comments'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      // Handle null response
      if (responseData == null) {
        print('📦 No comments found, returning empty list');
        return [];
      }
      
      List<dynamic> commentsList;
      
      if (responseData is List) {
        commentsList = responseData;
      } else if (responseData is Map && responseData.containsKey('comments')) {
        commentsList = responseData['comments'];
      } else {
        commentsList = [responseData];
      }
      
      print('📦 Parsed ${commentsList.length} comments');
      
      // Safely parse comments, skip any that fail
      final List<TicketComment> comments = [];
      for (final commentData in commentsList) {
        try {
          if (commentData is Map<String, dynamic>) {
            comments.add(TicketComment.fromJson(commentData));
          } else if (commentData is Map) {
            comments.add(TicketComment.fromJson(Map<String, dynamic>.from(commentData)));
          }
        } catch (e) {
          print('⚠️ Failed to parse comment: $e, data: $commentData');
          // Skip invalid comments but continue processing others
        }
      }
      
      return comments;
    } catch (e) {
      print('❌ Failed to load comments: $e');
      // Return empty list instead of throwing for empty comments
      return [];
    }
  }

  // Create comment
  Future<TicketComment> createComment(TicketComment comment, String token) async {
    try {
      print('📡 Creating comment for ticket ${comment.ticketId}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets/${comment.ticketId}/comments'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(comment.toJson()),
      );

      final responseData = _handleResponse(response);
      
      if (responseData is Map) {
        // Map the API response fields to your model
        final mappedData = Map<String, dynamic>.from(responseData);
        return TicketComment(
          id: mappedData['id'] ?? 0,
          ticketId: mappedData['ticket_id'] ?? comment.ticketId,
          userId: mappedData['author_id'] ?? comment.userId, // API uses 'author_id'
          comment: mappedData['comment'] ?? '',
          isInternal: mappedData['is_internal'] ?? false,
          createdAt: DateTime.parse(mappedData['created_at']),
          userName: comment.userName, // Keep original user info
          userEmail: comment.userEmail,
        );
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to create comment: $e');
      throw Exception('Failed to create comment: $e');
    }
  }


// Set up verification for a ticket (change from not_required to pending)

Future<Ticket> setupVerification(int ticketId, String token) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/setup-verification'),
    headers: {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return Ticket.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to setup verification: ${response.statusCode}');
  }
}

Future<Ticket> resetVerification(int ticketId, String token) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/reset-verification'),
    headers: {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return Ticket.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to reset verification: ${response.statusCode}');
  }
}

Future<Ticket> requestVerification(int ticketId, String notes, String token) async {
  try {
    print('📡 Requesting verification for ticket $ticketId');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/request-verification'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'notes': notes,
      }),
    );

    final responseData = _handleResponse(response);
    
    if (responseData is Map) {
      return Ticket.fromJson(Map<String, dynamic>.from(responseData));
    } else {
      throw Exception('Unexpected response format: $responseData');
    }
  } catch (e) {
    print('❌ Failed to request verification: $e');
    throw Exception('Failed to request verification: $e');
  }
}

// Verify or reject a ticket (only works when status is pending)
Future<Ticket> verifyTicket(int ticketId, bool approved, String notes, String token) async {
  try {
    print('📡 ${approved ? 'Verifying' : 'Rejecting'} ticket $ticketId');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/verify'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'approved': approved,
        'notes': notes,
      }),
    );

    final responseData = _handleResponse(response);
    
    if (responseData is Map) {
      return Ticket.fromJson(Map<String, dynamic>.from(responseData));
    } else {
      throw Exception('Unexpected response format: $responseData');
    }
  } catch (e) {
    print('❌ Failed to verify ticket: $e');
    throw Exception('Failed to verify ticket: $e');
  }
}


// Update ticket verification status
Future<Ticket> updateTicketVerification(int ticketId, String verificationStatus, String verificationNotes, String token) async {
  try {
    print('📡 Updating ticket $ticketId verification to $verificationStatus');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/verify'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'verification_status': verificationStatus,
        'verification_notes': verificationNotes,
      }),
    );

    final responseData = _handleResponse(response);
    
    if (responseData is Map) {
      return Ticket.fromJson(Map<String, dynamic>.from(responseData));
    } else {
      throw Exception('Unexpected response format: $responseData');
    }
  } catch (e) {
    print('❌ Failed to update ticket verification: $e');
    throw Exception('Failed to update ticket verification: $e');
  }
}

// Close verified ticket
Future<Ticket> closeVerifiedTicket(int ticketId, String token) async {
  try {
    print('📡 Closing verified ticket $ticketId');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/tickets/$ticketId/close'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = _handleResponse(response);
    
    if (responseData is Map) {
      return Ticket.fromJson(Map<String, dynamic>.from(responseData));
    } else {
      throw Exception('Unexpected response format: $responseData');
    }
  } catch (e) {
    print('❌ Failed to close verified ticket: $e');
    throw Exception('Failed to close verified ticket: $e');
  }
}

  // Get ticket statistics
  Future<Map<String, dynamic>> getTicketStats(String token) async {
    try {
      print('📡 Fetching ticket statistics');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/tickets/stats'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = _handleResponse(response);
      
      if (responseData is Map) {
        return Map<String, dynamic>.from(responseData);
      } else {
        throw Exception('Unexpected response format: $responseData');
      }
    } catch (e) {
      print('❌ Failed to load ticket stats: $e');
      throw Exception('Failed to load ticket stats: $e');
    }
  }
}