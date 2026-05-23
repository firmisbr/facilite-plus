import '../entities/client.dart';

abstract class ClientsRepository {
  Stream<List<Client>> watchAll(String userId);

  Future<Client?> getById(String id);

  Future<Client?> findByDocumentOrPhone({
    required String userId,
    String? document,
    String? phone,
  });

  Future<Client> create({
    required String userId,
    required String name,
    String? phone,
    String? email,
    String? document,
    String? address,
    String? notes,
  });

  Future<Client> update(Client client);

  Future<void> delete(String id);
}
