import 'package:cloud_firestore/cloud_firestore.dart';

class BlogModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
  });

  factory BlogModel.fromMap(String id, Map<String, dynamic> map) {
    return BlogModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}

class BlogCommentModel {
  final String id;
  final String blogId;
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;

  BlogCommentModel({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory BlogCommentModel.fromMap(String id, Map<String, dynamic> map) {
    return BlogCommentModel(
      id: id,
      blogId: map['blogId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blogId': blogId,
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}