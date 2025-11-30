import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'dark';
  String _appColor = 'purple';
  String _language = 'es';
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _themeMode = response['theme_mode'] ?? 'dark';
          _appColor = response['app_color'] ?? 'purple';
          _language = response['language'] ?? 'es';
          _notificationsEnabled = response['notifications_enabled'] ?? true;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('user_settings').upsert({
        'user_id': user.id,
        'theme_mode': _themeMode,
        'app_color': _appColor,
        'language': _language,
        'notifications_enabled': _notificationsEnabled,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          const Text(
            'Apariencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.brightness_6_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Tema'),
                  subtitle: Text(_themeMode == 'dark' ? 'Oscuro' : 'Claro'),
                  trailing: Switch(
                    value: _themeMode == 'dark',
                    onChanged: (value) {
                      setState(() {
                        _themeMode = value ? 'dark' : 'light';
                      });
                      _saveSettings();
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.palette_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Color de la aplicación'),
                  subtitle: const Text('Toca para cambiar'),
                  onTap: () => _showColorPicker(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Idioma',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.language_rounded,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Idioma'),
              subtitle: Text(_language == 'es' ? 'Español' : 'English'),
              trailing: DropdownButton<String>(
                value: _language,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _language = value);
                    _saveSettings();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                Icons.notifications_rounded,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Activar notificaciones'),
              subtitle: const Text('Recordatorios de sesiones'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Acerca de',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Versión'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.description_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Términos y condiciones'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    // Implementar términos y condiciones
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Política de privacidad'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    // Implementar política de privacidad
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elige un color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildColorOption('Morado', 'purple', AppTheme.purple),
            _buildColorOption('Azul Oscuro', 'dark_blue', AppTheme.darkBlue),
            _buildColorOption('Naranja', 'orange', AppTheme.orange),
            _buildColorOption('Rosa', 'pink', AppTheme.pink),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String name, String value, Color color) {
    final isSelected = _appColor == value;
    
    return ListTile(
      title: Text(name),
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: isSelected ? 3 : 2,
          ),
        ),
      ),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: color)
          : null,
      onTap: () {
        setState(() => _appColor = value);
        _saveSettings();
        Navigator.of(context).pop();
        
        // Mostrar diálogo de reinicio
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reiniciar aplicación'),
            content: const Text(
              'Para aplicar el nuevo color, necesitas reiniciar la aplicación.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}
