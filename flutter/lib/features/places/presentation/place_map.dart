import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../domain/place_draft.dart';

class PlaceMapConfig {
  const PlaceMapConfig(this.tileUrl);
  factory PlaceMapConfig.fromEnvironment() =>
      const PlaceMapConfig(String.fromEnvironment('REMORI_MAP_TILE_URL'));
  final String tileUrl;
  bool get valid {
    final uri = Uri.tryParse(tileUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'tile.openstreetmap.org' &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        uri.userInfo.isEmpty &&
        tileUrl.endsWith('/{z}/{x}/{y}.png');
  }
}

final placeMapConfigProvider = Provider<PlaceMapConfig>(
  (ref) => PlaceMapConfig.fromEnvironment(),
);
typedef PlaceMapBuilder = Widget Function(
  BuildContext,
  PlaceDraft,
  bool,
  ValueChanged<PlacePoint>,
);
final placeMapBuilderProvider = Provider<PlaceMapBuilder>((ref) {
  final config = ref.watch(placeMapConfigProvider);
  return (context, draft, locked, select) =>
      PlaceMap(draft: draft, locked: locked, select: select, config: config);
});

class PlaceMap extends StatefulWidget {
  const PlaceMap({
    super.key,
    required this.draft,
    required this.locked,
    required this.select,
    required this.config,
    this.tiles,
  });
  final PlaceDraft draft;
  final bool locked;
  final ValueChanged<PlacePoint> select;
  final PlaceMapConfig config;
  // Deterministic tiles in tests; production uses the approved cached provider.
  final TileProvider? tiles;
  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap> {
  final _map = MapController();
  bool _ready = false;
  bool _failed = false;
  bool _dragging = false;
  TileProvider? _tiles;
  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PlaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready && oldWidget.draft.point == null && widget.draft.point != null) {
      Future.microtask(() {
        if (mounted) _map.move(_latLng(widget.draft.point!), 17);
      });
    }
  }

  LatLng _latLng(PlacePoint p) =>
      LatLng(p.latitude.clamp(-85.05112878, 85.05112878), p.longitude);
  void _select(LatLng p) {
    if (!widget.locked) {
      widget.select(
        PlacePoint(p.latitude, ((p.longitude + 180) % 360 + 360) % 360 - 180),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context), point = widget.draft.point;
    if (!widget.config.valid) {
      return ColoredBox(
        color: RemoriColors.lavender,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(s.placeMapUnavailable),
          ),
        ),
      );
    }
    return Stack(
      children: [
        Semantics(
          container: true,
          label: point == null ? s.placeDragPin : s.placePin,
          onTap: widget.locked || _failed
              ? null
              : () => _select(_map.camera.center),
          child: ExcludeSemantics(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: point == null
                    ? const LatLng(0, 0)
                    : _latLng(point),
                initialZoom: point == null ? 2 : 17,
                minZoom: 2,
                maxZoom: 19,
                backgroundColor: RemoriColors.lavender,
                interactionOptions: InteractionOptions(
                  flags: widget.locked || _dragging
                      ? InteractiveFlag.none
                      : InteractiveFlag.drag |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.scrollWheelZoom,
                ),
                onMapReady: () => _ready = true,
                onTap: (_, p) {
                  if (!_failed) _select(p);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: widget.config.tileUrl,
                  userAgentPackageName: 'org.AI.remori',
                  errorTileCallback: (_, _, _) {
                    Future.microtask(() {
                      if (mounted && !_failed) setState(() => _failed = true);
                    });
                  },
                  panBuffer: 0,
                  tileProvider: _tiles ??=
                      widget.tiles ??
                      NetworkTileProvider(
                        headers: {'User-Agent': 'Remori/1.0 (org.AI.remori)'},
                        attemptDecodeOfHttpErrorResponses: false,
                      ),
                ),
                if (point != null) ...[
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _latLng(point),
                        radius: widget.draft.radiusM.toDouble(),
                        useRadiusInMeter: true,
                        color: RemoriColors.purple.withValues(alpha: .15),
                        borderColor: RemoriColors.purple,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _latLng(point),
                        width: 48,
                        height: 48,
                        child: Listener(
                          onPointerDown: widget.locked || _failed
                              ? null
                              : (_) => setState(() => _dragging = true),
                          onPointerUp: (_) {
                            if (_dragging) setState(() => _dragging = false);
                          },
                          onPointerCancel: (_) {
                            if (_dragging) setState(() => _dragging = false);
                          },
                          onPointerMove: widget.locked || _failed
                              ? null
                              : (details) {
                                  final pixels = _map.camera
                                      .latLngToScreenOffset(
                                        _latLng(widget.draft.point!),
                                      );
                                  _select(
                                    _map.camera.screenOffsetToLatLng(
                                      pixels + details.delta,
                                    ),
                                  );
                                },
                          child: GestureDetector(
                            key: const ValueKey('place-pin'),
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: widget.locked || _failed
                                ? null
                                : (_) {},
                            child: Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: RemoriColors.purple,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_failed)
          PositionedDirectional(
            start: 12,
            end: 12,
            top: 8,
            child: ColoredBox(
              color: RemoriColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  s.placeMapUnavailable,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          start: 12,
          end: 12,
          bottom: 8,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: RemoriColors.surface.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Text(
                      s.placeDragPin,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RemoriColors.muted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: RemoriColors.surface.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Text(
                      s.placeAttribution,
                      style: const TextStyle(
                        fontSize: 10,
                        color: RemoriColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
