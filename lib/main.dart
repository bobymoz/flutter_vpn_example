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
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo: fades + scales in
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Ring: expands behind logo
    _ringScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Text: fades in after logo
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward();

    // Navigate after animation + small hold
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
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
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo + ring ───────────────
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Transform.scale(
                      scale: _ringScale.value,
                      child: Opacity(
                        opacity: (_ringScale.value - 0.4) / 0.6,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4C6FFF).withOpacity(0.35),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Second inner ring
                    Transform.scale(
                      scale: _ringScale.value * 0.85,
                      child: Opacity(
                        opacity: (_ringScale.value - 0.4).clamp(0.0, 0.6),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00D4FF).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Logo itself
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
                                Color(0xFF4C6FFF),
                                Color(0xFF00D4FF),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: const Color(0xFF0A0E21),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/LOGO.png',
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shield,
                                  color: Color(0xFF4C6FFF),
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
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF4C6FFF), Color(0xFF00D4FF)],
                      ).createShader(bounds),
                      child: const Text(
                        'NOCIX',
                        style: TextStyle(
                          fontSize: 36,
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
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              // ── Loading indicator ─────────
              Opacity(
                opacity: _textOpacity.value,
                child: SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4C6FFF),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SERVER MODEL
// ─────────────────────────────────────────────
class VpnServer {
  final String name;
  final String countryCode; // ISO 3166-1 alpha-2 lower-case e.g. "us"
  final String flagEmoji;
  final String endpoint;
  final String config;

  const VpnServer({
    required this.name,
    required this.countryCode,
    required this.flagEmoji,
    required this.endpoint,
    required this.config,
  });
}

// ─────────────────────────────────────────────
// SERVER LIST  (adicione quantos quiser aqui)
// ─────────────────────────────────────────────
final List<VpnServer> kServers = [
  VpnServer(
    name: 'United States',
    countryCode: 'us',
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
  // Exemplo: adicione mais servidores abaixo
  // VpnServer(
  //   name: 'Germany',
  //   countryCode: 'de',
  //   flagEmoji: '🇩🇪',
  //   endpoint: 'ENDPOINT:PORT',
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
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4C6FFF),
          secondary: Color(0xFF00D4FF),
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
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

  // ── Servidor selecionado ───────────────────
  VpnServer _selectedServer = kServers.first;

  // ── Unity Ads ─────────────────────────────
  static const String _gameId = '6079651';
  bool _interstitialReady = false;
  bool _bannerReady = false;
  bool _isAdShowing = false;

  // ── Velocidade ────────────────────────────
  Timer? _speedTimer;
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  int _prevRxBytes = 0;
  int _prevTxBytes = 0;
  String _sessionTime = '00:00:00';
  DateTime? _connectedAt;
  Timer? _clockTimer;

  // ── Animação ──────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Pulse animation for the connect button
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

  // ── VPN init ─────────────────────────────
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
      _startSpeedTimer();
    } else {
      _stopClock();
      _stopSpeedTimer();
      if (stage == VpnStage.disconnected) {
        setState(() {
          _downloadSpeed = 0;
          _uploadSpeed = 0;
          _sessionTime = '00:00:00';
        });
      }
    }
  }

  // ── Ads init ─────────────────────────────
  // FIX: Inicializa e pré-carrega na abertura do app para evitar atraso
  void _initAds() {
    UnityAds.init(
      gameId: _gameId,
      testMode: false,
      onComplete: () {
        debugPrint('Unity Ads initialized');
        _preloadInterstitial();
        setState(() => _bannerReady = true);
      },
      onFailed: (error, msg) =>
          debugPrint('Unity Ads init failed: $error – $msg'),
    );
  }

  void _preloadInterstitial() {
    _interstitialReady = false;
    UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (id) {
        debugPrint('Interstitial loaded: $id');
        if (mounted) setState(() => _interstitialReady = true);
      },
      onFailed: (id, error, msg) {
        debugPrint('Interstitial failed: $msg');
        if (mounted) setState(() => _interstitialReady = false);
      },
    );
  }

  // FIX: Anúncio é mostrado IMEDIATAMENTE porque já foi pré-carregado
  void _showAdThenConnect() {
    if (_isAdShowing) return;
    if (_interstitialReady) {
      setState(() => _isAdShowing = true);
      UnityAds.showVideoAd(
        placementId: 'Interstitial_Android',
        onComplete: (_) => _afterAd(),
        onFailed: (_, __, ___) => _afterAd(),
        onSkipped: (_) => _afterAd(),
      );
    } else {
      // Ad ainda não carregou – conecta direto sem atraso
      _connectVpn();
    }
  }

  void _afterAd() {
    setState(() => _isAdShowing = false);
    _connectVpn();
    // Pré-carrega próximo anúncio imediatamente
    _preloadInterstitial();
  }

  // ── VPN connect/disconnect ────────────────
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

  // ── Velocidade ────────────────────────────
  // FIX: Lê /proc/net/dev para cálculo correto de velocidade
  void _startSpeedTimer() {
    _prevRxBytes = 0;
    _prevTxBytes = 0;
    _speedTimer?.cancel();
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final file = File('/proc/net/dev');
        if (!await file.exists()) return;
        final lines = await file.readAsLines();
        int rx = 0, tx = 0;
        for (final line in lines) {
          if (line.contains('nocix0') || line.contains('tun')) {
            final parts = line.trim().split(RegExp(r'\s+'));
            // /proc/net/dev: col1=iface, col2=rx_bytes, col10=tx_bytes
            if (parts.length >= 10) {
              rx += int.tryParse(parts[1]) ?? 0;
              tx += int.tryParse(parts[9]) ?? 0;
            }
          }
        }
        if (_prevRxBytes > 0) {
          final dlKbps = (rx - _prevRxBytes) / 1024.0;
          final ulKbps = (tx - _prevTxBytes) / 1024.0;
          if (mounted) {
            setState(() {
              _downloadSpeed = dlKbps < 0 ? 0 : dlKbps;
              _uploadSpeed = ulKbps < 0 ? 0 : ulKbps;
            });
          }
        }
        _prevRxBytes = rx;
        _prevTxBytes = tx;
      } catch (e) {
        debugPrint('Speed read error: $e');
      }
    });
  }

  void _stopSpeedTimer() {
    _speedTimer?.cancel();
    _speedTimer = null;
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null || !mounted) return;
      final diff = DateTime.now().difference(_connectedAt!);
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      setState(() => _sessionTime = '$h:$m:$s');
    });
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  // ── Server picker ─────────────────────────
  // FIX: Modal com lista clicável de servidores, bandeira emoji + nome
  void _openServerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141831),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Column(
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
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                itemCount: kServers.length,
                itemBuilder: (_, i) {
                  final s = kServers[i];
                  final isSelected = s == _selectedServer;
                  return ListTile(
                    leading: Text(
                      s.flagEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      s.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? const Color(0xFF4C6FFF) : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      s.endpoint,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF4C6FFF))
                        : null,
                    onTap: () {
                      setState(() => _selectedServer = s);
                      Navigator.pop(ctx);
                      // Se estava conectado, desconecta para reconectar no novo servidor
                      if (_stage == VpnStage.connected) {
                        _disconnectVpn();
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        });
      },
    );
  }

  // ── Import config ─────────────────────────
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
          countryCode: 'custom',
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
    _stopSpeedTimer();
    _stopClock();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isConnected = _stage == VpnStage.connected;
    final bool isProcessing =
        _stage != VpnStage.connected && _stage != VpnStage.disconnected;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Body ──────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildLogo(),
                    const SizedBox(height: 24),
                    _buildServerCard(),
                    const SizedBox(height: 32),
                    _buildConnectButton(isConnected, isProcessing),
                    const SizedBox(height: 32),
                    if (isConnected) _buildStatsRow(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // ── Banner Ad ─────────────────────
          // FIX: Banner só renderiza quando SDK pronto
          if (_bannerReady)
            UnityBannerAd(
              placementId: 'Banner_Android',
              onLoad: (_) => debugPrint('Banner loaded'),
              onClick: (_) {},
              onFailed: (id, error, msg) =>
                  debugPrint('Banner failed: $msg'),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0E21),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _stage == VpnStage.connected
                  ? const Color(0xFF00FF9D)
                  : _stage == VpnStage.disconnected
                      ? Colors.redAccent
                      : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _stageLabel,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: Colors.white60,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onPressed: () => _showSettingsMenu(),
        ),
      ],
    );
  }

  String get _stageLabel {
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
              colors: [Color(0xFF4C6FFF), Color(0xFF00D4FF)],
            ),
          ),
          child: CircleAvatar(
            radius: 52,
            backgroundColor: const Color(0xFF0A0E21),
            child: ClipOval(
              child: Image.asset(
                'assets/LOGO.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shield,
                  color: Color(0xFF4C6FFF),
                  size: 56,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4C6FFF), Color(0xFF00D4FF)],
          ).createShader(bounds),
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

  // FIX: Server card agora é clicável e mostra bandeira emoji
  Widget _buildServerCard() {
    return GestureDetector(
      onTap: _stage == VpnStage.disconnected ? _openServerPicker : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141831),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4C6FFF).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4C6FFF).withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              _selectedServer.flagEmoji,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedServer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _selectedServer.endpoint,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_stage == VpnStage.disconnected)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF4C6FFF),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton(bool isConnected, bool isProcessing) {
    return Column(
      children: [
        GestureDetector(
          onTap: isProcessing
              ? null
              : () {
                  if (isConnected) {
                    _disconnectVpn();
                  } else {
                    _showAdThenConnect();
                  }
                },
          child: ScaleTransition(
            scale:
                (!isConnected && !isProcessing) ? _pulseAnim : kAlwaysCompleteAnimation,
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
                      : isProcessing
                          ? [Colors.orange.shade700, Colors.orange.shade900]
                          : [const Color(0xFF4C6FFF), const Color(0xFF7B5EA7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isConnected
                            ? const Color(0xFF00C853)
                            : isProcessing
                                ? Colors.orange
                                : const Color(0xFF4C6FFF))
                        .withOpacity(0.45),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: isProcessing
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
        const SizedBox(height: 18),
        Text(
          isConnected
              ? 'DISCONNECT'
              : isProcessing
                  ? 'PLEASE WAIT...'
                  : 'TAP TO CONNECT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: isConnected
                ? const Color(0xFF00C853)
                : isProcessing
                    ? Colors.orange
                    : Colors.white70,
          ),
        ),
        if (isConnected) ...[
          const SizedBox(height: 4),
          Text(
            _sessionTime,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141831),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00C853).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF00D4FF),
            label: 'DOWNLOAD',
            value: _formatSpeed(_downloadSpeed),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white12,
          ),
          _buildStatItem(
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFF7B5EA7),
            label: 'UPLOAD',
            value: _formatSpeed(_uploadSpeed),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // FIX: Cálculo de velocidade correto – mostra Mbps ou KB/s
  String _formatSpeed(double kbps) {
    if (kbps >= 1024) {
      return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${kbps.toStringAsFixed(0)} KB/s';
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141831),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.dns_outlined, color: Color(0xFF4C6FFF)),
            title: const Text('Select Server'),
            onTap: () {
              Navigator.pop(ctx);
              _openServerPicker();
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.file_upload_outlined, color: Color(0xFF4C6FFF)),
            title: const Text('Import .conf File'),
            onTap: () {
              Navigator.pop(ctx);
              _importConfig();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
