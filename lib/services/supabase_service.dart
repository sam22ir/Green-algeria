import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://fkryelyvsajruvdutqda.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrcnllbHl2c2FqcnV2ZHV0cWRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MjYzMzgsImV4cCI6MjA4ODUwMjMzOH0.X4Qtq0q4JwJiGyPBE8Qzm0Dj1IVt1FgFFG2NsgrhQTg';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
