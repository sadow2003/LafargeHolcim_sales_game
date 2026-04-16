import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lafargeholcim_sales_game/firebase_options.dart';
import 'package:lafargeholcim_sales_game/screens/Login.dart';
import 'package:lafargeholcim_sales_game/screens/dashboard.dart';
import 'package:lafargeholcim_sales_game/screens/products.dart';
import 'package:lafargeholcim_sales_game/screens/profile.dart';
import 'package:lafargeholcim_sales_game/screens/register.dart';
import 'package:lafargeholcim_sales_game/screens/sale_claim_page.dart';


const Color kPrimaryColor = Color(0xFF1B3A6B);
const Color kSecondaryColor = Color(0xFFF59E0B);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); 
  } catch (e) {
    print('Error initializing Firebase or loading .env: $e');
  }
  
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ); 

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LafargeHolcim Sales Game',




      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
        ),
        useMaterial3: true,
         fontFamily: 'Roboto',
         textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,//
        centerTitle: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical:14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),//
            ),
          ),
        ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(// Rounded border for input fields
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kPrimaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
      ), 
      ),
      initialRoute: '/login',

      routes: {
        '/login':    (context) => const LoginPage(),
        '/register': (context) => const RegisterScreen(),
        '/home':     (context) => const HomePage(),
        '/profile':  (context) => const ProfilePage(),
        '/products': (context) => const ProductsPage(),
        '/saleclaim': (context) => const SaleClaimPage(),
      },
    );
  }
}