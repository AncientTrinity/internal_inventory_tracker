import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../models/ticket_comment.dart';
import '../models/ticket_stats.dart';
import '../services/api_service.dart';

class TicketProvider with ChangeNotifier {
  List<Ticket> _tickets = [];
  List<Ticket> _filteredTickets = [];
  Ticket? _selectedTicket;
  List<TicketComment> _comments = [];
  TicketStats? _stats;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = '';
  String _filterType = '';
  String _filterPriority = '';

  List<Ticket> get tickets => _filteredTickets;
  List<Ticket> get allTickets => _tickets;
  Ticket? get selectedTicket => _selectedTicket;
  List<TicketComment> get comments => _comments;
  TicketStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTickets() async {
    _setLoading(true);
    _error = null;

    try {
      // Build query string from filters
      final queryParams = <String>[];
      if (_filterStatus.isNotEmpty) queryParams.add('status=$_filterStatus');
      if (_filterType.isNotEmpty) queryParams.add('type=$_filterType');
      if (_filterPriority.isNotEmpty) queryParams.add('priority=$_filterPriority');
      
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await ApiService.get('/tickets$queryString');
      
      _tickets = (response as List).map((json) => Ticket.fromJson(json)).toList();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tickets: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTicketStats() async {
    try {
      final response = await ApiService.get('/tickets/stats');
      _stats = TicketStats.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load ticket statistics: $e';
    }
  }

  Future<Ticket?> getTicketById(int id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.get('/tickets/$id');
      _selectedTicket = Ticket.fromJson(response);
      await loadComments(id);
      notifyListeners();
      return _selectedTicket;
    } catch (e) {
      _error = 'Failed to load ticket: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadComments(int ticketId) async {
    try {
      final response = await ApiService.get('/tickets/$ticketId/comments');
      _comments = (response as List).map((json) => TicketComment.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load comments: $e';
    }
  }

  Future<bool> createTicket(Ticket ticket) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.post('/tickets', ticket.toJson());
      final newTicket = Ticket.fromJson(response);
      _tickets.insert(0, newTicket);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create ticket: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTicket(Ticket ticket) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.put('/tickets/${ticket.id}', ticket.toJson());
      final updatedTicket = Ticket.fromJson(response);
      
      final index = _tickets.indexWhere((t) => t.id == ticket.id);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
      
      if (_selectedTicket?.id == ticket.id) {
        _selectedTicket = updatedTicket;
      }
      
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update ticket: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTicketStatus(int ticketId, String status, int completion, int? assignedTo) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.post('/tickets/$ticketId/status', {
        'status': status,
        'completion': completion,
        'assigned_to': assignedTo,
      });
      
      await loadTickets(); // Reload to get updated data
      if (_selectedTicket?.id == ticketId) {
        await getTicketById(ticketId); // Reload selected ticket
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to update ticket status: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> reassignTicket(int ticketId, int assignedTo) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.post('/tickets/$ticketId/reassign', {
        'assigned_to': assignedTo,
      });
      
      await loadTickets(); // Reload to get updated data
      if (_selectedTicket?.id == ticketId) {
        await getTicketById(ticketId); // Reload selected ticket
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to reassign ticket: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addComment(int ticketId, String comment, bool isInternal) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.post('/tickets/$ticketId/comments', {
        'comment': comment,
        'is_internal': isInternal,
      });
      
      await loadComments(ticketId); // Reload comments
      return true;
    } catch (e) {
      _error = 'Failed to add comment: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search and filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  void setFilterPriority(String priority) {
    _filterPriority = priority;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterStatus = '';
    _filterType = '';
    _filterPriority = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTickets = _tickets.where((ticket) {
      final matchesSearch = _searchQuery.isEmpty ||
          ticket.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ticket.ticketNum.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ticket.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _filterStatus.isEmpty || ticket.status == _filterStatus;
      final matchesType = _filterType.isEmpty || ticket.type == _filterType;
      final matchesPriority = _filterPriority.isEmpty || ticket.priority == _filterPriority;

      return matchesSearch && matchesStatus && matchesType && matchesPriority;
    }).toList();
  }

  List<Ticket> getTicketsByStatus(String status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  List<Ticket> getTicketsAssignedToUser(int userId) {
    return _tickets.where((ticket) => ticket.assignedTo == userId).toList();
  }

  List<Ticket> getTicketsCreatedByUser(int userId) {
    return _tickets.where((ticket) => ticket.createdBy == userId).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedTicket = null;
    _comments = [];
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}