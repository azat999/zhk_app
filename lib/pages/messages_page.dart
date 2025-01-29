import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zhk_app/services/UserRoleProvider.dart';
import 'package:zhk_app/widgets/user_role_provider.dart';

import 'login_page.dart';

class MessagesPage extends StatelessWidget {
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRoleProvider = Provider.of<UserRoleProvider>(context);

    if (!userRoleProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Сообщения',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFFF2E594),
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: const Color(0xFF232323),
        ),
        backgroundColor: const Color(0xFFFFFFFF), // Белый фон
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/messageauth.png',
                width: 300,
                height: 221,
              ),
              const SizedBox(height: 100),
              OutlinedButton(
                onPressed: () => _navigateToLogin(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFBB00), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 12),
                ),
                child: const Text(
                  'Авторизоваться',
                  style: TextStyle(
                    color: Color(0xFFFFBB00),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                   
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Сообщения',
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFFF2E594),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF232323),
      ),
      backgroundColor: const Color(0xFFFFFFFF), // Белый фон
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.message, color: Colors.blue),
            title: Text('Сообщение ${index + 1}'),
            subtitle: const Text('Это пример текста сообщения.'),
          );
        },
      ),
    );
  }
}
