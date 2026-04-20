import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NocixApp());
}

// ─────────────────────────────────────────────
// BACKGROUND HELPER
// ─────────────────────────────────────────────
Widget buildBackground({required Widget child, double overlay = 0.52}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/FUNDO.png', fit: BoxFit.cover),
      Container(color: Colors.black.withOpacity(overlay)),
      child,
    ],
  );
}

// ─────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────
const String kServerEndpoint = '51.79.117.132:53';
const String kWgConfig = '''[Interface]
Address = 10.7.0.2/24
DNS = 1.1.1.1, 1.0.0.1
PrivateKey = IOc2iOHC1hvNfl6xhNP2Ogaf8TmsGoB6RCET0T1zoHU=

[Peer]
PublicKey = amKr8K29p+j7KPMzXB/Pl9Mco47DX4U9f2accFBWJxM=
PresharedKey = MlvLn22E2Hcodu+oYIjeq4qNhRipT93ihsFiOWhIxHg=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 51.79.117.132:53
PersistentKeepalive = 25
''';
const String kGameId = '6079651';

// ─────────────────────────────────────────────
// NATIVE CHANNEL
// ─────────────────────────────────────────────
const _channel = MethodChannel('nocix/launcher');

Future<void> _showVpnNotification() async {
  try {
    await _channel.invokeMethod('showNotification', {
      'title': 'NOCIX VPN • Connected',
      'body': 'Your connection is protected',
    });
  } catch (_) {}
}

Future<void> _cancelVpnNotification() async {
  try { await _channel.invokeMethod('cancelNotification'); } catch (_) {}
}

Future<void> _openUrl(String url) async {
  try { await _channel.invokeMethod('openUrl', {'url': url}); } catch (_) {}
}

/// Returns true if this is the very first launch (stored in native SharedPrefs)
Future<bool> _isFirstLaunch() async {
  try {
    final result = await _channel.invokeMethod<bool>('isFirstLaunch');
    return result ?? true;
  } catch (_) { return false; }
}

/// Marks first launch as done
Future<void> _markLaunched() async {
  try { await _channel.invokeMethod('markLaunched'); } catch (_) {}
}

/// Closes the app process
Future<void> _restartApp() async {
  try { await _channel.invokeMethod('restartApp'); } catch (_) {}
}

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────
class NocixApp extends StatelessWidget {
  const NocixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOCIX VPN',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
      ),
      home: const InitScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// INIT SCREEN
// First launch  → loads ads → shows restart popup → user taps
//                 "Restart Now" → app closes → user reopens → works
// Second launch → loads ads → shows success → goes to MainScreen
// ─────────────────────────────────────────────
class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _ringScale;

  String _statusText = 'Initializing...';
  bool _success = false;
  bool _adsReady = false;
  bool _interstitialReady = false;
  bool _navigated = false;
  bool _firstLaunch = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _ringScale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic)));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 0.85, curve: Curves.easeIn)));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 700), _startInit);
    // Hard timeout – never leave user stuck
    Timer(const Duration(seconds: 20), () => _proceed());
  }

  void _startInit() async {
    _firstLaunch = await _isFirstLaunch();
    if (mounted) setState(() => _statusText = 'Loading servers...');

    UnityAds.init(
      gameId: kGameId,
      testMode: false,
      onComplete: () {
        _adsReady = true;
        if (mounted) setState(() => _statusText = 'Almost ready...');
        _loadAd();
      },
      onFailed: (_, msg) {
        debugPrint('[Init] Ads failed: $msg');
        _proceed();
      },
    );
  }

  void _loadAd() {
    UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (_) {
        _interstitialReady = true;
        _proceed();
      },
      onFailed: (_, __, msg) {
        debugPrint('[Init] Ad load failed: $msg');
        _proceed();
      },
    );
  }

  void _proceed() {
    if (_navigated || !mounted) return;
    _navigated = true;

    setState(() {
      _success = true;
      _statusText = 'Everything is ready!';
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_firstLaunch) {
        // First launch: show the restart popup
        _showRestartDialog();
      } else {
        // Normal launch: go straight to main screen
        _goToMain();
      }
    });
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => MainScreen(
          adsReady: _adsReady,
          interstitialReady: _interstitialReady,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Beautiful restart dialog ──────────────
  void _showRestartDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: const Color(0xFFFF8C5A).withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8622A).withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated shield icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8622A), Color(0xFFFF8C5A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8622A).withOpacity(0.4),
                        blurRadius: 20, spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),
                const Text(
                  'You\'re all set! 🎉',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'NOCIX VPN is ready to protect you.\nTap the button below and reopen the app to start connecting securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Cute tip
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00C853).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded,
                          color: Color(0xFF00FF9D), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'This only happens once!',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF00FF9D).withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Restart button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
                      await _markLaunched();
                      await _restartApp();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8622A), Color(0xFFFF8C5A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE8622A).withOpacity(0.4),
                            blurRadius: 16, spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Restart Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBackground(
        overlay: 0.45,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 210, height: 210,
                  child: Stack(alignment: Alignment.center, children: [
                    Transform.scale(
                      scale: _ringScale.value,
                      child: Opacity(
                        opacity: ((_ringScale.value - 0.4) / 0.6).clamp(0.0, 1.0),
                        child: Container(
                          width: 190, height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFFF8C5A).withOpacity(0.4),
                                width: 2),
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _ringScale.value * 0.84,
                      child: Opacity(
                        opacity: ((_ringScale.value - 0.4) / 0.6).clamp(0.0, 0.5),
                        child: Container(
                          width: 155, height: 155,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFE8622A).withOpacity(0.3),
                                width: 1),
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE8622A), Color(0xFFFF8C5A)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.black54,
                            child: ClipOval(
                              child: Image.asset('assets/LOGO.png',
                                  width: 108, height: 108, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.shield,
                                      color: Color(0xFFFF8C5A), size: 64)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _textOpacity.value,
                  child: Column(children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                              colors: [Color(0xFFFF8C5A), Color(0xFFFFD580)])
                          .createShader(b),
                      child: const Text('NOCIX',
                          style: TextStyle(
                              fontSize: 38, fontWeight: FontWeight.w900,
                              letterSpacing: 14, color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    const Text('SECURE VPN',
                        style: TextStyle(
                            fontSize: 11, letterSpacing: 5,
                            color: Colors.white54)),
                  ]),
                ),
                const SizedBox(height: 48),
                Opacity(
                  opacity: _textOpacity.value,
                  child: Column(children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Row(
                        key: ValueKey(_statusText),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_success)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF00FF9D), size: 16)
                          else
                            const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: Color(0xFFFF8C5A), strokeWidth: 2),
                            ),
                          const SizedBox(width: 8),
                          Text(_statusText,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _success
                                      ? const Color(0xFF00FF9D)
                                      : Colors.white54,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: _success ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 400),
                      child: SizedBox(
                        width: 140,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE8622A)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VPN PERMISSION SCREEN  (shown before Android dialog)
// ─────────────────────────────────────────────
class VpnPermissionScreen extends StatelessWidget {
  final VoidCallback onAllow;
  const VpnPermissionScreen({super.key, required this.onAllow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBackground(
        overlay: 0.55,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                // Shield icon
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8622A), Color(0xFFFF8C5A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8622A).withOpacity(0.45),
                        blurRadius: 30, spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Allow VPN Access',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'NOCIX needs permission to create a VPN connection on your device. This keeps your data safe and your browsing private.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.65),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                // Feature list
                _permissionFeature(
                  Icons.lock_rounded,
                  'End-to-end encrypted',
                  'All your traffic is secured with AES-256',
                ),
                const SizedBox(height: 14),
                _permissionFeature(
                  Icons.visibility_off_rounded,
                  'No logs, ever',
                  'We never store or sell your data',
                ),
                const SizedBox(height: 14),
                _permissionFeature(
                  Icons.flash_on_rounded,
                  'Lightning fast',
                  'WireGuard protocol for max speed',
                ),
                const Spacer(),
                // Allow button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onAllow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8622A), Color(0xFFFF8C5A)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE8622A).withOpacity(0.45),
                            blurRadius: 20, spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Allow & Protect Me',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Not now',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _permissionFeature(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8622A).withOpacity(0.12),
            border: Border.all(
                color: const Color(0xFFE8622A).withOpacity(0.25)),
          ),
          child: Icon(icon, color: const Color(0xFFFF8C5A), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, color: Colors.white)),
              Text(sub,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45))),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  final bool adsReady;
  final bool interstitialReady;
  const MainScreen({
    super.key,
    required this.adsReady,
    required this.interstitialReady,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final _wireguard = WireGuardFlutter.instance;
  VpnStage _stage = VpnStage.disconnected;
  StreamSubscription? _stageSub;

  late bool _adsReady;
  late bool _interstitialReady;
  bool _connecting = false;
  bool _loadingAd = false;
  bool _permissionShown = false;

  String _sessionTime = '00:00:00';
  DateTime? _connectedAt;
  Timer? _clockTimer;

  late Future<void> _initFuture;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _adsReady = widget.adsReady;
    _interstitialReady = widget.interstitialReady;

    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initFuture = _initVpn();
    if (_adsReady && !_interstitialReady) _loadInterstitial();
  }

  // ─────────────────────────────────────────
  // VPN
  // ─────────────────────────────────────────
  Future<void> _initVpn() async {
    await _wireguard.initialize(interfaceName: 'nocix0');
    await _stageSub?.cancel();
    _stageSub = _wireguard.vpnStageSnapshot.listen((stage) {
      if (!mounted) return;
      setState(() {
        _stage = stage;
        if (stage == VpnStage.connected || stage == VpnStage.disconnected) {
          _connecting = false;
        }
      });
      if (stage == VpnStage.connected) {
        _connectedAt = DateTime.now();
        _startClock();
        _showVpnNotification();
      } else if (stage == VpnStage.disconnected) {
        _stopClock();
        setState(() => _sessionTime = '00:00:00');
        _cancelVpnNotification();
      }
    });
  }

  Future<void> _connect() async {
    await _initFuture; // always wait for initialize to finish
    await _wireguard.startVpn(
      serverAddress: kServerEndpoint,
      wgQuickConfig: kWgConfig,
      providerBundleIdentifier: 'com.jinoca.vpn',
    );
    // Safety: release lock after 25 s if WireGuard never fires
    Timer(const Duration(seconds: 25), () {
      if (mounted && _connecting) setState(() => _connecting = false);
    });
  }

  Future<void> _disconnect() async => _wireguard.stopVpn();

  // ─────────────────────────────────────────
  // ADS
  // ─────────────────────────────────────────
  void _loadInterstitial() {
    if (!_adsReady) return;
    UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (_) {
        if (mounted) setState(() => _interstitialReady = true);
      },
      onFailed: (_, __, msg) {
        if (mounted) setState(() => _interstitialReady = false);
      },
    );
  }

  // ─────────────────────────────────────────
  // CONNECT FLOW
  // Shows our custom permission screen first,
  // then shows ad, then connects.
  // ─────────────────────────────────────────
  void _onConnectTapped() {
    if (_connecting) return;
    if (!_permissionShown) {
      // Show our beautiful permission screen before anything else
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => VpnPermissionScreen(
            onAllow: () {
              Navigator.of(context).pop();
              _permissionShown = true;
              _startAdFlow();
            },
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      );
    } else {
      _startAdFlow();
    }
  }

  void _startAdFlow() {
    setState(() { _connecting = true; _loadingAd = true; });
    if (_interstitialReady) {
      _showInterstitial();
    } else {
      debugPrint('[Ads] Ad not ready – connecting directly');
      _afterAd();
    }
  }

  void _showInterstitial() {
    UnityAds.showVideoAd(
      placementId: 'Interstitial_Android',
      onComplete: (_) { if (mounted) _afterAd(); },
      onFailed: (_, __, ___) { if (mounted) _afterAd(); },
      onSkipped: (_) { if (mounted) _afterAd(); },
    );
  }

  Future<void> _afterAd() async {
    setState(() { _loadingAd = false; _interstitialReady = false; });
    _loadInterstitial();
    await _connect();
  }

  // ─────────────────────────────────────────
  bool get _isConnected => _stage == VpnStage.connected;
  bool get _isVpnBusy =>
      _stage != VpnStage.connected && _stage != VpnStage.disconnected;
  bool get _isBusy => _connecting || _isVpnBusy;

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null || !mounted) return;
      final d = DateTime.now().difference(_connectedAt!);
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      setState(() => _sessionTime = '$h:$m:$s');
    });
  }

  void _stopClock() { _clockTimer?.cancel(); _clockTimer = null; }

  @override
  void dispose() {
    _stageSub?.cancel();
    _pulseCtrl.dispose();
    _stopClock();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: buildBackground(
        overlay: 0.50,
        child: SafeArea(
          child: Column(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  const SizedBox(height: 16),
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildInfoCard(),
                  const Spacer(),
                  _buildConnectButton(),
                  const SizedBox(height: 20),
                  _buildFeatureRow(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
            UnityBannerAd(
              placementId: 'Banner_Android',
              onLoad: (_) {},
              onClick: (_) {},
              onFailed: (_, __, ___) {},
            ),
          ]),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent, elevation: 0,
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isConnected
                ? const Color(0xFF00FF9D)
                : _isBusy ? Colors.orange : Colors.redAccent,
          ),
        ),
        const SizedBox(width: 8),
        Text(_statusLabel,
            style: const TextStyle(
                fontSize: 12, letterSpacing: 2, color: Colors.white70)),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onPressed: _showSettingsMenu,
        ),
      ],
    );
  }

  String get _statusLabel {
    if (_loadingAd) return 'LOADING AD...';
    if (_isConnected) return 'CONNECTED';
    if (_isBusy) return 'CONNECTING...';
    return 'NOT CONNECTED';
  }

  Widget _buildLogo() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [Color(0xFFE8622A), Color(0xFFFF8C5A)]),
        ),
        child: CircleAvatar(
          radius: 50, backgroundColor: Colors.black54,
          child: ClipOval(
            child: Image.asset('assets/LOGO.png',
                width: 92, height: 92, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.shield,
                    color: Color(0xFFFF8C5A), size: 52)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFF8C5A), Color(0xFFFFD580)])
            .createShader(b),
        child: const Text('NOCIX',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                letterSpacing: 12, color: Colors.white)),
      ),
      const Text('SECURE VPN',
          style: TextStyle(fontSize: 10, letterSpacing: 4,
              color: Colors.white38)),
    ]);
  }

  Widget _buildInfoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.40),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isConnected
              ? const Color(0xFF00C853).withOpacity(0.5)
              : const Color(0xFFE8622A).withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8622A).withOpacity(0.15),
              border: Border.all(
                  color: const Color(0xFFE8622A).withOpacity(0.3)),
            ),
            child: const Icon(Icons.language,
                color: Color(0xFFFF8C5A), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Server',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: Colors.white)),
                SizedBox(height: 3),
                Text('Best available location',
                    style: TextStyle(fontSize: 11, color: Colors.white38)),
              ]),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isConnected
                ? const Icon(Icons.lock_rounded,
                    key: ValueKey('locked'),
                    color: Color(0xFF00FF9D), size: 24)
                : const Icon(Icons.lock_open_rounded,
                    key: ValueKey('unlocked'),
                    color: Colors.white24, size: 24),
          ),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: _isConnected
              ? Column(children: [
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoChip(Icons.timer_outlined, 'SESSION',
                          _sessionTime, const Color(0xFF00FF9D)),
                      _infoChip(Icons.shield_outlined, 'STATUS',
                          'Protected', const Color(0xFF7BA7FF)),
                      _infoChip(Icons.lock_rounded, 'ENCRYPTED',
                          'AES-256', const Color(0xFFFF8C5A)),
                    ],
                  ),
                ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(fontSize: 9, letterSpacing: 1,
              color: Colors.white38)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
              color: color)),
    ]);
  }

  Widget _buildConnectButton() {
    String label;
    if (_loadingAd) label = 'LOADING AD...';
    else if (_isConnected) label = 'DISCONNECT';
    else if (_isBusy) label = 'CONNECTING...';
    else label = 'TAP TO CONNECT';

    final Color labelColor = _isConnected
        ? const Color(0xFF00FF9D)
        : _isBusy ? Colors.orange : Colors.white70;

    return Column(children: [
      GestureDetector(
        onTap: _isBusy ? null
            : () => _isConnected ? _disconnect() : _onConnectTapped(),
        child: ScaleTransition(
          scale: (!_isConnected && !_isBusy)
              ? _pulseAnim : kAlwaysCompleteAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 148, height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: _isConnected
                    ? [const Color(0xFF00C853), const Color(0xFF00897B)]
                    : _isBusy
                        ? [Colors.orange.shade700, Colors.orange.shade900]
                        : [const Color(0xFFE8622A), const Color(0xFF7B2D00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isConnected
                      ? const Color(0xFF00C853)
                      : _isBusy ? Colors.orange
                          : const Color(0xFFE8622A)).withOpacity(0.5),
                  blurRadius: 40, spreadRadius: 6,
                ),
              ],
            ),
            child: _isBusy
                ? const Center(child: SizedBox(width: 48, height: 48,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3)))
                : const Icon(Icons.power_settings_new_rounded,
                    size: 64, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
          letterSpacing: 2, color: labelColor)),
    ]);
  }

  Widget _buildFeatureRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _featurePill(Icons.flash_on, 'Fast'),
        _featurePill(Icons.security, 'Encrypted'),
        _featurePill(Icons.visibility_off, 'No Logs'),
      ],
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFFFF8C5A)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12,
            color: Colors.white70, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('SETTINGS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  letterSpacing: 3, color: Colors.white54)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined,
                color: Color(0xFFFF8C5A)),
            title: const Text('Import .conf File'),
            onTap: () { Navigator.pop(ctx); _importConfig(); },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: Color(0xFFFF8C5A)),
            title: const Text('Privacy Policy & Terms'),
            onTap: () {
              Navigator.pop(ctx);
              _openUrl('https://www.jinoca.com/demo.html');
            },
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Future<void> _importConfig() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['conf']);
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Config imported – reconnect to apply.'),
      backgroundColor: Color(0xFF1A1A2E),
    ));
  }
}
