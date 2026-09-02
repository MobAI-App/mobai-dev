// Preview adapter for google_maps_flutter (federated, no macOS/Linux impl).
// Covers: BitmapDescriptor.asset at bootstrap,
// AdvancedMarker/MarkerId/LatLng/CameraPosition, and a GoogleMap widget that
// renders a placeholder with the camera target instead of tiles.
import 'package:flutter/material.dart';

class LatLng {
  const LatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
  @override
  String toString() => '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}

class BitmapDescriptor {
  const BitmapDescriptor._(this.assetName);
  final String? assetName;
  static const BitmapDescriptor defaultMarker = BitmapDescriptor._(null);
  static Future<BitmapDescriptor> asset(
    ImageConfiguration configuration,
    String assetName, {
    double? width,
    double? height,
  }) async => BitmapDescriptor._(assetName);
}

class MarkerId {
  const MarkerId(this.value);
  final String value;
}

class Marker {
  const Marker({required this.markerId, this.position = const LatLng(0, 0), this.icon = BitmapDescriptor.defaultMarker});
  final MarkerId markerId;
  final LatLng position;
  final BitmapDescriptor icon;
}

class AdvancedMarker extends Marker {
  const AdvancedMarker({required super.markerId, super.position, super.icon});
}

class CameraPosition {
  const CameraPosition({required this.target, this.zoom = 0, this.bearing = 0, this.tilt = 0});
  final LatLng target;
  final double zoom;
  final double bearing;
  final double tilt;
}

enum MapType { none, normal, satellite, terrain, hybrid }

enum GoogleMapMarkerType { legacy, advancedMarker }

class GoogleMap extends StatelessWidget {
  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.mapId,
    this.mapType = MapType.normal,
    this.markers = const <Marker>{},
    this.markerType = GoogleMapMarkerType.legacy,
    this.myLocationButtonEnabled = true,
    this.myLocationEnabled = false,
    this.zoomControlsEnabled = true,
    this.mapToolbarEnabled = true,
    this.compassEnabled = true,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.liteModeEnabled = false,
    this.buildingsEnabled = true,
    this.trafficEnabled = false,
    this.onMapCreated,
    this.onTap,
  });

  final CameraPosition initialCameraPosition;
  final String? mapId;
  final MapType mapType;
  final Set<Marker> markers;
  final GoogleMapMarkerType markerType;
  final bool myLocationButtonEnabled;
  final bool myLocationEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final bool compassEnabled;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool liteModeEnabled;
  final bool buildingsEnabled;
  final bool trafficEnabled;
  final void Function(Object controller)? onMapCreated;
  final void Function(LatLng)? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD1DEC9),
      alignment: Alignment.center,
      child: Semantics(
        label: 'map',
        child: Text(
          'map ${mapType.name} at ${initialCameraPosition.target} zoom ${initialCameraPosition.zoom.toStringAsFixed(0)}, ${markers.length} marker(s)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF223322), fontSize: 14),
        ),
      ),
    );
  }
}
