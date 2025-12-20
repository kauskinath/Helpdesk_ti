import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:helpdesk_ti/core/theme/app_colors.dart';

/// Tela para visualizar arquivos PDF
///
/// Usa o Syncfusion PDF Viewer para exibir PDFs
/// com recursos de zoom, scroll e busca.
///
/// Uso:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => PdfViewerScreen(
///       pdfUrl: 'https://firebase.com/file.pdf',
///       title: 'Documento.pdf',
///     ),
///   ),
/// );
/// ```
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  int _currentPage = 1;
  int _totalPages = 0;
  bool _showControls = true;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _showPageNavigator() {
    showDialog(
      context: context,
      builder: (context) {
        int pageNumber = _currentPage;
        return AlertDialog(
          title: const Text('Ir para Página'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Página atual: $_currentPage de $_totalPages'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número da página',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  pageNumber = int.tryParse(value) ?? _currentPage;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (pageNumber >= 1 && pageNumber <= _totalPages) {
                  _pdfViewerController.jumpToPage(pageNumber);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Botão de página
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_currentPage/$_totalPages',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          // Botão de ir para página
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            onPressed: _showPageNavigator,
            tooltip: 'Ir para página',
          ),
          // Botão de alternar controles
          IconButton(
            icon: Icon(_showControls ? Icons.fullscreen : Icons.fullscreen_exit),
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            tooltip: _showControls ? 'Tela cheia' : 'Mostrar controles',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Visualizador de PDF
          SfPdfViewer.network(
            widget.pdfUrl,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _totalPages = details.document.pages.count;
              });
              print('✅ PDF carregado: $_totalPages páginas');
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            enableTextSelection: true,
            enableDoubleTapZooming: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),

          // Controles flutuantes
          if (_showControls)
            Positioned(
              bottom: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom Out
                      IconButton(
                        icon: const Icon(Icons.zoom_out),
                        onPressed: () {
                          _pdfViewerController.zoomLevel = 
                              _pdfViewerController.zoomLevel - 0.25;
                        },
                        tooltip: 'Diminuir zoom',
                      ),
                      // Resetar Zoom
                      IconButton(
                        icon: const Icon(Icons.fit_screen),
                        onPressed: () {
                          _pdfViewerController.zoomLevel = 1.0;
                        },
                        tooltip: 'Zoom original',
                      ),
                      // Zoom In
                      IconButton(
                        icon: const Icon(Icons.zoom_in),
                        onPressed: () {
                          _pdfViewerController.zoomLevel = 
                              _pdfViewerController.zoomLevel + 0.25;
                        },
                        tooltip: 'Aumentar zoom',
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showControls && _totalPages > 1
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Página anterior
                FloatingActionButton(
                  heroTag: 'prev_page',
                  mini: true,
                  onPressed: _currentPage > 1
                      ? () => _pdfViewerController.previousPage()
                      : null,
                  backgroundColor: _currentPage > 1
                      ? AppColors.primary
                      : Colors.grey,
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(height: 8),
                // Próxima página
                FloatingActionButton(
                  heroTag: 'next_page',
                  mini: true,
                  onPressed: _currentPage < _totalPages
                      ? () => _pdfViewerController.nextPage()
                      : null,
                  backgroundColor: _currentPage < _totalPages
                      ? AppColors.primary
                      : Colors.grey,
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            )
          : null,
    );
  }
}

