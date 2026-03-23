import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/face_id/widget/face_id_page.dart';
import '../../features/login/widget/login_page.dart';
import '../../features/pages/face_recognition/face_recognition_page.dart';
import '../../features/pages/favorites/favorites_page.dart';
import '../../features/pages/home_page/home_page.dart';
import '../../features/pages/hotels/hotels_page.dart';
import '../../features/pages/map_view/map_view_page.dart';
import '../../features/pages/organizations/organizations_page.dart';
import '../../features/pages/search_address/search_address_page.dart';
import '../../features/pages/search_car/search_car_page.dart';
import '../widget/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/face-id',
        builder: (_, _) => const FaceIdPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home/posts',
            builder: (_, _) => const HomePage(),
          ),
          GoRoute(
            path: '/home/search-address',
            builder: (_, _) => const SearchAddressPage(),
          ),
          GoRoute(
            path: '/home/search-car',
            builder: (_, _) => const SearchCarPage(),
          ),
          GoRoute(
            path: '/home/face-recognition',
            builder: (_, _) => const FaceRecognitionPage(),
          ),
          GoRoute(
            path: '/home/hotels',
            builder: (_, _) => const HotelsPage(),
          ),
          GoRoute(
            path: '/home/organizations',
            builder: (_, _) => const OrganizationsPage(),
          ),
          GoRoute(
            path: '/home/favorites',
            builder: (_, _) => const FavoritesPage(),
          ),
          GoRoute(
            path: '/home/map',
            builder: (_, _) => const MapViewPage(),
          ),
        ],
      ),
    ],
  );
});