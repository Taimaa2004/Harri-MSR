import 'package:flutter/material.dart';
import 'package:graduation_project/Screens/Drawer/Preference/theme_provider.dart';
import 'package:provider/provider.dart';

class PreferenceScreen extends StatelessWidget {
  const PreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text("Preferences")),
      body: ListTile(
        title: const Text("Dark Theme"),
        trailing: Switch(
          value: isDark,
          onChanged: (value) {
            themeProvider.toggleTheme(value);
          },
        ),
      ),
    );
  }
}
