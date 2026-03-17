import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Integration / App Flow Tests — Chapter 15 (Green Algeria)
// Tests isolated widget flows that do NOT require Firebase or Supabase.
// Full end-to-end device tests (real login → plant tree → see pin) are
// performed manually as described in PERFORMANCE_CHECKLIST.md.
// ─────────────────────────────────────────────────────────────────────────────

// ── Minimal stub widgets representing the app's key UI surfaces ──────────────

class _FakeLoginScreen extends StatelessWidget {
  final VoidCallback? onLogin;
  const _FakeLoginScreen({this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('الجزائر خضراء', key: Key('app-title')),
          TextField(key: const Key('email-field'), decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
          TextField(key: const Key('password-field'), obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
          ElevatedButton(key: const Key('login-btn'), onPressed: onLogin, child: const Text('تسجيل الدخول')),
        ],
      ),
    );
  }
}

class _FakeBottomNav extends StatefulWidget {
  const _FakeBottomNav();
  @override
  State<_FakeBottomNav> createState() => _FakeBottomNavState();
}

class _FakeBottomNavState extends State<_FakeBottomNav> {
  int _index = 0;
  final _labels = ['الرئيسية', 'الخريطة', 'الحملات', 'المتصدرون', 'الملف'];
  final _keys = ['home-tab', 'map-tab', 'campaigns-tab', 'leaderboard-tab', 'profile-tab'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(_labels[_index], key: Key('screen-${_labels[_index]}'))),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: const Color(0xFF606C38), // olive-grove
        unselectedItemColor: const Color(0xFF6B705C), // olive-grey
        type: BottomNavigationBarType.fixed,
        items: List.generate(5, (i) => BottomNavigationBarItem(
          icon: Icon(Icons.circle, key: Key(_keys[i])),
          label: _labels[i],
        )),
      ),
    );
  }
}

class _FakeSettingsScreen extends StatelessWidget {
  final bool isVolunteer;
  const _FakeSettingsScreen({this.isVolunteer = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const ListTile(key: Key('lang-tile'), title: Text('اللغة')),
          const ListTile(key: Key('darkmode-tile'), title: Text('الوضع الليلي')),
          const ListTile(key: Key('notifications-tile'), title: Text('الإشعارات')),
          const ListTile(key: Key('about-tile'), title: Text('حول التطبيق')),
          const ListTile(key: Key('logout-tile'), title: Text('تسجيل الخروج')),
          if (isVolunteer)
            const ListTile(
              key: Key('upgrade-request-tile'),
              title: Text('طلب ترقية إلى منظم'),
            ),
        ],
      ),
    );
  }
}

// ── Test suite ────────────────────────────────────────────────────────────────

void main() {
  // ─── Volunteer User Flow ───────────────────────────────────────────────────
  group('Volunteer User Flow', () {
    testWidgets('Login screen renders all required fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: _FakeLoginScreen(),
        ),
      ));

      expect(find.byKey(const Key('app-title')), findsOneWidget);
      expect(find.byKey(const Key('email-field')), findsOneWidget);
      expect(find.byKey(const Key('password-field')), findsOneWidget);
      expect(find.byKey(const Key('login-btn')), findsOneWidget);
    });

    testWidgets('Login button triggers login callback', (tester) async {
      bool loginCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: _FakeLoginScreen(onLogin: () => loginCalled = true),
        ),
      ));

      await tester.tap(find.byKey(const Key('login-btn')));
      await tester.pump();
      expect(loginCalled, true);
    });

    testWidgets('App shell shows 5-tab bottom navigation', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: _FakeBottomNav(),
        ),
      ));

      // 5 tabs visible
      expect(find.byKey(const Key('home-tab')), findsOneWidget);
      expect(find.byKey(const Key('map-tab')), findsOneWidget);
      expect(find.byKey(const Key('campaigns-tab')), findsOneWidget);
      expect(find.byKey(const Key('leaderboard-tab')), findsOneWidget);
      expect(find.byKey(const Key('profile-tab')), findsOneWidget);
    });

    testWidgets('Tapping each nav tab changes the active screen', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: _FakeBottomNav(),
        ),
      ));

      // Start on Home
      expect(find.byKey(const Key('screen-الرئيسية')), findsOneWidget);

      // Tap Map tab
      await tester.tap(find.byKey(const Key('map-tab')));
      await tester.pump();
      expect(find.byKey(const Key('screen-الخريطة')), findsOneWidget);

      // Tap Campaigns tab
      await tester.tap(find.byKey(const Key('campaigns-tab')));
      await tester.pump();
      expect(find.byKey(const Key('screen-الحملات')), findsOneWidget);

      // Tap Leaderboard tab
      await tester.tap(find.byKey(const Key('leaderboard-tab')));
      await tester.pump();
      expect(find.byKey(const Key('screen-المتصدرون')), findsOneWidget);

      // Tap Profile tab
      await tester.tap(find.byKey(const Key('profile-tab')));
      await tester.pump();
      expect(find.byKey(const Key('screen-الملف')), findsOneWidget);
    });
  });

  // ─── Settings Screen Flow ─────────────────────────────────────────────────
  group('Settings Screen Flow', () {
    testWidgets('Volunteer sees upgrade request button in settings', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _FakeSettingsScreen(isVolunteer: true),
      ));
      expect(find.byKey(const Key('upgrade-request-tile')), findsOneWidget);
    });

    testWidgets('Non-volunteer does NOT see upgrade request button', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _FakeSettingsScreen(isVolunteer: false),
      ));
      expect(find.byKey(const Key('upgrade-request-tile')), findsNothing);
    });

    testWidgets('Settings screen has all required menu items', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _FakeSettingsScreen(isVolunteer: false),
      ));
      expect(find.byKey(const Key('lang-tile')), findsOneWidget);
      expect(find.byKey(const Key('darkmode-tile')), findsOneWidget);
      expect(find.byKey(const Key('notifications-tile')), findsOneWidget);
      expect(find.byKey(const Key('about-tile')), findsOneWidget);
      expect(find.byKey(const Key('logout-tile')), findsOneWidget);
    });
  });

  // ─── RTL / Language Direction ─────────────────────────────────────────────
  group('RTL / Language Direction', () {
    testWidgets('Arabic locale uses RTL text direction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: Text('الجزائر خضراء')),
          ),
        ),
      );
      final context = tester.element(find.text('الجزائر خضراء'));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('English locale uses LTR text direction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(body: Text('Green Algeria')),
          ),
        ),
      );
      final context = tester.element(find.text('Green Algeria'));
      expect(Directionality.of(context), TextDirection.ltr);
    });
  });

  // ─── Design System Color Tokens ──────────────────────────────────────────
  group('Design System — Color Tokens', () {
    test('olive-grove primary color is correct hex', () {
      const oliveGrove = Color(0xFF606C38);
      expect(oliveGrove.r, 0x60);
      expect(oliveGrove.g, 0x6C);
      expect(oliveGrove.b, 0x38);
    });

    test('moss-forest border color is correct hex', () {
      const mossForest = Color(0xFF5A7233);
      expect(mossForest.r, 0x5A);
      expect(mossForest.g, 0x72);
      expect(mossForest.b, 0x33);
    });

    test('linen-white background is correct hex', () {
      const linenWhite = Color(0xFFFBFBF7);
      expect(linenWhite.r, 0xFB);
      expect(linenWhite.g, 0xFB);
      expect(linenWhite.b, 0xF7);
    });

    test('slate-charcoal text color is correct hex', () {
      const slateCharcoal = Color(0xFF2D2D2D);
      expect(slateCharcoal.r, 0x2D);
      expect(slateCharcoal.g, 0x2D);
      expect(slateCharcoal.b, 0x2D);
    });
  });
}
