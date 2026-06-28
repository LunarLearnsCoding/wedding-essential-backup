import 'package:flutter/material.dart';

import '../models/service_model.dart';
import '../services/service_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceService _serviceService = ServiceService();

  List<ServiceModel> _services = [];

  List<ServiceModel> get services => _services;

  void loadServices() {
    _serviceService.getAllActiveServices().listen((data) {
      _services = data;
      notifyListeners();
    });
  }
}