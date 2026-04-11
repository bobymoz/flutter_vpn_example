import 'package:flutter/material.dart';
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
// Wraps any widget with assets/FUNDO.png + dark overlay
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
// SERVER MODEL
// ─────────────────────────────────────────────
class VpnServer {
  final String name;
  final String flagEmoji;
  final String endpoint; // used internally only – never shown to user
  final String config;

  const VpnServer({
    required this.name,
    required this.flagEmoji,
    required this.endpoint,
    required this.config,
  });
}

// ─────────────────────────────────────────────
// SERVER LIST  — add more servers here
// ─────────────────────────────────────────────
final List<VpnServer> kServers = [
  VpnServer(
    name: 'United States',
    flagEmoji: '🇺🇸',
    endpoint: '51.79.117.132:53',
    config: '''[Interface]
Address = 10.7.0.2/24
DNS = 1.1.1.1, 1.0.0.1
PrivateKey = IOc2iOHC1hvNfl6xhNP2Ogaf8TmsGoB6RCET0T1zoHU=

[Peer]
PublicKey = amKr8K29p+j7KPMzXB/Pl9Mco47DX4U9f2accFBWJxM=
PresharedKey = MlvLn22E2Hcodu+oYIjeq4qNhRipT93ihsFiOWhIxHg=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 51.79.117.132:53
PersistentKeepalive = 25
''',
  ),
  // VpnServer(
  //   name: 'Germany',
  //   flagEmoji: '🇩🇪',
  //   endpoint: 'HOST:PORT',
  //   config: '''...''',
  // ),
];

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
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// SPLASH SCREEN
// Same FUNDO.png background so colors are consistent
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
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _ringScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.55, 0.85, curve: Curves.easeIn)),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
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
                // ── Logo + rings ──────────────
                SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Transform.scale(
                        scale: _ringScale.value,
                        child: Opacity(
                          opacity: ((_ringScale.value - 0.4) / 0.6)
                              .clamp(0.0, 1.0),
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF8C5A).withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Inner ring
                      Transform.scale(
                        scale: _ringScale.value * 0.84,
                        child: Opacity(
                          opacity: ((_ringScale.value - 0.4) / 0.6)
                              .clamp(0.0, 0.5),
                          child: Container(
                            width: 155,
                            height: 155,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE8622A).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Logo
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE8622A),
                                  Color(0xFFFF8C5A),
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 58,
                              backgroundColor: Colors.black.withOpacity(0.55),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/LOGO.png',
                                  width: 108,
                                  height: 108,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.shield,
                                    color: Color(0xFFFF8C5A),
                                    size: 64,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // ── Brand text ────────────────
                Opacity(
                  opacity: _textOpacity.value,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFF8C5A), Color(0xFFFFD580)],
                        ).createShader(b),
                        child: const Text(
                          'NOCIX',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SECURE VPN',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 5,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 56),
                // ── Progress bar ──────────────
                Opacity(
                  opacity: _textOpacity.value,
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE8622A),
                      ),
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
  // ── WireGuard ──────────────────────────────
  final _wireguard = WireGuardFlutter.instance;
  VpnStage _stage = VpnStage.disconnected;
  StreamSubscription? _stageSub;

  // ── Selected server ────────────────────────
  VpnServer _selectedServer = kServers.first;

  // ── Unity Ads ─────────────────────────────
  static const String _gameId = '6079651';
  bool _adsReady = false;
  bool _interstitialReady = false;

  /// True while the entire ad-load→show flow is running
  bool _adFlowRunning = false;

  /// True while we are waiting for the ad to load (shows "LOADING AD...")
  bool _loadingAd = false;

  // ── Session timer ──────────────────────────
  String _sessionTime = '00:00:00';
  DateTime? _connectedAt;
  Timer? _clockTimer;

  // ── Pulse animation ────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _initVpn();
    _initAds();
  }

  // ── VPN ───────────────────────────────────
  void _initVpn() async {
    await _wireguard.initialize(interfaceName: 'nocix0');
    _stageSub = _wireguard.vpnStageSnapshot.listen(_onStageChange);
  }

  void _onStageChange(VpnStage stage) {
    if (!mounted) return;
    setState(() => _stage = stage);
    if (stage == VpnStage.connected) {
      _connectedAt = DateTime.now();
      _startClock();
    } else {
      _stopClock();
      if (stage == VpnStage.disconnected) {
        setState(() => _sessionTime = '00:00:00');
      }
    }
  }

  void _connectVpn() async {
    await _wireguard.startVpn(
      serverAddress: _selectedServer.endpoint,
      wgQuickConfig: _selectedServer.config,
      providerBundleIdentifier: 'com.jinoca.vpn',
    );
  }

  void _disconnectVpn() async {
    await _wireguard.stopVpn();
  }

  // ── Session clock ─────────────────────────
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

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  // ── Ads ───────────────────────────────────
  void _initAds() {
    UnityAds.init(
      gameId: _gameId,
      testMode: false,
      onComplete: () {
        debugPrint('[Ads] SDK ready');
        if (mounted) setState(() => _adsReady = true);
        _loadInterstitial(); // pre-load immediately
      },
      onFailed: (error, msg) => debugPrint('[Ads] Init failed: $msg'),
    );
  }

  void _loadInterstitial() {
    if (!_adsReady) return;
    setState(() => _interstitialReady = false);
    UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (id) {
        debugPrint('[Ads] Interstitial ready');
        if (mounted) setState(() => _interstitialReady = true);
      },
      onFailed: (id, error, msg) {
        debugPrint('[Ads] Interstitial failed: $msg');
        if (mounted) setState(() => _interstitialReady = false);
      },
    );
  }

  // ── Ad connect flow ───────────────────────
  // ALWAYS shows: "LOADING AD..." spinner → ad plays → VPN connects
  // Never silently skips. On every connect tap, every time.
  void _onConnectTapped() {
    if (_adFlowRunning) return;
    setState(() {
      _adFlowRunning = true;
      _loadingAd = true;
    });

    if (_interstitialReady) {
      _showInterstitial();
    } else {
      _waitForAdThenShow();
    }
  }

  /// Polls every 300 ms until ad is ready (max 8 s), then shows it.
  void _waitForAdThenShow() {
    // Trigger a fresh load attempt in case SDK is ready
    _loadInterstitial();

    int waited = 0;
    const int intervalMs = 300;
    const int maxWaitMs = 8000;

    Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      waited += intervalMs;
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_interstitialReady) {
        t.cancel();
        _showInterstitial();
      } else if (waited >= maxWaitMs) {
        t.cancel();
        // Timed out – connect anyway so user is never stuck
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

  void _afterAd() {
    setState(() {
      _loadingAd = false;
      _adFlowRunning = false;
    });
    _connectVpn();
    // Immediately start loading the next ad for the next connection
    _loadInterstitial();
  }

  // ── Server picker ─────────────────────────
  void _openServerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.90),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SELECT SERVER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kServers.length,
              itemBuilder: (_, i) {
                final s = kServers[i];
                final sel = s == _selectedServer;
                return ListTile(
                  leading: Text(s.flagEmoji,
                      style: const TextStyle(fontSize: 30)),
                  title: Text(
                    s.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: sel ? const Color(0xFFFF8C5A) : Colors.white,
                    ),
                  ),
                  // Endpoint / IP intentionally not shown
                  trailing: sel
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFFFF8C5A))
                      : null,
                  onTap: () {
                    setState(() => _selectedServer = s);
                    Navigator.pop(ctx);
                    if (_stage == VpnStage.connected) _disconnectVpn();
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Import custom config ───────────────────
  Future<void> _importConfig() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['conf'],
    );
    if (result != null) {
      final content =
          await File(result.files.single.path!).readAsString();
      setState(() {
        _selectedServer = VpnServer(
          name: 'Custom Server',
          flagEmoji: '🌐',
          endpoint: 'custom',
          config: content,
        );
      });
    }
  }

  // ─────────────────────────────────────────
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
    final bool isConnected = _stage == VpnStage.connected;
    final bool isVpnBusy =
        _stage != VpnStage.connected && _stage != VpnStage.disconnected;
    final bool isBusy = isVpnBusy || _adFlowRunning;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isConnected),
      body: buildBackground(
        overlay: 0.52,
        child: SafeArea(
          child: Column(
            children: [
              // ── Content ───────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildLogo(),
                        const SizedBox(height: 24),
                        _buildServerCard(),
                        const SizedBox(height: 40),
                        _buildConnectButton(isConnected, isBusy),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Banner Ad ─────────────────
              // Always rendered; Unity SDK controls its own visibility.
              UnityBannerAd(
                placementId: 'Banner_Android',
                onLoad: (id) => debugPrint('[Ads] Banner loaded: $id'),
                onClick: (id) {},
                onFailed: (id, error, msg) =>
                    debugPrint('[Ads] Banner failed: $msg'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isConnected) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected
                  ? const Color(0xFF00FF9D)
                  : _stage == VpnStage.disconnected
                      ? Colors.redAccent
                      : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _statusLabel,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Colors.white70,
            ),
          ),
        ],
      ),
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
    switch (_stage) {
      case VpnStage.connected:
        return 'CONNECTED';
      case VpnStage.disconnected:
        return 'NOT CONNECTED';
      default:
        return 'CONNECTING...';
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE8622A), Color(0xFFFF8C5A)],
            ),
          ),
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.black54,
            child: ClipOval(
              child: Image.asset(
                'assets/LOGO.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shield,
                  color: Color(0xFFFF8C5A),
                  size: 56,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFF8C5A), Color(0xFFFFD580)],
          ).createShader(b),
          child: const Text(
            'NOCIX',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
              color: Colors.white,
            ),
          ),
        ),
        const Text(
          'SECURE VPN',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildServerCard() {
    final bool canPick =
        _stage == VpnStage.disconnected && !_adFlowRunning;
    return GestureDetector(
      onTap: canPick ? _openServerPicker : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8622A).withOpacity(0.45),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              _selectedServer.flagEmoji,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _selectedServer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
            if (canPick)
              const Icon(Icons.chevron_right, color: Color(0xFFFF8C5A)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton(bool isConnected, bool isBusy) {
    String label;
    if (_loadingAd) {
      label = 'LOADING AD...';
    } else if (isConnected) {
      label = 'DISCONNECT';
    } else if (isBusy) {
      label = 'CONNECTING...';
    } else {
      label = 'TAP TO CONNECT';
    }

    final Color labelColor = isConnected
        ? const Color(0xFF00FF9D)
        : isBusy
            ? Colors.orange
            : Colors.white70;

    return Column(
      children: [
        GestureDetector(
          onTap: isBusy
              ? null
              : () => isConnected ? _disconnectVpn() : _onConnectTapped(),
          child: ScaleTransition(
            scale: (!isConnected && !isBusy)
                ? _pulseAnim
                : kAlwaysCompleteAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isConnected
                      ? [const Color(0xFF00C853), const Color(0xFF00897B)]
                      : isBusy
                          ? [Colors.orange.shade700, Colors.orange.shade900]
                          : [const Color(0xFFE8622A), const Color(0xFF7B2D00)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isConnected
                            ? const Color(0xFF00C853)
                            : isBusy
                                ? Colors.orange
                                : const Color(0xFFE8622A))
                        .withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: isBusy
                  ? const Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.power_settings_new_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: labelColor,
          ),
        ),
        // Session timer – only visible when connected
        if (isConnected) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00C853).withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    color: Color(0xFF00FF9D), size: 16),
                const SizedBox(width: 8),
                Text(
                  _sessionTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FF9D),
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.90),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.dns_outlined,
                  color: Color(0xFFFF8C5A)),
              title: const Text('Select Server'),
              onTap: () {
                Navigator.pop(ctx);
                _openServerPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined,
                  color: Color(0xFFFF8C5A)),
              title: const Text('Import .conf File'),
              onTap: () {
                Navigator.pop(ctx);
                _importConfig();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
