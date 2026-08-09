import 'dart:async';
import 'package:flutter/material.dart';

import '../models/service_model.dart';
import '../services/service_service.dart';

/// Stores service state and notifies listening widgets when that state changes.
class ServiceProvider extends ChangeNotifier {
  final ServiceService _serviceService = ServiceService();
  StreamSubscription? _serviceSubscription;

  List<ServiceModel> _services = [];

  List<ServiceModel> get services => _services;

  /// Loads services and updates the visible state.
  void loadServices() {
    _serviceSubscription?.cancel();
    _serviceSubscription = _serviceService.getAllActiveServices().listen((
      data,
    ) {
      _services = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }
}
