import 'dart:math';

class AppAvatars {
  /// Phase 1 & 2 — 18 avatars available.
  static const List<String> list = [
    // Old Phase 1 Avatars
    'assets/images/avatars/avatar_farmer_man_1.png',
    'assets/images/avatars/avatar_student_woman_1.png',
    'assets/images/avatars/avatar_elder_man_1.png',
    'assets/images/avatars/avatar_child_girl_1.png',
    'assets/images/avatars/avatar_urban_man_1.png',
    'assets/images/avatars/avatar_young_woman_1.png',
    'assets/images/avatars/avatar_elderly_woman_1.png',
    'assets/images/avatars/avatar_teen_boy_1.png',
    // Phase 2 — 5 new avatars
    'assets/images/avatars/avatar_rural_woman_1.png',
    'assets/images/avatars/avatar_expert_man_1.png',
    'assets/images/avatars/avatar_activist_woman_1.png',
    'assets/images/avatars/avatar_office_man_1.png',
    'assets/images/avatars/avatar_child_boy_1.png',
    // New Phase 2 Avatars
    'assets/images/avatars/avatar_modern_man_2.png',
    'assets/images/avatars/avatar_hijabi_woman_2.png',
    'assets/images/avatars/avatar_sporty_boy_2.png',
    'assets/images/avatars/avatar_nature_girl_2.png',
    'assets/images/avatars/avatar_wise_man_2.png',
  ];

  static String getRandom() {
    final random = Random();
    return list[random.nextInt(list.length)];
  }
}
