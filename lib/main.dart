import 'package:auto_service/presentation/providers/booking_provider.dart';
import 'package:auto_service/presentation/providers/language_provider.dart';
import 'package:auto_service/presentation/providers/orders_provider.dart';
import 'package:auto_service/presentation/providers/theme_provider.dart';
import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:auto_service/presentation/providers/cart_provider.dart';
import 'package:auto_service/presentation/providers/favorites_provider.dart';
import 'package:auto_service/presentation/providers/profile_image_provider.dart';
import 'package:auto_service/presentation/providers/products_provider.dart';
import 'package:auto_service/data/datasources/repositories/product_repositories.dart';
import 'package:auto_service/data/datasources/repositories/auth_repositories.dart';
import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/presentation/screens/home/home_screen.dart';
import 'package:auto_service/presentation/screens/profile/profile_screen.dart';
import 'package:auto_service/presentation/screens/services/services_screen.dart';
import 'package:auto_service/presentation/screens/shop/shop_screen.dart';
import 'package:auto_service/core/config/yandex_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // Загружаем переменные окружения из .env (если файл есть локально)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Файл может отсутствовать в проде — это нормально
  }

  // Проверяем статус API ключей Яндекса
  print('🔑 Yandex API Keys Status: ${YandexConfig.configStatus}');
  print('📍 MapKit Key: ${YandexConfig.mapKitApiKey.substring(0, 8)}...');
  print('🗺️ Routing Key: ${YandexConfig.routingApiKey.substring(0, 8)}...');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru')],
      path: 'assets/lang',
      fallbackLocale: const Locale('uz'),
      child: const MyApp(),
    ),
  );
}

// 🔹 Глобальный ключ для MainScreen
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final themeProvider = snapshot.data!['themeProvider'] as ThemeProvider;
        final authProvider = snapshot.data!['authProvider'] as AuthProvider;
        final languageProvider =
            snapshot.data!['languageProvider'] as LanguageProvider;
        final productRepository =
            snapshot.data!['productRepository'] as ProductRepository;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<LanguageProvider>.value(
              value: languageProvider,
            ),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<FavoritesProvider>(
              create: (_) => FavoritesProvider(),
            ),
            ChangeNotifierProvider<BookingProvider>(
              create: (_) => BookingProvider()..init(),
            ),
            ChangeNotifierProvider<OrdersProvider>(
              create: (_) => OrdersProvider(productRepository),
            ),
            ChangeNotifierProvider<ProfileImageProvider>(
              create: (_) => ProfileImageProvider(),
            ),
            ChangeNotifierProvider<ProductsProvider>(
              create: (_) => ProductsProvider()..init(),
            ),
          ],

          /// 🔹 Материал-приложение реагирует на изменения темы и языка.
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              // Синхронизируем язык из SharedPreferences с EasyLocalization один раз
              context.read<LanguageProvider>().loadLanguage(context);
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Auto Service',
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: themeProvider.themeMode,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: MainScreen(key: mainScreenKey),
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _initializeApp() async {
    final localStorage = LocalStorage();
    await localStorage.init();

    final authProvider = AuthProvider(AuthRepository(localStorage));
    final languageProvider = LanguageProvider();
    final themeProvider = ThemeProvider();
    final productRepository = ProductRepository(localStorage);

    await Future.wait([
      authProvider.init(),
      // Язык синхронизируем в build() c контекстом EasyLocalization
      // _loadTheme вызывается в конструкторе ThemeProvider
    ]);

    return {
      'authProvider': authProvider,
      'languageProvider': languageProvider,
      'themeProvider': themeProvider,
      'productRepository': productRepository,
    };
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 🔹 Глобальный ключ для HomeScreen
  final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

  List<Widget> get _screens => [
    HomeScreen(key: homeScreenKey),
    const ServicesScreen(),
    const ShopScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// 🔹 Публичный метод для построения маршрута из DetailServiceScreen
  void buildRouteFromService(double latitude, double longitude) {
    setState(() {
      _selectedIndex = 0; // Переключаемся на вкладку карты
    });

    // После перестроения вызываем метод карты
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeState = homeScreenKey.currentState;
      if (homeState != null) {
        homeState.buildRouteTo(latitude, longitude);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.brightness == Brightness.dark
            ? Colors.white70
            : Colors.black54,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'nav_home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.design_services_outlined),
            activeIcon: const Icon(Icons.design_services),
            label: 'nav_services'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            activeIcon: const Icon(Icons.store),
            label: 'nav_shop'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'nav_profile'.tr(),
          ),
        ],
      ),
    );
  }
}
