/// PIN de suporte para importar dados de outro usuário via nuvem.
abstract final class AdminImportPin {
  static const code = '1910';

  static bool verify(String input) => input == code;
}
