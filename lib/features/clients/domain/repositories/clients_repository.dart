import '../entities/client.dart';

abstract class ClientsRepository {
  Stream<List<Client>> watchAll(String userId);

  Future<Client?> getById(String id);

  Future<Client> create({
    required String userId,
    required String name,
    String? phone,
    String? document,
    String? address,
    String? notes,
  });

  Future<Client> update(Client client);

  Future<void> delete(String id);
}
