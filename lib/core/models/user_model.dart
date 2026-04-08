// lib/core/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String photoUrl;
  final String bio;
  final String phoneNumber;
  final int? age;
  final bool profileCompleted;
  final List<String> followers;
  final List<String> following;
  final int postsCount;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    this.photoUrl = '',
    this.bio = '',
    this.phoneNumber = '',
    this.age,
    this.profileCompleted = false,
    this.followers = const [],
    this.following = const [],
    this.postsCount = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        username: map['username'] ?? '',
        displayName: map['displayName'] ?? '',
        photoUrl: map['photoUrl'] ?? '',
        bio: map['bio'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        age: map['age'] is int
            ? map['age'] as int
            : (map['age'] is num ? (map['age'] as num).toInt() : null),
        profileCompleted: map['profileCompleted'] ?? false,
        followers: List<String>.from(map['followers'] ?? []),
        following: List<String>.from(map['following'] ?? []),
        postsCount: map['postsCount'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'username': username,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'bio': bio,
        'phoneNumber': phoneNumber,
        'age': age,
        'profileCompleted': profileCompleted,
        'followers': followers,
        'following': following,
        'postsCount': postsCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? phoneNumber,
    int? age,
    bool? profileCompleted,
    List<String>? followers,
    List<String>? following,
    int? postsCount,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        bio: bio ?? this.bio,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        age: age ?? this.age,
        profileCompleted: profileCompleted ?? this.profileCompleted,
        followers: followers ?? this.followers,
        following: following ?? this.following,
        postsCount: postsCount ?? this.postsCount,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [uid, email, username, profileCompleted];
}
