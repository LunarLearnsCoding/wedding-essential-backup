import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];

  List<BookingModel> get bookings => _bookings;

  void loadCustomerBookings(String customerId) {
    _bookingService
        .getCustomerBookings(customerId)
        .listen((data) {
      _bookings = data;
      notifyListeners();
    });
  }
}