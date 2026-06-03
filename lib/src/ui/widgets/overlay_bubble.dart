import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble> {
  static const _channel = MethodChannel('cricboss/app');
  Map<String, dynamic> _data = const {
    'title': 'CricBoss',
    'score': 'Live score',
  };

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() => _data = Map<String, dynamic>.from(event));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          await FlutterOverlayWindow.closeOverlay();
          await _channel.invokeMethod<bool>('openMatch', {
            'matchId': _data['matchId'],
          });
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF08251D),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(blurRadius: 18, color: Colors.black45)],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_cricket, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_data['title']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${_data['score']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB5F7DC),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
