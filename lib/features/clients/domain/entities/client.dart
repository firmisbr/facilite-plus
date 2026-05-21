class Client {
  const Client({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.document,
    this.address,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? document;
  final String? address;
  final String? notes;
  final String? createdAt;

  Client copyWith({
    String? name,
    String? phone,
    String? document,
    String? address,
    String? notes,
  }) {
    return Client(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      document: document ?? this.document,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toSyncPayload() {
    return {
      'user_id': userId,
      'name': name,
      if (phone != null) 'phone': phone,
      if (document != null) 'document': document,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
