import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfo {
  final String name;
  final String? avatar;
  final String? country;
  final DateTime? memberSince;

  const UserInfo({
    required this.name,
    this.avatar,
    this.country,
    this.memberSince,
  });

  factory UserInfo.fromFirestore(Map<String, dynamic> data) {
    return UserInfo(
      name: data['name'] as String,
      avatar: data['avatar'] as String?,
      country: data['country'] as String?,
      memberSince: data['memberSince'] != null
          ? (data['memberSince'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (avatar != null) 'avatar': avatar,
      if (country != null) 'country': country,
      if (memberSince != null) 'memberSince': Timestamp.fromDate(memberSince!),
    };
  }
}
