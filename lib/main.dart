import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
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
// PROTOCOL ENUM
// ─────────────────────────────────────────────
enum VpnProtocol { wireguard, openvpn }

// ─────────────────────────────────────────────
// SERVER MODEL
// ─────────────────────────────────────────────
class VpnServer {
  final String name;
  final String countryCode;
  final String flagEmoji;
  final VpnProtocol protocol;
  final String endpoint;
  final String config;
  final int ping;
  final int speedBps;

  const VpnServer({
    required this.name,
    required this.countryCode,
    required this.flagEmoji,
    required this.protocol,
    required this.config,
    this.endpoint = '',
    this.ping = 0,
    this.speedBps = 0,
  });

  String get speedLabel {
    if (speedBps == 0) return '';
    if (speedBps >= 1000000) {
      return '${(speedBps / 1000000).toStringAsFixed(0)} Mbps';
    }
    return '${(speedBps / 1000).toStringAsFixed(0)} Kbps';
  }

  String get pingLabel => ping > 0 ? '${ping}ms' : '';
}

// ─────────────────────────────────────────────
// FLAG EMOJI HELPER
// ─────────────────────────────────────────────
String countryCodeToEmoji(String code) {
  if (code.length != 2) return '🌐';
  final c = code.toUpperCase();
  final first = 0x1F1E6 + (c.codeUnitAt(0) - 65);
  final second = 0x1F1E6 + (c.codeUnitAt(1) - 65);
  return String.fromCharCode(first) + String.fromCharCode(second);
}

// ─────────────────────────────────────────────
// YOUR WIREGUARD SERVER
// ─────────────────────────────────────────────
final VpnServer kMyServer = VpnServer(
  name: 'United States',
  countryCode: 'US',
  flagEmoji: '🇺🇸',
  protocol: VpnProtocol.wireguard,
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
);

// ─────────────────────────────────────────────
// VPN GATE FETCHER
// ─────────────────────────────────────────────
class VpnGateFetcher {
  static const String _apiUrl = 'https://www.vpngate.net/api/iphone/';

  static Future<List<VpnServer>> fetch() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final lines = const LineSplitter().convert(response.body);
      final servers = <VpnServer>[];

      for (final line in lines) {
        if (line.startsWith('#') ||
            line.startsWith('*') ||
            line.trim().isEmpty) continue;

        final cols = line.split(',');
        if (cols.length < 15) continue;

        final countryCode = cols[6].trim().toUpperCase();
        final ping = int.tryParse(cols[3].trim()) ?? 0;
        final speed = int.tryParse(cols[4].trim()) ?? 0;
        final ovpnBase64 = cols[14].trim();
        final countryLong = cols[5].trim();

        // Skip offline servers (ping = 0 means no response)
        if (ovpnBase64.isEmpty || ping == 0) continue;

        String ovpnConfig;
        try {
          ovpnConfig = utf8.decode(base64.decode(ovpnBase64));
        } catch (_) {
          continue;
        }

        servers.add(VpnServer(
          name: countryLong.isNotEmpty ? countryLong : countryCode,
          countryCode: countryCode,
          flagEmoji: countryCodeToEmoji(countryCode),
          protocol: VpnProtocol.openvpn,
          config: ovpnConfig,
          ping: ping,
          speedBps: speed,
        ));
      }

      servers.sort((a, b) => b.speedBps.compareTo(a.speedBps));
      return servers.take(30).toList();
    } catch (e) {
      debugPrint('[VpnGate] Fetch error: $e');
      return [];
    }
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION CHANNEL  (no extra dependency)
// Uses MainActivity.kt MethodChannel
// ─────────────────────────────────────────────
const _notifChannel = MethodChannel('nocix/launcher');

Future<void> _showVpnNotification(String serverName) async {
  try {
    await _notifChannel.invokeMethod('showNotification', {
      'title': 'NOCIX VPN Connected',
      'body': 'Protected via $serverName',
    });
  } catch (_) {}
}

Future<void> _cancelVpnNotification() async {
  try {
    await _notifChannel.invokeMethod('cancelNotification');
  } catch (_) {}
}

Future<void> _openUrl(String url) async {
  try {
    await _notifChannel.invokeMethod('openUrl', {'url': url});
  } catch (_) {}
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
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
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
                                  color:
                                      const Color(0xFFFF8C5A).withOpacity(0.4),
                                  width: 2),
                            ),
                          ),
                        ),
                      ),
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
                                  color:
                                      const Color(0xFFE8622A).withOpacity(0.3),
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
                                colors: [
                                  Color(0xFFE8622A),
                                  Color(0xFFFF8C5A)
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 58,
                              backgroundColor: Colors.black54,
                              child: ClipOval(
                                child: Image.asset('assets/LOGO.png',
                                    width: 108,
                                    height: 108,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.shield,
                                        color: Color(0xFFFF8C5A),
                                        size: 64)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 14,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    const Text('SECURE VPN',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 5,
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
  // ── WireGuard ──────────────────────────────
  final _wireguard = WireGuardFlutter.instance;
  VpnStage _wgStage = VpnStage.disconnected;
  StreamSubscription? _wgSub;

  // ── OpenVPN ────────────────────────────────
  // FIX 3: Initialized early so the engine is warm when user connects
  late OpenVPN _openVpn;
  VPNStage _ovpnStage = VPNStage.disconnected;
  // Tracks whether OpenVPN permission request is pending (Android)
  bool _ovpnRequestingPermission = false;

  // ── Selected server ────────────────────────
  VpnServer _selectedServer = kMyServer;

  // ── VPN Gate servers ───────────────────────
  // FIX 1: ValueNotifier so picker rebuilds automatically
  final ValueNotifier<List<VpnServer>> _serversNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _fetchedNotifier = ValueNotifier(false);

  // ── Unity Ads ─────────────────────────────
  static const String _gameId = '6079651';
  bool _adsReady = false;
  bool _interstitialReady = false;
  // FIX 2: Single flag that gates the entire flow
  bool _connecting = false;
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

    _initWireGuard();
    _initOpenVpn(); // FIX 3: warm up engine immediately
    _initAds();
    _fetchVpnGateServers(); // starts in background on app open
  }

  // ─────────────────────────────────────────
  // WIREGUARD
  // ─────────────────────────────────────────
  void _initWireGuard() async {
    await _wireguard.initialize(interfaceName: 'nocix0');
    _wgSub = _wireguard.vpnStageSnapshot.listen((stage) {
      if (!mounted) return;
      setState(() => _wgStage = stage);
      if (stage == VpnStage.connected) {
        _connectedAt = DateTime.now();
        _startClock();
        _showVpnNotification(_selectedServer.name);
      } else if (stage == VpnStage.disconnected) {
        _stopClock();
        setState(() => _sessionTime = '00:00:00');
        _cancelVpnNotification();
      }
    });
  }

  // ─────────────────────────────────────────
  // OPENVPN
  // FIX 3: Initialize as soon as MainScreen mounts so the VPN
  // permission dialog is pre-cached and connection is instant.
  // ─────────────────────────────────────────
  void _initOpenVpn() {
    _openVpn = OpenVPN(
      onVpnStageChanged: (stage, message) {
        if (!mounted) return;
        debugPrint('[OpenVPN] stage=$stage msg=$message');
        setState(() {
          _ovpnStage = stage;
          // FIX 2: Release _connecting only when OpenVPN reaches a
          // terminal state (connected OR disconnected).  While it is
          // still negotiating we keep _connecting=true so the button
          // shows the spinner and cannot be tapped again.
          if (stage == VPNStage.connected ||
              stage == VPNStage.disconnected) {
            _connecting = false;
            _ovpnRequestingPermission = false;
          }
        });
        if (stage == VPNStage.connected) {
          _connectedAt = DateTime.now();
          _startClock();
          _showVpnNotification(_selectedServer.name);
        } else if (stage == VPNStage.disconnected) {
          _stopClock();
          setState(() => _sessionTime = '00:00:00');
          _cancelVpnNotification();
        }
      },
      onVpnStatusChanged: (_) {},
    );

    _openVpn.initialize(
      groupIdentifier: 'group.com.jinoca.vpn',
      providerBundleIdentifier: 'com.jinoca.vpn.extension',
      localizedDescription: 'NOCIX VPN',
    );
  }

  // ─────────────────────────────────────────
  // VPN GATE FETCH
  // FIX 1: ValueNotifiers broadcast to picker without needing
  // the sheet to close/reopen.
  // ─────────────────────────────────────────
  Future<void> _fetchVpnGateServers() async {
    if (_loadingNotifier.value) return;
    _loadingNotifier.value = true;
    _fetchedNotifier.value = false;

    final servers = await VpnGateFetcher.fetch();

    _serversNotifier.value = servers;
    _loadingNotifier.value = false;
    _fetchedNotifier.value = true;
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
        debugPrint('[Ads] Load failed: $msg');
      },
    );
  }

  // ─────────────────────────────────────────
  // CONNECT FLOW
  // FIX 2: _connecting flag is set TRUE here and only cleared
  // by the OpenVPN/WireGuard state callback when the connection
  // reaches a terminal state. This prevents the button from
  // flickering back to "TAP TO CONNECT" mid-negotiation.
  // ─────────────────────────────────────────
  void _onConnectTapped() {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _loadingAd = true;
    });

    if (_interstitialReady) {
      _showInterstitial();
    } else {
      _waitForAdThenShow();
    }
  }

  void _waitForAdThenShow() {
    _loadInterstitial();
    int waited = 0;
    Timer.periodic(const Duration(milliseconds: 300), (t) {
      waited += 300;
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_interstitialReady) {
        t.cancel();
        _showInterstitial();
      } else if (waited >= 8000) {
        t.cancel();
        _afterAd(); // timeout – connect without ad
      }
    });
  }

  void _showInterstitial() {
    UnityAds.showVideoAd(
      placementId: 'Interstitial_Android',
      onComplete: (_) {
        if (mounted) _afterAd();
      },
      onFailed: (_, __, ___) {
        if (mounted) _afterAd();
      },
      onSkipped: (_) {
        if (mounted) _afterAd();
      },
    );
  }

  // FIX 2: _loadingAd ends here, but _connecting stays TRUE
  // until the VPN callback tells us the connection resolved.
  Future<void> _afterAd() async {
    setState(() => _loadingAd = false);
    // Reload ad for next connection attempt
    _loadInterstitial();
    // Now actually connect
    await _connectSelected();
  }

  // ─────────────────────────────────────────
  // CONNECT / DISCONNECT
  // ─────────────────────────────────────────
  Future<void> _connectSelected() async {
    if (_selectedServer.protocol == VpnProtocol.wireguard) {
      // WireGuard: awaitable – WG callback clears _connecting
      await _wireguard.startVpn(
        serverAddress: _selectedServer.endpoint,
        wgQuickConfig: _selectedServer.config,
        providerBundleIdentifier: 'com.jinoca.vpn',
      );
      // WireGuard fires stage events so _connecting is released there
    } else {
      // OpenVPN: NOT awaitable – fires events asynchronously.
      // _connecting will be cleared by onVpnStageChanged callback.
      setState(() => _ovpnRequestingPermission = true);
      _openVpn.connect(
        _selectedServer.config,
        _selectedServer.name,
        username: 'vpn',
        password: 'vpn',
        certIsRequired: false,
      );
      // Safety fallback: if OpenVPN never fires a state event within
      // 30 s (e.g. permission denied silently), release the lock.
      Timer(const Duration(seconds: 30), () {
        if (mounted && _connecting && _ovpnStage == VPNStage.disconnected) {
          setState(() {
            _connecting = false;
            _ovpnRequestingPermission = false;
          });
        }
      });
    }
  }

  Future<void> _disconnectSelected() async {
    if (_selectedServer.protocol == VpnProtocol.wireguard) {
      await _wireguard.stopVpn();
    } else {
      _openVpn.disconnect();
    }
  }

  // ─────────────────────────────────────────
  // COMPUTED STATE
  // ─────────────────────────────────────────
  bool get _isConnected {
    if (_selectedServer.protocol == VpnProtocol.wireguard) {
      return _wgStage == VpnStage.connected;
    }
    return _ovpnStage == VPNStage.connected;
  }

  bool get _isVpnNegotiating {
    if (_selectedServer.protocol == VpnProtocol.wireguard) {
      return _wgStage != VpnStage.connected &&
          _wgStage != VpnStage.disconnected;
    }
    return _ovpnStage != VPNStage.connected &&
        _ovpnStage != VPNStage.disconnected;
  }

  // Button is locked when: ad is loading, ad is showing,
  // VPN is negotiating, OR our manual _connecting flag is set.
  bool get _isBusy => _connecting || _isVpnNegotiating;

  // ─────────────────────────────────────────
  // SESSION TIMER
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

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  @override
  void dispose() {
    _wgSub?.cancel();
    _pulseCtrl.dispose();
    _stopClock();
    _serversNotifier.dispose();
    _loadingNotifier.dispose();
    _fetchedNotifier.dispose();
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
        overlay: 0.52,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(children: [
                      const SizedBox(height: 16),
                      _buildLogo(),
                      const SizedBox(height: 24),
                      _buildServerCard(),
                      const SizedBox(height: 40),
                      _buildConnectButton(),
                      const SizedBox(height: 16),
                    ]),
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected
                  ? const Color(0xFF00FF9D)
                  : _isBusy
                      ? Colors.orange
                      : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 8),
          Text(_statusLabel,
              style: const TextStyle(
                  fontSize: 12, letterSpacing: 2, color: Colors.white70)),
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
    if (_ovpnRequestingPermission) return 'REQUESTING PERMISSION...';
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
          radius: 52,
          backgroundColor: Colors.black54,
          child: ClipOval(
            child: Image.asset('assets/LOGO.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.shield,
                    color: Color(0xFFFF8C5A), size: 56)),
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
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
                color: Colors.white)),
      ),
      const Text('SECURE VPN',
          style: TextStyle(
              fontSize: 11, letterSpacing: 4, color: Colors.white38)),
    ]);
  }

  Widget _buildServerCard() {
    final bool canPick = !_isConnected && !_isBusy;
    return GestureDetector(
      onTap: canPick ? _openServerPicker : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE8622A).withOpacity(0.45), width: 1),
        ),
        child: Row(children: [
          Text(_selectedServer.flagEmoji,
              style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedServer.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
                Row(children: [
                  _protocolBadge(_selectedServer.protocol),
                  if (_selectedServer.pingLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(_selectedServer.pingLabel,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                  if (_selectedServer.speedLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(_selectedServer.speedLabel,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ]),
              ],
            ),
          ),
          if (canPick)
            const Icon(Icons.chevron_right, color: Color(0xFFFF8C5A)),
        ]),
      ),
    );
  }

  Widget _protocolBadge(VpnProtocol p) {
    final isWg = p == VpnProtocol.wireguard;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isWg
            ? const Color(0xFFE8622A).withOpacity(0.2)
            : const Color(0xFF4C6FFF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isWg ? 'WireGuard' : 'OpenVPN',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isWg ? const Color(0xFFFF8C5A) : const Color(0xFF7BA7FF),
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    String label;
    if (_loadingAd) {
      label = 'LOADING AD...';
    } else if (_ovpnRequestingPermission) {
      label = 'ALLOW VPN PERMISSION';
    } else if (_isConnected) {
      label = 'DISCONNECT';
    } else if (_isBusy) {
      label = 'CONNECTING...';
    } else {
      label = 'TAP TO CONNECT';
    }

    final Color labelColor = _isConnected
        ? const Color(0xFF00FF9D)
        : _isBusy
            ? Colors.orange
            : Colors.white70;

    return Column(children: [
      GestureDetector(
        onTap: _isBusy
            ? null
            : () => _isConnected ? _disconnectSelected() : _onConnectTapped(),
        child: ScaleTransition(
          scale: (!_isConnected && !_isBusy)
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
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: _isBusy
                ? const Center(
                    child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                  ))
                : const Icon(Icons.power_settings_new_rounded,
                    size: 64, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: labelColor)),
      if (_isConnected) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFF00C853).withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_outlined,
                color: Color(0xFF00FF9D), size: 16),
            const SizedBox(width: 8),
            Text(_sessionTime,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FF9D),
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ]),
        ),
      ],
    ]);
  }

  // ─────────────────────────────────────────
  // SERVER PICKER
  // FIX 1: Uses ValueListenableBuilder so the sheet rebuilds
  // automatically when _serversNotifier / _loadingNotifier change,
  // even while the sheet is already open.
  // ─────────────────────────────────────────
  void _openServerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.93),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('SELECT SERVER',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.white54)),
            const SizedBox(height: 8),
            Expanded(
              // ValueListenableBuilder rebuilds whenever notifiers change
              child: ValueListenableBuilder<bool>(
                valueListenable: _loadingNotifier,
                builder: (_, loading, __) =>
                    ValueListenableBuilder<bool>(
                  valueListenable: _fetchedNotifier,
                  builder: (_, fetched, __) =>
                      ValueListenableBuilder<List<VpnServer>>(
                    valueListenable: _serversNotifier,
                    builder: (_, servers, __) => ListView(
                      controller: scrollCtrl,
                      children: [
                        _sectionHeader('⚡  Premium  •  WireGuard'),
                        _serverTile(kMyServer, ctx),

                        _sectionHeader('🌐  OpenVPN'),

                        if (loading)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Column(children: [
                                CircularProgressIndicator(
                                    color: Color(0xFFFF8C5A)),
                                SizedBox(height: 12),
                                Text('Loading servers...',
                                    style: TextStyle(
                                        color: Colors.white54)),
                              ]),
                            ),
                          )
                        else if (fetched && servers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(children: [
                              const Icon(Icons.cloud_off,
                                  color: Colors.white24, size: 40),
                              const SizedBox(height: 12),
                              const Text('No servers available',
                                  style:
                                      TextStyle(color: Colors.white38)),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.refresh,
                                    color: Color(0xFFFF8C5A)),
                                label: const Text('Retry',
                                    style: TextStyle(
                                        color: Color(0xFFFF8C5A))),
                                onPressed: _fetchVpnGateServers,
                              ),
                            ]),
                          )
                        else if (!fetched && !loading)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Column(children: [
                                CircularProgressIndicator(
                                    color: Color(0xFFFF8C5A)),
                                SizedBox(height: 12),
                                Text('Fetching servers...',
                                    style: TextStyle(
                                        color: Colors.white54)),
                              ]),
                            ),
                          )
                        else
                          ...servers
                              .map((s) => _serverTile(s, ctx))
                              .toList(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              color: Colors.white38,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _serverTile(VpnServer s, BuildContext ctx) {
    final selected = s == _selectedServer;
    return ListTile(
      leading: Text(s.flagEmoji, style: const TextStyle(fontSize: 28)),
      title: Text(s.name,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? const Color(0xFFFF8C5A) : Colors.white)),
      subtitle: Row(children: [
        _protocolBadge(s.protocol),
        if (s.pingLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(s.pingLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
        if (s.speedLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(s.speedLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ]),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFFFF8C5A))
          : null,
      onTap: () {
        setState(() => _selectedServer = s);
        Navigator.pop(ctx);
        if (_isConnected) _disconnectSelected();
      },
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('SETTINGS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.white54)),
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
              leading: const Icon(Icons.refresh, color: Color(0xFFFF8C5A)),
              title: const Text('Refresh Servers'),
              onTap: () {
                Navigator.pop(ctx);
                _fetchVpnGateServers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined,
                  color: Color(0xFFFF8C5A)),
              title: const Text('Import .conf / .ovpn File'),
              onTap: () {
                Navigator.pop(ctx);
                _importConfig();
              },
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
      allowedExtensions: ['conf', 'ovpn'],
    );
    if (result != null) {
      final content =
          await File(result.files.single.path!).readAsString();
      final isWg = content.contains('[Interface]');
      setState(() {
        _selectedServer = VpnServer(
          name: 'Custom Server',
          countryCode: 'XX',
          flagEmoji: '🌐',
          protocol: isWg ? VpnProtocol.wireguard : VpnProtocol.openvpn,
          config: content,
          endpoint: isWg
              ? RegExp(r'Endpoint\s*=\s*(.+)')
                      .firstMatch(content)
                      ?.group(1)
                      ?.trim() ??
                  ''
              : '',
        );
      });
    }
  }
}
