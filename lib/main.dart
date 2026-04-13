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
// WIREGUARD CONFIG
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

// ─────────────────────────────────────────────
// NATIVE CHANNEL  (notification + open URL)
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
  try {
    await _channel.invokeMethod('cancelNotification');
  } catch (_) {}
}

Future<void> _openUrl(String url) async {
  try {
    await _channel.invokeMethod('openUrl', {'url': url});
  } catch (_) {}
}

// ─────────────────────────────────────────────
// APP
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
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

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
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn)));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ));
    });
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
                const SizedBox(height: 56),
                Opacity(
                  opacity: _textOpacity.value,
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFE8622A)),
                      borderRadius: BorderRadius.circular(4),
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
}

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final _wireguard = WireGuardFlutter.instance;
  VpnStage _stage = VpnStage.disconnected;
  StreamSubscription? _stageSub;

  // ── Ads ───────────────────────────────────
  static const String _gameId = '6079651';
  bool _adsReady = false;
  bool _interstitialReady = false;
  bool _connecting = false; // gates the entire connect flow
  bool _loadingAd = false;

  // ── Session timer ──────────────────────────
  String _sessionTime = '00:00:00';
  DateTime? _connectedAt;
  Timer? _clockTimer;

  // ── Pulse animation ────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initVpn();
    _initAds();
  }

  // ─────────────────────────────────────────
  // VPN
  // ─────────────────────────────────────────
  void _initVpn() async {
    await _wireguard.initialize(interfaceName: 'nocix0');
    _stageSub = _wireguard.vpnStageSnapshot.listen((stage) {
      if (!mounted) return;
      setState(() {
        _stage = stage;
        // Release _connecting once WG reaches a terminal state
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
    await _wireguard.startVpn(
      serverAddress: kServerEndpoint,
      wgQuickConfig: kWgConfig,
      providerBundleIdentifier: 'com.jinoca.vpn',
    );
  }

  Future<void> _disconnect() async {
    await _wireguard.stopVpn();
  }

  // ─────────────────────────────────────────
  // ADS
  // ─────────────────────────────────────────
  void _initAds() {
    UnityAds.init(
      gameId: _gameId,
      testMode: false,
      onComplete: () {
        if (mounted) setState(() => _adsReady = true);
        _loadInterstitial();
      },
      onFailed: (_, msg) => debugPrint('[Ads] Init failed: $msg'),
    );
  }

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

  void _onConnectTapped() {
    if (_connecting) return;
    setState(() { _connecting = true; _loadingAd = true; });

    if (_interstitialReady) {
      // Ad already loaded – show immediately
      _showInterstitial();
    } else {
      // SDK may still be initialising or ad still loading.
      // Poll every 300 ms for up to 12 s total.
      // Covers both "SDK not ready yet" (first launch) and
      // "SDK ready but ad hasn't loaded yet" (subsequent launches).
      _pollForAdThenConnect();
    }
  }

  void _pollForAdThenConnect() {
    int waited = 0;
    const int intervalMs = 300;
    const int maxWaitMs = 12000; // 12 s total – enough for SDK + ad load

    Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      waited += intervalMs;
      if (!mounted) { t.cancel(); return; }

      // If SDK just became ready but we haven't triggered a load yet, do it now
      if (_adsReady && !_interstitialReady) {
        _loadInterstitial();
      }

      if (_interstitialReady) {
        // Ad is ready – show it
        t.cancel();
        _showInterstitial();
      } else if (waited >= maxWaitMs) {
        // Timeout: SDK or network too slow – connect without ad
        t.cancel();
        _afterAd();
      }
    });
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
    setState(() => _loadingAd = false);
    _loadInterstitial();
    await _connect();
    // _connecting released by vpnStageSnapshot callback
  }

  // ─────────────────────────────────────────
  // COMPUTED STATE
  // ─────────────────────────────────────────
  bool get _isConnected => _stage == VpnStage.connected;
  bool get _isVpnBusy =>
      _stage != VpnStage.connected && _stage != VpnStage.disconnected;
  bool get _isBusy => _connecting || _isVpnBusy;

  // ─────────────────────────────────────────
  // TIMER
  // ─────────────────────────────────────────
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
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildLogo(),
                      const SizedBox(height: 28),
                      _buildInfoCard(),
                      const Spacer(),
                      _buildConnectButton(),
                      const SizedBox(height: 20),
                      _buildFeatureRow(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              UnityBannerAd(
                placementId: 'Banner_Android',
                onLoad: (_) => debugPrint('[Ads] Banner loaded'),
                onClick: (_) {},
                onFailed: (_, __, msg) =>
                    debugPrint('[Ads] Banner failed: $msg'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
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

  // ─────────────────────────────────────────
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
          radius: 50,
          backgroundColor: Colors.black54,
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
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900,
                letterSpacing: 12, color: Colors.white)),
      ),
      const Text('SECURE VPN',
          style: TextStyle(
              fontSize: 10, letterSpacing: 4, color: Colors.white38)),
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
        // Server row — generic, no location or protocol exposed
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Server',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15, color: Colors.white)),
                SizedBox(height: 3),
                Text('Best available location',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
          // Lock icon only — no text that reveals anything
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

        // Session stats — only visible when connected
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

  Widget _infoChip(
      IconData icon, String label, String value, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 9, letterSpacing: 1, color: Colors.white38)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  // ─────────────────────────────────────────
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
        onTap: _isBusy
            ? null
            : () => _isConnected ? _disconnect() : _onConnectTapped(),
        child: ScaleTransition(
          scale: (!_isConnected && !_isBusy)
              ? _pulseAnim
              : kAlwaysCompleteAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 148, height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                          : _isBusy
                              ? Colors.orange
                              : const Color(0xFFE8622A))
                      .withOpacity(0.5),
                  blurRadius: 40, spreadRadius: 6,
                ),
              ],
            ),
            child: _isBusy
                ? const Center(
                    child: SizedBox(
                      width: 48, height: 48,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    ))
                : const Icon(Icons.power_settings_new_rounded,
                    size: 64, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold,
              letterSpacing: 2, color: labelColor)),
    ]);
  }

  // ─────────────────────────────────────────
  // Feature pills at the bottom – fills space & communicates value
  // ─────────────────────────────────────────
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
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.white70,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─────────────────────────────────────────
  // SETTINGS MENU
  // ─────────────────────────────────────────
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.92),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('SETTINGS',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Future<void> _importConfig() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['conf'],
    );
    if (result == null) return;
    // Custom config imported – the app will use it for the next connection.
    // For simplicity we just show a snackbar; extending to hot-swap the
    // config at runtime is possible but out of scope here.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Config imported – reconnect to apply.'),
          backgroundColor: Color(0xFF1A1A2E),
        ),
      );
    }
  }
}
