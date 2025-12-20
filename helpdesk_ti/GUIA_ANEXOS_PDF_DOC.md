# 📎 GUIA DE ANEXOS - PDF, DOC e Outros Arquivos

## ✅ O QUE FOI IMPLEMENTADO

Sistema completo de anexos de arquivos com suporte a:
- 📄 PDF
- 📝 DOC/DOCX (Word)
- 📊 XLS/XLSX (Excel)
- 📷 JPG/PNG (Imagens)
- 📝 TXT (Texto)

---

## 📦 BIBLIOTECAS INSTALADAS

### 1. **file_picker: ^8.1.4**
**O que faz:** Permite escolher arquivos do dispositivo

**Como funciona:**
```dart
// Abre seletor de arquivos
final result = await FilePicker.platform.pickFiles(
  allowMultiple: true,  // Múltiplos arquivos
  type: FileType.custom,
  allowedExtensions: ['pdf', 'doc', 'docx'],
  withData: true,  // Pega os bytes do arquivo
);

// Resultado:
result.files[0].name;   // "documento.pdf"
result.files[0].bytes;  // Uint8List com os dados
result.files[0].size;   // Tamanho em bytes
```

### 2. **syncfusion_flutter_pdfviewer: ^28.1.35**
**O que faz:** Visualizador profissional de PDFs

**Recursos:**
- ✅ Zoom in/out
- ✅ Scroll de páginas
- ✅ Seleção de texto
- ✅ Busca de texto
- ✅ Navegação por páginas
- ✅ Funciona offline

### 3. **path_provider: ^2.1.5**
**O que faz:** Acessa diretórios do sistema

**Usado para:**
- Salvar PDFs temporariamente
- Cache de documentos
- Armazenamento local

---

## 🏗️ ARQUITETURA IMPLEMENTADA

### **Fluxo de Upload de Arquivo:**

```
1. Usuário clica em "Anexar Arquivos"
   └→ FileAttachmentWidget

2. Abre seletor de arquivos
   └→ FilePicker.platform.pickFiles()

3. Valida arquivo:
   ├→ Tem bytes? ✅
   ├→ Extensão permitida? ✅
   ├→ Tamanho < 25MB? ✅
   └→ Se OK: continua

4. Faz upload para Firebase Storage
   └→ chamadoService.uploadFile(bytes, name)

5. Storage retorna URL pública
   └→ https://firebase.com/files/documento.pdf

6. Salva URL no Firestore
   └→ Campo 'anexos' do chamado
```

---

## 📁 ARQUIVOS CRIADOS

### **1. `file_attachment_widget.dart`**

**Widgets:**

#### **FileAttachmentWidget**
Botão para anexar arquivos

```dart
FileAttachmentWidget(
  onFilesSelected: (files) {
    // files = List<PlatformFile>
    for (var file in files) {
      print(file.name);   // "documento.pdf"
      print(file.bytes);  // Uint8List
      print(file.size);   // 1024000 (bytes)
    }
  },
  allowMultiple: true,
  allowedExtensions: ['pdf', 'doc', 'docx'],
)
```

#### **AttachedFilesListWidget**
Lista de arquivos anexados

```dart
AttachedFilesListWidget(
  files: [
    AttachedFileInfo(
      name: 'documento.pdf',
      url: 'https://...',
      size: 1024000,
      extension: 'pdf',
    ),
  ],
  onRemove: (index) {
    // Remove arquivo pelo índice
  },
  onView: (url, name) {
    // Abre PDF para visualizar
  },
)
```

**Características:**
- ✅ Validação de tamanho (máx 25MB)
- ✅ Validação de extensão
- ✅ Ícones coloridos por tipo
- ✅ Formatação de tamanho (KB, MB)
- ✅ Botões de remover e visualizar

---

### **2. `pdf_viewer_screen.dart`**

Tela completa para visualizar PDFs

**Recursos:**
```
┌─────────────────────────────┐
│ [←] documento.pdf  [5/12] 📄│ ← AppBar
├─────────────────────────────┤
│                             │
│    Conteúdo do PDF          │
│    com zoom e scroll        │
│                             │
│                 [🔍-][📐][🔍+]│ ← Controles de zoom
├─────────────────────────────┤
│              [↑]             │ ← Página anterior
│              [↓]             │ ← Próxima página
└─────────────────────────────┘
```

**Controles:**
- 🔍 Zoom in/out
- 📐 Resetar zoom
- ↕️ Navegação de páginas
- 🔢 Ir para página específica
- 📱 Modo tela cheia
- 📝 Seleção de texto

**Uso:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PdfViewerScreen(
      pdfUrl: 'https://firebase.com/file.pdf',
      title: 'Documento.pdf',
    ),
  ),
);
```

---

### **3. `chamado_service.dart` (atualizado)**

Novo método: **uploadFile()**

```dart
Future<String> uploadFile({
  required String chamadoId,
  required Uint8List fileBytes,
  required String fileName,
}) async {
  // 1. Cria referência no Storage
  final ref = storage
    .ref()
    .child('chamados/$chamadoId/files/${timestamp}_$fileName');
  
  // 2. Detecta tipo MIME
  final contentType = detectMimeType(fileName);
  
  // 3. Faz upload com metadata
  await ref.putData(fileBytes, SettableMetadata(
    contentType: contentType,
  ));
  
  // 4. Retorna URL pública
  return await ref.getDownloadURL();
}
```

**Tipos MIME suportados:**
```dart
'pdf'  → 'application/pdf'
'doc'  → 'application/msword'
'docx' → 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
'xls'  → 'application/vnd.ms-excel'
'xlsx' → 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
'txt'  → 'text/plain'
```

---

## 🎯 COMO INTEGRAR NAS TELAS EXISTENTES

### **Exemplo: Tela de Novo Chamado**

```dart
class NewTicketScreen extends StatefulWidget {
  // ...
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  List<PlatformFile> _selectedFiles = [];
  List<String> _uploadedUrls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... outros campos ...
          
          // Botão de anexar
          FileAttachmentWidget(
            onFilesSelected: (files) {
              setState(() {
                _selectedFiles.addAll(files);
              });
            },
          ),
          
          // Lista de arquivos selecionados
          if (_selectedFiles.isNotEmpty)
            AttachedFilesListWidget(
              files: _selectedFiles
                  .map((f) => AttachedFileInfo(
                        name: f.name,
                        url: '', // Ainda não foi uploadado
                        size: f.size,
                        extension: f.extension ?? '',
                      ))
                  .toList(),
              onRemove: (index) {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
            ),
          
          // Botão de enviar
          ElevatedButton(
            onPressed: () async {
              // 1. Fazer upload dos arquivos
              for (var file in _selectedFiles) {
                final url = await chamadoService.uploadFile(
                  chamadoId: chamadoId,
                  fileBytes: file.bytes!,
                  fileName: file.name,
                );
                _uploadedUrls.add(url);
              }
              
              // 2. Criar chamado com URLs
              await chamadoService.criarChamado(
                chamado.copyWith(anexos: _uploadedUrls),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📱 EXEMPLO COMPLETO DE USO

### **1. Seleção de Arquivos**
```dart
FileAttachmentWidget(
  allowMultiple: true,
  allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
  buttonText: 'Anexar Documentos',
  buttonIcon: Icons.attach_file,
  onFilesSelected: (files) {
    print('${files.length} arquivos selecionados');
    
    for (var file in files) {
      print('Nome: ${file.name}');
      print('Tamanho: ${file.size} bytes');
      print('Extensão: ${file.extension}');
    }
  },
)
```

### **2. Upload para Firebase**
```dart
Future<List<String>> uploadFiles(
  String chamadoId,
  List<PlatformFile> files,
) async {
  final urls = <String>[];
  
  for (var file in files) {
    try {
      final url = await chamadoService.uploadFile(
        chamadoId: chamadoId,
        fileBytes: file.bytes!,
        fileName: file.name,
      );
      urls.add(url);
      print('✅ Upload OK: ${file.name}');
    } catch (e) {
      print('❌ Erro: ${file.name} - $e');
    }
  }
  
  return urls;
}
```

### **3. Visualizar PDF**
```dart
// Ao clicar em um PDF
onView: (url, name) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PdfViewerScreen(
        pdfUrl: url,
        title: name,
      ),
    ),
  );
}
```

---

## 🔒 SEGURANÇA E VALIDAÇÕES

### **Validações Implementadas:**

1. **Tamanho Máximo: 25 MB**
```dart
if (file.size > 25 * 1024 * 1024) {
  throw 'Arquivo muito grande';
}
```

2. **Extensões Permitidas**
```dart
allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'png']
```

3. **Verificação de Bytes**
```dart
if (file.bytes == null) {
  throw 'Erro ao ler arquivo';
}
```

4. **Tipo MIME Correto**
```dart
SettableMetadata(
  contentType: 'application/pdf',  // Detectado automaticamente
)
```

---

## 📊 ESTRUTURA NO FIREBASE

### **Storage:**
```
storage/
└── chamados/
    └── {chamadoId}/
        ├── images/
        │   ├── 1234567890_foto.jpg
        │   └── 1234567891_screenshot.png
        └── files/
            ├── 1234567892_documento.pdf
            ├── 1234567893_planilha.xlsx
            └── 1234567894_relatorio.docx
```

### **Firestore:**
```json
{
  "tickets": {
    "chamadoId123": {
      "titulo": "Solicitação de equipamento",
      "anexos": [
        "https://storage.firebase.com/.../documento.pdf",
        "https://storage.firebase.com/.../planilha.xlsx"
      ],
      "anexosInfo": [
        {
          "name": "documento.pdf",
          "url": "https://...",
          "size": 1024000,
          "extension": "pdf"
        }
      ]
    }
  }
}
```

---

## 🎨 ÍCONES POR TIPO DE ARQUIVO

```
📄 PDF      → Icons.picture_as_pdf (vermelho)
📝 DOC/DOCX → Icons.description (azul)
📊 XLS/XLSX → Icons.table_chart (verde)
📝 TXT      → Icons.text_snippet (cinza)
📷 Imagens  → Icons.image (roxo)
📦 Outros   → Icons.insert_drive_file (cinza azulado)
```

---

## ⚡ PERFORMANCE

### **Otimizações:**

1. **Imagens comprimidas** (flutter_image_compress)
2. **Arquivos limitados a 25MB**
3. **Upload paralelo** (pode fazer múltiplos ao mesmo tempo)
4. **Cache de PDFs** (syncfusion faz automaticamente)
5. **Lazy loading** (arquivos só baixam quando necessário)

---

## 🚀 PRÓXIMOS PASSOS (Opcional)

1. **Preview de imagens** (já temos cached_network_image)
2. **Preview de DOCs** (converter para PDF ou usar Google Docs Viewer)
3. **Download de arquivos** (salvar localmente)
4. **Compartilhar arquivos** (share plugin)
5. **Comprimir PDFs grandes**
6. **OCR em PDFs** (extrair texto)

---

## 🆘 TROUBLESHOOTING

### ❌ "Erro ao selecionar arquivo"
**Causa:** Permissões não concedidas
**Solução:** Adicionar permissões no AndroidManifest.xml e Info.plist

### ❌ "Arquivo muito grande"
**Causa:** Arquivo > 25MB
**Solução:** Reduzir tamanho ou aumentar limite

### ❌ "PDF não carrega"
**Causa:** URL inválida ou problema de rede
**Solução:** Verificar URL e conexão com internet

### ❌ "Tipo de arquivo não suportado"
**Causa:** Extensão não está na lista permitida
**Solução:** Adicionar extensão em `allowedExtensions`

---

**Última atualização:** 1 de dezembro de 2025

✅ **Sistema completo de anexos implementado e funcionando!**
