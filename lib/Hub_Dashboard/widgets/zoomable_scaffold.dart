import 'package:flutter/material.dart';

class ZoomableScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;

  final Widget? body;

  final Widget? drawer;

  final Widget? endDrawer;

  final Color? backgroundColor;

  final Widget? floatingActionButton;

  final Widget? bottomNavigationBar;

  const ZoomableScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  State<ZoomableScaffold> createState() => _ZoomableScaffoldState();
}

class _ZoomableScaffoldState extends State<ZoomableScaffold> {
  double _scale = 1.0;

  void _zoomIn() => setState(() => _scale = (_scale + 0.1).clamp(0.5, 3.0));

  void _zoomOut() => setState(() => _scale = (_scale - 0.1).clamp(0.5, 3.0));

  void _resetZoom() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,

      drawer: widget.drawer,

      endDrawer: widget.endDrawer,

      backgroundColor: widget.backgroundColor,

      floatingActionButton: widget.floatingActionButton,

      bottomNavigationBar: widget.bottomNavigationBar,

      body: Stack(
        children: [
          SafeArea(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              scaleEnabled: false,
              panEnabled: false,
              boundaryMargin: const EdgeInsets.all(100),
              onInteractionUpdate: (details) {
                setState(() {
                  _scale = details.scale.clamp(0.5, 3.0);
                });
              },
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.topCenter,
                child: widget.body ?? const SizedBox.shrink(),
              ),
            ),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: null,
                    onPressed: _zoomIn,
                    child: const Icon(Icons.zoom_in),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: null,
                    onPressed: _zoomOut,
                    child: const Icon(Icons.zoom_out),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: null,
                    onPressed: _resetZoom,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
