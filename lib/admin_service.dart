import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final _client = Supabase.instance.client;

  static Future<String> getMyRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return 'user';

    try {
      final result = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      return result?['role'] as String? ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  static Future<bool> isAdmin() async {
    final role = await getMyRole();
    return role == 'owner' || role == 'admin';
  }
}
