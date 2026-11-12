import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final _client = Supabase.instance.client;

  static Future<String> getMyRole() async {
    final user = _client.auth.currentUser;
    if (user == null) { debugPrint('ADMIN DEBUG: No logged-in user'); return 'user'; }

    try {
      final result = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      debugPrint('ADMIN DEBUG: role result = $result'); return result?['role'] as String? ?? 'user';
    } catch (e) { debugPrint('ADMIN DEBUG ERROR: $e');
      return 'user';
    }
  }

  static Future<bool> isAdmin() async {
    final role = await getMyRole();
    return role == 'owner' || role == 'admin';
  }
}


