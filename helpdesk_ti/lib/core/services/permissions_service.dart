import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  /// Verifica e solicita permissão de câmera apenas se necessário
  static Future<bool> verificarPermissaoCamera() async {
    final status = await Permission.camera.status;

    // Se já foi concedida, retorna true sem solicitar novamente
    if (status.isGranted) {
      return true;
    }

    // Se foi negada permanentemente, não solicitar novamente
    if (status.isPermanentlyDenied) {
      print(
        '⚠️ Permissão de câmera negada permanentemente. Abra as configurações do app.',
      );
      return false;
    }

    // Solicitar apenas se ainda não foi respondida
    if (status.isDenied || status.isLimited) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    return false;
  }

  /// Verifica e solicita permissão de galeria apenas se necessário
  static Future<bool> verificarPermissaoGaleria() async {
    final status = await Permission.photos.status;

    // Se já foi concedida, retorna true sem solicitar novamente
    if (status.isGranted) {
      return true;
    }

    // Se foi negada permanentemente, não solicitar novamente
    if (status.isPermanentlyDenied) {
      print(
        '⚠️ Permissão de galeria negada permanentemente. Abra as configurações do app.',
      );
      return false;
    }

    // Solicitar apenas se ainda não foi respondida
    if (status.isDenied || status.isLimited) {
      final result = await Permission.photos.request();
      return result.isGranted;
    }

    return false;
  }
}
