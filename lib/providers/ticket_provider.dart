// filename: lib/providers/ticket_provider.dart
import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../models/ticket_comment.dart'; // ADD THIS IMPORT
import '../services/ticket_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();
  
  List<Ticket> _tickets = [];
  Ticket? _selectedTicket;
  List<TicketComment> _selectedTicketComments = [];
  bool _isLoading = false;
  String? _error;

  List<Ticket> get tickets => _tickets;
  Ticket? get selectedTicket => _selectedTicket;
  List<TicketComment> get selectedTicketComments => _selectedTicketComments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper method to safely notify listeners
  void _safeNotifyListeners() {
    if (!_isLoading) {
      Future.microtask(() => notifyListeners());
    }
  }

  // Load all tickets
  Future<void> loadTickets(String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _tickets = await _ticketService.getTickets(token);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading tickets: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Load ticket by ID
  Future<void> loadTicketById(int ticketId, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _selectedTicket = await _ticketService.getTicket(ticketId, token);
      await loadComments(ticketId, token);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading ticket $ticketId: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Load comments for selected ticket
  Future<void> loadComments(int ticketId, String token) async {
    try {
      _selectedTicketComments = await _ticketService.getComments(ticketId, token);
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading comments: $e');
    }
  }

  // Create new ticket
  Future<void> createTicket(Ticket ticket, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final newTicket = await _ticketService.createTicket(ticket, token);
      _tickets.insert(0, newTicket);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Update ticket
  Future<void> updateTicket(Ticket ticket, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final updatedTicket = await _ticketService.updateTicket(ticket, token);
      final index = _tickets.indexWhere((t) => t.id == ticket.id);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
      if (_selectedTicket?.id == ticket.id) {
        _selectedTicket = updatedTicket;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Update ticket status
  Future<void> updateTicketStatus(int ticketId, String status, double completion, int? assignedTo, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final updatedTicket = await _ticketService.updateTicketStatus(ticketId, status, completion, assignedTo, token);
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = updatedTicket;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Delete ticket
  Future<void> deleteTicket(int ticketId, String token) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _ticketService.deleteTicket(ticketId, token);
      _tickets.removeWhere((ticket) => ticket.id == ticketId);
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = null;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }



  final UserService _userService = UserService();
List<User> _availableUsers = [];

List<User> get availableUsers => _availableUsers;

// Load available users for assignment
Future<void> loadAvailableUsers(String token) async {
  try {
    _availableUsers = await _userService.getITStaff(token);
    _safeNotifyListeners();
  } catch (e) {
    _error = e.toString();
    print('❌ Error loading available users: $e');
  }
}

// Reassign single ticket
Future<void> reassignTicket(int ticketId, int? assigneeId, String token) async {
  if (_isLoading) return;
  
  _isLoading = true;
  _error = null;
  _safeNotifyListeners();

  try {
    final updatedTicket = await _ticketService.reassignTicket(ticketId, assigneeId, token);
    
    // Update in tickets list
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = updatedTicket;
    }
    
    // Update selected ticket if it's the same
    if (_selectedTicket?.id == ticketId) {
      _selectedTicket = updatedTicket;
    }
    
    _error = null;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}

// Bulk reassign tickets
Future<void> bulkReassignTickets(List<int> ticketIds, int? assigneeId, String token) async {
  if (_isLoading) return;
  
  _isLoading = true;
  _error = null;
  _safeNotifyListeners();

  try {
    for (final ticketId in ticketIds) {
      await _ticketService.reassignTicket(ticketId, assigneeId, token);
    }
    
    // Refresh tickets to get updated data
    await loadTickets(token);
    
    _error = null;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}

  // Create comment
  Future<void> createComment(TicketComment comment, String token) async {
    try {
      final newComment = await _ticketService.createComment(comment, token);
      _selectedTicketComments.add(newComment);
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> setupTicketVerification(int ticketId, String token) async {
  if (_isLoading) return;

  _isLoading = true;
  _error = null;
  _safeNotifyListeners();

  try {
    final updatedTicket = await _ticketService.setupVerification(ticketId, token);

    // Update in tickets list
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = updatedTicket;
    }

    // Update selected ticket if it's the same
    if (_selectedTicket?.id == ticketId) {
      _selectedTicket = updatedTicket;
    }

    _error = null;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}

// Request verification for a ticket
  Future<void> requestVerification(int ticketId, String notes, String token) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final updatedTicket = await _ticketService.requestVerification(ticketId, notes, token);

      // Update in tickets list
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }

      // Update selected ticket if it's the same
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = updatedTicket;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

// Verify or reject a ticket
  Future<void> verifyTicket(int ticketId, bool approved, String notes, String token) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final updatedTicket = await _ticketService.verifyTicket(ticketId, approved, notes, token);

      // Update in tickets list
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }

      // Update selected ticket if it's the same
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = updatedTicket;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
// Update ticket verification
  Future<void> updateTicketVerification(int ticketId, String verificationStatus, String verificationNotes, String token) async {
  if (_isLoading) return;
  
  _isLoading = true;
  _error = null;
  _safeNotifyListeners();

  try {
    final updatedTicket = await _ticketService.updateTicketVerification(
      ticketId, 
      verificationStatus, 
      verificationNotes, 
      token
    );
    
    // Update in tickets list
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = updatedTicket;
    }
    
    // Update selected ticket if it's the same
    if (_selectedTicket?.id == ticketId) {
      _selectedTicket = updatedTicket;
    }
    
    _error = null;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}

// Close verified ticket
Future<void> closeVerifiedTicket(int ticketId, String token) async {
  if (_isLoading) return;
  
  _isLoading = true;
  _error = null;
  _safeNotifyListeners();

  try {
    final updatedTicket = await _ticketService.closeVerifiedTicket(ticketId, token);
    
    // Update in tickets list
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = updatedTicket;
    }
    
    // Update selected ticket if it's the same
    if (_selectedTicket?.id == ticketId) {
      _selectedTicket = updatedTicket;
    }
    
    _error = null;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}

Future<void> resetVerification(int ticketId, String token) async {
  if (_isLoading) return;

  _isLoading = true;
  _error = null;
  _safeNotifyListeners();

  try {
    final updatedTicket = await _ticketService.resetVerification(ticketId, token);

    // Update in tickets list
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = updatedTicket;
    }

    // Update selected ticket if it's the same
    if (_selectedTicket?.id == ticketId) {
      _selectedTicket = updatedTicket;
    }

    _error = null;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    _safeNotifyListeners();
  }
}

  // Get ticket statistics
  Future<Map<String, dynamic>> getTicketStats(String token) async {
    try {
      return await _ticketService.getTicketStats(token);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Ticket analytics
  Map<String, dynamic> getTicketAnalytics() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentTickets = _tickets.where((ticket) => 
      ticket.createdAt.isAfter(thirtyDaysAgo)
    ).toList();
    
    final resolvedTickets = recentTickets.where((ticket) => 
      ticket.isResolved || ticket.isClosed
    ).toList();
    
    final avgResolutionTime = _calculateAverageResolutionTime(resolvedTickets);
    
    return {
      'total_tickets': _tickets.length,
      'recent_tickets': recentTickets.length,
      'resolution_rate': recentTickets.isEmpty ? 0 : (resolvedTickets.length / recentTickets.length) * 100,
      'avg_resolution_time': avgResolutionTime,
      'priority_distribution': _getPriorityDistribution(),
      'status_distribution': _getStatusDistribution(),
    };
  }

  double _calculateAverageResolutionTime(List<Ticket> resolvedTickets) {
    if (resolvedTickets.isEmpty) return 0;
    
    final totalHours = resolvedTickets.fold(0.0, (sum, ticket) {
      final resolutionTime = ticket.updatedAt.difference(ticket.createdAt);
      return sum + resolutionTime.inHours.toDouble();
    });
    
    return totalHours / resolvedTickets.length;
  }

  Map<String, int> _getPriorityDistribution() {
    final distribution = <String, int>{};
    for (final ticket in _tickets) {
      distribution.update(
        ticket.priority,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return distribution;
  }

  Map<String, int> _getStatusDistribution() {
    final distribution = <String, int>{};
    for (final ticket in _tickets) {
      distribution.update(
        ticket.status,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return distribution;
  }

  // Filter tickets by status
  List<Ticket> getTicketsByStatus(String status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  // Filter tickets by priority
  List<Ticket> getTicketsByPriority(String priority) {
    return _tickets.where((ticket) => ticket.priority == priority).toList();
  }

  // Search tickets
  List<Ticket> searchTickets(String query) {
    if (query.isEmpty) return _tickets;
    
    final lowerQuery = query.toLowerCase();
    return _tickets.where((ticket) {
      return ticket.title.toLowerCase().contains(lowerQuery) ||
             ticket.description.toLowerCase().contains(lowerQuery) ||
             ticket.typeDisplay.toLowerCase().contains(lowerQuery) ||
             (ticket.assignedToName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected ticket
  void clearSelectedTicket() {
    _selectedTicket = null;
    _selectedTicketComments = [];
    notifyListeners();
  }
}