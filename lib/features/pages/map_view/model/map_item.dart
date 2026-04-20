import 'package:maplibre_gl/maplibre_gl.dart';

class MapItem {
  final int id;
  final String name;
  final DateTime createdAt;
  final String img1, img2;
  final LatLng coords;

  const MapItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.img1,
    required this.img2,
    required this.coords,
  });
}

const _rawData = [
  ('Toshkent Metro Station',   LatLng(41.2995, 69.2401)),
  ('Samarkand Grand Bazaar',   LatLng(39.6270, 66.9749)),
  ('Bukhara Old City',         LatLng(39.7747, 64.4286)),
  ('Namangan Central Park',    LatLng(41.0011, 71.6725)),
  ('Fergana Valley Route',     LatLng(40.3834, 71.7812)),
  ('Andijan Main Square',      LatLng(40.7828, 72.3437)),
  ('Nukus Art Museum',         LatLng(42.4647, 59.6038)),
  ('Termez Border Post',       LatLng(37.2241, 67.2783)),
  ('Guliston City Center',     LatLng(40.4897, 68.7751)),
  ('Jizzakh District Hub',     LatLng(40.1158, 67.8422)),
  ('Sirdaryo Bridge',          LatLng(40.8439, 68.6660)),
  ('Qarshi Airport',           LatLng(38.8629, 65.7990)),
  ('Navoi Mining Zone',        LatLng(40.0842, 65.3791)),
  ('Urgench Bazaar',           LatLng(41.5547, 60.6317)),
  ('Khiva Ancient Wall',       LatLng(41.3783, 60.3634)),
  ('Shakhrisabz Palace',       LatLng(39.0489, 66.8299)),
  ('Margilan Silk Factory',    LatLng(40.4737, 71.7224)),
  ('Kokand Fortress',          LatLng(40.5289, 70.9428)),
  ('Denov Village',            LatLng(37.7683, 67.9047)),
  ('Muynaq Ship Graveyard',    LatLng(43.8006, 59.0158)),
  ('Chimgan Mountain Resort',  LatLng(41.5476, 70.0581)),
  ('Charvak Lake',             LatLng(41.6182, 70.1213)),
  ('Chorsu Bazaar',            LatLng(41.3096, 69.2348)),
  ('Amudarya River Camp',      LatLng(40.1233, 62.8580)),
  ('Zarafshan Valley Post',    LatLng(39.9234, 64.5769)),
  ('Kyzylkum Desert Track',    LatLng(41.1000, 64.5000)),
  ('Angren Coal Station',      LatLng(41.0144, 70.1395)),
  ('Olmaliq Mine',             LatLng(40.8884, 69.3374)),
  ('Yangiyer Rail Station',    LatLng(40.7730, 69.0453)),
  ('Bekabad Steel Plant',      LatLng(40.2247, 69.2177)),
  ('Ohangaron River Bridge',   LatLng(41.2670, 69.6340)),
  ('Eski Shahar Quarter',      LatLng(41.2960, 69.2330)),
  ('Hazrati Imam Complex',     LatLng(41.3011, 69.2277)),
  ('Tillya Kari Madrasa',      LatLng(39.6520, 66.9597)),
  ('Registan Square',          LatLng(39.6548, 66.9757)),
  ('Shah-i-Zinda Necropolis',  LatLng(39.6573, 66.9750)),
  ('Gur-e-Amir Mausoleum',     LatLng(39.6475, 66.9730)),
  ('Ark Fortress Bukhara',     LatLng(39.7763, 64.4167)),
  ('Sitorai Mohi Palace',      LatLng(39.7820, 64.4286)),
  ('Poi Kalon Minaret',        LatLng(39.7755, 64.4166)),
  ('Toshkent TV Tower',        LatLng(41.2994, 69.2401)),
  ('Shodlik Palace Hotel',     LatLng(41.2850, 69.2100)),
  ('Alay Mountain Pass',       LatLng(40.5167, 70.6500)),
  ('Independence Square TAS',  LatLng(41.3000, 69.2700)),
  ('Minor Mosque Toshkent',    LatLng(41.3043, 69.2370)),
  ('Barak Khan Madrassa',      LatLng(41.3000, 69.2400)),
  ('Kukeldash Madrassa',       LatLng(41.2981, 69.2367)),
];

final mockMapData = List<MapItem>.generate(_rawData.length, (i) {
  final id = 1001 + i;
  return MapItem(
    id: id,
    name: _rawData[i].$1,
    createdAt: DateTime(2024, 1, 1).add(Duration(days: i * 7 + i)),
    img1: 'https://picsum.photos/seed/${id}a/600/400',
    img2: 'https://picsum.photos/seed/${id}b/600/400',
    coords: _rawData[i].$2,
  );
});

// ── Formatters ────────────────────────────────────────────────────────────────
const _mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

String fmtMapDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')} ${_mo[d.month-1]} ${d.year}'
    '  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

String fmtMapDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')} ${_mo[d.month-1]} ${d.year}';