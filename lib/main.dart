import 'dart:async';
import 'package:flutter/foundation.dart';//in simple terms: it provides a way to check if the app is running in debug mode or release mode, which can be useful for enabling or disabling certain features or behaviors based on the build configuration.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lafargeholcim_sales_game/ai/ai_coach_screen.dart';
import 'package:lafargeholcim_sales_game/services/notification_service.dart';
import 'package:lafargeholcim_sales_game/firebase_options.dart';
import 'package:lafargeholcim_sales_game/screens/login.dart';
import 'package:lafargeholcim_sales_game/screens/salesperon/dashboard.dart';
import 'package:lafargeholcim_sales_game/screens/salesperon/products.dart';
import 'package:lafargeholcim_sales_game/screens/salesperon/profile.dart';
import 'package:lafargeholcim_sales_game/screens/salesperon/ranking/rankings.dart';
import 'package:lafargeholcim_sales_game/screens/register.dart';
import 'package:lafargeholcim_sales_game/screens/salesperon/sale_claim.dart';
import 'package:lafargeholcim_sales_game/screens/admin/admin_dashboard.dart';
import 'package:lafargeholcim_sales_game/screens/admin/user_management/user_management_page.dart';
import 'package:lafargeholcim_sales_game/screens/sales_manager/manager_dashboard.dart';
import 'package:lafargeholcim_sales_game/screens/sales_manager/manager_product_managment.dart';
import 'package:lafargeholcim_sales_game/screens/sales_manager/manager_sales_managment.dart';
import 'package:lafargeholcim_sales_game/screens/broadcast.dart';
import 'package:lafargeholcim_sales_game/screens/salesperon/milestones/milestone_screen.dart';
import 'package:lafargeholcim_sales_game/screens/market_manager/market_manager_dashboard.dart';
import 'package:lafargeholcim_sales_game/screens/market_manager/event_manager/event_management.dart';
import 'package:lafargeholcim_sales_game/screens/salesperon/reward_store/reward_screen.dart';
import 'package:lafargeholcim_sales_game/widgets/require_auth.dart';


//primary colors of the application — LafargeHolcim brand palette
const Color kPrimaryColor   = Color(0xFF1B3A6B); // dark navy blue
const Color kSecondaryColor = Color(0xFF8DC21F);
const Color kCyanColor      = Color(0xFF00AEEF); // brand cyan

void main() async {
  WidgetsFlutterBinding.ensureInitialized();//ensures that the Flutter framework is fully initialized before running the app, which is necessary for certain operations like Firebase initialization.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error initializing loading .env: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,//initializes the Firebase app with the default options for the current platform (e.g., Android, iOS, web) specified in the DefaultFirebaseOptions class.
  );

  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider('6Lf7smctAAAAAEo9-4qhDYkDKU7RwSYsyLwPiN-s'),
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );

  // flutter_local_notifications does not support web — skip on web platform.
  if (!kIsWeb) {
    unawaited(NotificationService.instance.init());//initializes the notification service for the app, allowing it to handle local notifications. The unawaited function is used to indicate that the initialization can run asynchronously without blocking the main thread.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SalesQuest',
      //global default theme style of the application , any page that doesnt override the style will inherit from this
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
        ),
        useMaterial3: true,//enables Material Design 3 features and styling across the app, giving it a more modern look and feel.
         fontFamily: 'Roboto',
         textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      ),
      appBarTheme: const AppBarTheme(
        // Transparent so GradientAppBar's flexibleSpace gradient shows through.
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,//the text doesnt seem elevated from the screen
        centerTitle: true,
      ),
      //any elevation button used any where on this app will get this style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical:14),//adds 14 pixels of empty space above and below(vertical) the button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),//the corners have more smoth circular edge
            ),
          ),
        ),
        //any textFIELD input on the app will have this style by default
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),// Rounded border for input fields
          borderSide: BorderSide(color: const Color.fromRGBO(27, 58, 107, 1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      ),
      //what is the the first page the user see
      initialRoute: '/login',
      //add the routes of the application
      routes: {
        '/login':    (context) => const LoginPage(),
        '/register': (context) => const RegisterScreen(),

        '/home': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: HomePage(),
            ),
        '/profile': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: ProfilePage(),
            ),
        '/products': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: ProductsPage(),
            ),
        '/saleclaim': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: SaleClaimPage(),
            ),
        '/rankings': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: RankingsPage(),
            ),
        '/milestones': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: MilestoneScreen(),
            ),
        '/reward-store': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: RewardStorePage(),
            ),
        '/ai-coach': (context) => const RequireAuth(
              allowedRoles: ['salesperson'],
              child: AiCoachScreen()
        ),

        '/admin/dashboard': (context) => const RequireAuth(
              allowedRoles: ['admin'],
              child: AdminDashboard(),
            ),
        '/admin/users': (context) => const RequireAuth(
              allowedRoles: ['admin'],
              child: AdminUsersPage(),
            ),

        '/manager/dashboard': (context) => const RequireAuth(
              allowedRoles: ['sales-manager'],
              child: ManagerDashboard(),
            ),
        '/manager/products': (context) => const RequireAuth(
              allowedRoles: ['sales-manager'],
              child: ManagerProductsPage(),
            ),
        '/manager/sales': (context) => const RequireAuth(
              allowedRoles: ['sales-manager'],
              child: ManagerSalesManagment(),
            ),

        '/market-manager/dashboard': (context) => const RequireAuth(
              allowedRoles: ['market-manager'],
              child: MarketManagerDashboard(),
            ),
        '/market-manager/events': (context) => const RequireAuth(
              allowedRoles: ['market-manager'],
              child: EventManagementPage(),
            ),

        '/broadcast': (context) => const RequireAuth(
              allowedRoles: ['admin', 'sales-manager', 'market-manager', 'salesperson'],
              child: BroadcastScreen(),
            ),
      },
    );
  }
}
