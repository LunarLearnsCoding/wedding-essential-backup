import 'dart:async';
import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Stores booking state and notifies listening widgets when that state changes.
class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  StreamSubscription? _bookingSubscription;
  String? _customerId;

  List<BookingModel> _bookings = [];

  List<BookingModel> get bookings => _bookings;

  /// Applies the requested user change and refreshes state.
  void updateUser(String? customerId) {
    if (_customerId != customerId) {
      _customerId = customerId;
      _loadCustomerBookings();
    }
  }

  /// Loads customer bookings and updates the visible state.
  void _loadCustomerBookings() {
    _bookingSubscription?.cancel();

    if (_customerId == null) {
      _bookings = [];
      notifyListeners();
      return;
    }

    _bookingSubscription = _bookingService
        .getCustomerBookings(_customerId!)
        .listen((data) {
          _bookings = data;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    super.dispose();
  }
}
