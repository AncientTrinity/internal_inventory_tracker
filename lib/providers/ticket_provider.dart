// filename: lib/providers/ticket_provider.dart
import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

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

  // Load all tickets
  Future<void> loadTickets(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _ticketService.getTickets(token);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load ticket by ID
  Future<void> loadTicketById(int ticketId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTicket = await _ticketService.getTicket(ticketId, token);
      await loadComments(ticketId, token);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new ticket
  Future<void> createTicket(Ticket ticket, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTicket = await _ticketService.createTicket(ticket, token);
      _tickets.insert(0, newTicket);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update ticket
  Future<void> updateTicket(Ticket ticket, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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
      notifyListeners();
    }
  }

  // Update ticket status
  Future<void> updateTicketStatus(int ticketId, String status, double completion, int? assignedTo, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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
      notifyListeners();
    }
  }

  // Delete ticket
  Future<void> deleteTicket(int ticketId, String token) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    await _ticketService.deleteTicket(ticketId, token); // FIXED: Changed from deleteServiceLog to deleteTicket
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
    notifyListeners();
  }
}

  // Load comments for selected ticket
  Future<void> loadComments(int ticketId, String token) async {
    try {
      _selectedTicketComments = await _ticketService.getComments(ticketId, token);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // Create comment
  Future<void> createComment(TicketComment comment, String token) async {
    try {
      final newComment = await _ticketService.createComment(comment, token);
      _selectedTicketComments.add(newComment);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
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