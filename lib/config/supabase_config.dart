import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://yrmtthharlbribodmyjz.supabase.co',
    anonKey: 'sb_publishable_vgA416FYytXfS8xg-bQejg_K3oTguS5',
    debug: kDebugMode,
  );
}