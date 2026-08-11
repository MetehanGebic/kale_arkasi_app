import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_screen.dart'; // Mevcut HomeView'u kullanacağız
import '../../superlig/ui/superlig_screen.dart';
import '../../profile/ui/profile_screen.dart';

// Repositories & Cubits
import '../repository/economy_repository.dart';
import '../repository/leaderboard_repository.dart';
import '../repository/tasks_repository.dart';
import '../../superlig/data/repository/superlig_repository.dart';

import '../cubit/economy_cubit.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/leaderboard_cubit.dart';
import '../../superlig/cubit/superlig_cubit.dart';

const Color turfGreen = Color(0xFF1B5E20);
const Color teaBronze = Color(0xFFD4AF37);
const Color darkSurface = Color(0xFF121212);
const Color surfaceColor = Color(0xFFF5F5F5);

class MainNavigationScreen extends StatefulWidget {
  final String userToken;
  const MainNavigationScreen({super.key, required this.userToken});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeView(userToken: widget.userToken),
      const SuperligScreen(),
      ProfileScreen(userToken: widget.userToken),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => EconomyCubit(EconomyRepository())..fetchBalance(widget.userToken),
        ),
        BlocProvider(
          create: (context) => TasksCubit(TasksRepository(), widget.userToken)..fetchTasks(),
        ),
        BlocProvider(
          create: (context) => LeaderboardCubit(LeaderboardRepository(), widget.userToken)..fetchLeaderboard(),
        ),
        BlocProvider(
          create: (context) => SuperligCubit(SuperligRepository())..fetchAllData(),
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: Colors.white,
            selectedItemColor: turfGreen,
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Kahvehane',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_soccer),
                label: 'Süper Lig',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

