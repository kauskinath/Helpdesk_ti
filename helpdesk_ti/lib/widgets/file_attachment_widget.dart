import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';

/// Widget para anexar arquivos (imagens, PDFs, DOCs, etc)
///
/// Permite selecionar múltiplos tipos de arquivos e retorna
/// os bytes e informações dos arquivos selecionados.
///
/// Uso:
/// ```dart
/// FileAttachmentWidget(
///   onFilesSelected: (files) {
///     for (var file in files) {
///       print('Arquivo: ${file.name}');
///       print('Tamanho: ${file.size} bytes');
///       // Fazer upload: uploadFile(bytes: file.bytes, name: file.name)
///     }
///   },
/// )
/// ```
class FileAttachmentWidget extends StatelessWidget {
  final Function(List<PlatformFile>) onFilesSelected;
  final bool allowMultiple;
  final List<String> allowedExtensions;
  final String buttonText;
  final IconData buttonIcon;

  const FileAttachmentWidget({
    super.key,
    required this.onFilesSelected,
    this.allowMultiple = true,
    this.allowedExtensions = const [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'txt',
      'jpg',
      'jpeg',
      'png',
    ],
    this.buttonText = 'Anexar Arquivos',
    this.buttonIcon = Icons.attach_file,
  });

  Future<void> _pickFiles(BuildContext context) async {
    try {
      // Abrir seletor de arquivos
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true, // Importante: pega os bytes do arquivo
      );

      if (result == null) {
        // Usuário cancelou
        print('ℹ️ Seleção de arquivos cancelada');
        return;
      }

      // Validar arquivos selecionados
      final List<PlatformFile> validFiles = [];
      
      for (var file in result.files) {
        // Verificar se tem bytes
        if (file.bytes == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erro ao ler arquivo: ${file.name}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          continue;
        }

        // Verificar tamanho (limite: 25 MB)
        const maxSize = 25 * 1024 * 1024; // 25 MB
        if (file.size > maxSize) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Arquivo muito grande: ${file.name}\n'
                  'Tamanho máximo: 25 MB',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          continue;
        }

        validFiles.add(file);
      }

      if (validFiles.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Nenhum arquivo válido selecionado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Retornar arquivos válidos
      print('✅ ${validFiles.length} arquivo(s) selecionado(s)');
      for (var file in validFiles) {
        print('  📄 ${file.name} - ${(file.size / 1024).toStringAsFixed(1)} KB');
      }

      onFilesSelected(validFiles);

    } catch (e) {
      print('❌ Erro ao selecionar arquivos: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao selecionar arquivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pickFiles(context),
      icon: Icon(buttonIcon),
      label: Text(buttonText),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Widget para exibir lista de arquivos anexados
///
/// Mostra cards com ícones, nomes e tamanhos dos arquivos.
/// Permite remover arquivos e visualizar PDFs.
class AttachedFilesListWidget extends StatelessWidget {
  final List<AttachedFileInfo> files;
  final Function(int index)? onRemove;
  final Function(String url, String fileName)? onView;

  const AttachedFilesListWidget({
    super.key,
    required this.files,
    this.onRemove,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Arquivos Anexados:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...files.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return _buildFileCard(context, file, index);
        }),
      ],
    );
  }

  Widget _buildFileCard(BuildContext context, AttachedFileInfo file, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getFileIcon(file.extension),
        title: Text(
          file.name,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatFileSize(file.size),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão de visualizar (só para PDFs)
            if (file.extension == 'pdf' && onView != null)
              IconButton(
                icon: const Icon(Icons.visibility, color: AppColors.primary),
                onPressed: () => onView!(file.url, file.name),
                tooltip: 'Visualizar PDF',
              ),
            // Botão de remover
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => onRemove!(index),
                tooltip: 'Remover',
              ),
          ],
        ),
      ),
    );
  }

  /// Retorna ícone apropriado baseado na extensão do arquivo
  Widget _getFileIcon(String extension) {
    IconData icon;
    Color color;

    switch (extension.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case 'txt':
        icon = Icons.text_snippet;
        color = Colors.grey;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        icon = Icons.image;
        color = Colors.purple;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  /// Formata tamanho do arquivo para exibição
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
  }
}

/// Classe para armazenar informações de arquivo anexado
class AttachedFileInfo {
  final String name;
  final String url;
  final int size;
  final String extension;

  AttachedFileInfo({
    required this.name,
    required this.url,
    required this.size,
    required this.extension,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'size': size,
      'extension': extension,
    };
  }

  factory AttachedFileInfo.fromMap(Map<String, dynamic> map) {
    return AttachedFileInfo(
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      size: map['size'] ?? 0,
      extension: map['extension'] ?? '',
    );
  }
}

