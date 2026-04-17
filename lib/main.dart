import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lafargeholcim_sales_game/firebase_options.dart';
import 'package:lafargeholcim_sales_game/screens/Login.dart';
import 'package:lafargeholcim_sales_game/screens/dashboard.dart';
import 'package:lafargeholcim_sales_game/screens/products.dart';
import 'package:lafargeholcim_sales_game/screens/profile.dart';
import 'package:lafargeholcim_sales_game/screens/rankings.dart';
import 'package:lafargeholcim_sales_game/screens/register.dart';
import 'package:lafargeholcim_sales_game/screens/sale_claim.dart';
import 'package:lafargeholcim_sales_game/screens/admin/admin_dashboard.dart';
import 'package:lafargeholcim_sales_game/screens/admin/admin_products_page.dart';
import 'package:lafargeholcim_sales_game/screens/admin/admin_sales_page.dart';
import 'package:lafargeholcim_sales_game/screens/admin/admin_users_page.dart';

//primary colors of the application
const Color kPrimaryColor = Color.fromARGB(255, 27, 58, 107);
const Color kSecondaryColor = Color.fromARGB(255, 66, 245, 11);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); 
  } catch (e) {
    print('Error initializing loading .env: $e');
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
        //any text input on the app will have this style by default
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
        '/home':     (context) => const HomePage(),
        '/profile':  (context) => const ProfilePage(),
        '/products': (context) => const ProductsPage(),
        '/saleclaim':        (context) => const SaleClaimPage(),
        '/rankings':         (context) => const RankingsPage(),
        '/admin/dashboard':  (context) => const AdminDashboard(),
        '/admin/products':   (context) => const AdminProductsPage(),
        '/admin/sales':      (context) => const AdminSalesPage(),
        '/admin/users':      (context) => const AdminUsersPage(),
      },
    );
  }
}