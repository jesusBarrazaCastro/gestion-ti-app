import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  CustomAppBar({super.key});

  //final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor:  Color.fromARGB(255, 56, 56, 56), 
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: PopupMenuButton<int>(
            tooltip: '',
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Text('Cerrar Sesión'),
                    Spacer(),
                    Icon(Icons.logout),
                  ],
                ),
              ),
            ],
            onSelected: (int result) {
              if (result == 1) {
                try {
                  //supabase.auth.signOut();
                  //context.replace('/');
                } catch(e){
                }
              } 
            },
            child: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white, weight: 20,), 
        onPressed: () {
          // Toggle the drawer menu
          Scaffold.of(context).openDrawer();
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
