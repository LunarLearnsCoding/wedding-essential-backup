import 'package:flutter/material.dart';

import '../models/blog_model.dart';
import '../services/blog_service.dart';

class BlogProvider extends ChangeNotifier {
  final BlogService _blogService = BlogService();

  List<BlogModel> _blogs = [];

  List<BlogModel> get blogs => _blogs;

  void loadBlogs() {
    _blogService.getAllBlogs().listen((data) {
      _blogs = data;
      notifyListeners();
    });
  }
}
