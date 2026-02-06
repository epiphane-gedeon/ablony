class ParticipantDetails {
  final String name;
  final String? avatar;

  const ParticipantDetails({required this.name, this.avatar});

  factory ParticipantDetails.fromFirestore(Map<String, dynamic> data) {
    return ParticipantDetails(
      name: data['name'] as String,
      avatar: data['avatar'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, if (avatar != null) 'avatar': avatar};
  }
}
