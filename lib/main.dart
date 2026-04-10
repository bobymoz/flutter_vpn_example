import 'package:flutter/material.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NocixApp());
}

class NocixApp extends StatelessWidget {
  const NocixApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _wireguard = WireGuardFlutter.instance;
  VpnStage _stage = VpnStage.disconnected;
  
  // Unity Ads Config
  final String _gameId = "6079651";

  // Server Management
  String _currentConfig = '''
[Interface]
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

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    // Inicializa Ads
    UnityAds.init(
      gameId: _gameId,
      onComplete: () => _loadAds(),
      onFailed: (error, message) => debugPrint('Unity Ads Init Failed: $message'),
    );

    // Inicializa VPN
    await _wireguard.initialize(interfaceName: 'nocix0');
    _wireguard.vpnStageSnapshot.listen((stage) {
      if (mounted) setState(() => _stage = stage);
    });
  }

  void _loadAds() {
    UnityAds.load(placementId: 'Interstitial_Android');
    UnityAds.load(placementId: 'Rewarded_Android');
  }

  void _showAdAndConnect() {
    UnityAds.showVideoAd(
      placementId: 'Interstitial_Android',
      onComplete: (placementId) => _connectVpn(),
      onFailed: (placementId, error, message) => _connectVpn(),
      onSkipped: (placementId) => _connectVpn(),
    );
  }

  void _connectVpn() async {
    await _wireguard.startVpn(
      serverAddress: "51.79.117.132:53",
      wgQuickConfig: _currentConfig,
      providerBundleIdentifier: "com.jinoca.vpn",
    );
  }

  Future<void> _importConfig() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['conf'],
    );
    if (result != null) {
      String content = await File(result.files.single.path!).readAsString();
      setState(() => _currentConfig = content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1A1A2E),
                builder: (context) => _buildSettingsMenu(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fundo do App
          Image.asset("assets/FUNDO.png", fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Container(color: Colors.black.withOpacity(0.6)), // Filtro para dar contraste
          
          SafeArea(
            child: SizedBox(
              width: double.infinity, // <-- CORREÇÃO DO BUG: Força o alinhamento no centro da tela!
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildProfessionalLogo(),
                  const SizedBox(height: 20),
                  _buildServerBadge(),
                  const Spacer(),
                  _buildConnectButton(),
                  const SizedBox(height: 100), // Espaço para o Banner da Unity não cobrir o botão
                ],
              ),
            ),
          ),
          
          // Banner da Unity Fixo na Base
          Align(
            alignment: Alignment.bottomCenter,
            child: UnityBannerAd(placementId: 'Banner_Android'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
          ),
          child: CircleAvatar(
            radius: 65,
            backgroundColor: Colors.transparent, // <-- CORREÇÃO DO BUG: Remove o fundo branco!
            backgroundImage: const AssetImage("assets/LOGO.png"),
          ),
        ),
        const SizedBox(height: 10),
        const Text("NOCIX", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 10)),
      ],
    );
  }

  Widget _buildServerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/us.png", width: 24),
          const SizedBox(width: 10),
          const Text("USA DEFAULT", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    bool isConnected = _stage == VpnStage.connected;
    bool isProcessing = _stage != VpnStage.connected && _stage != VpnStage.disconnected;

    return GestureDetector(
      onTap: isProcessing ? null : () {
        if (isConnected) {
          _wireguard.stopVpn();
        } else {
          _showAdAndConnect(); 
        }
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 150, height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isConnected ? Colors.blueAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
                  blurRadius: 30, spreadRadius: 5
                )
              ],
              gradient: LinearGradient(
                colors: isConnected ? [Colors.blue, Colors.blueGrey] : [Colors.redAccent, Colors.red.shade900]
              )
            ),
            child: isProcessing 
              ? const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.white))
              : const Icon(Icons.power_settings_new, size: 70, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            isConnected ? "CONNECTED" : (isProcessing ? "CONNECTING..." : "TAP TO CONNECT"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("SETTINGS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text("Import .conf Server"),
            onTap: () {
              Navigator.pop(context);
              _importConfig();
            },
          ),
        ],
      ),
    );
  }
}
