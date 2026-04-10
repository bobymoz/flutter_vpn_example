import 'package:flutter/material.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'dart:async';

void main() => runApp(const NocixApp());

class NocixApp extends StatelessWidget {
  const NocixApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nocix',
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
  bool _isConnected = false;
  VpnStage _stage = VpnStage.disconnected;
  
  // Variáveis para simular velocidade e preencher o visual
  String _downSpeed = "0.0";
  String _upSpeed = "0.0";

  final String wgConfig = '''
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
    _initVpn();
  }

  void _initVpn() async {
    await _wireguard.initialize(interfaceName: 'nocix0');
    _wireguard.vpnStageSnapshot.listen((stage) {
      if (mounted) {
        setState(() {
          _stage = stage;
          _isConnected = (stage == VpnStage.connected);
        });
      }
    });
  }

  void _toggleVpn() async {
    if (_isConnected) {
      await _wireguard.stopVpn();
    } else {
      await _wireguard.startVpn(
        serverAddress: "51.79.117.132:53",
        wgQuickConfig: wgConfig,
        providerBundleIdentifier: "com.jinoca.vpn",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGEM DE FUNDO
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/FUNDO.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Filtro escuro para legibilidade
          Container(color: Colors.black.withOpacity(0.5)),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // 2. LOGO EM FORMA DE BOLINHA
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: const AssetImage("assets/LOGO.png"),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("NOCIX", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
                
                const Spacer(),

                // 3. VELOCIDADE DE FORMA BONITA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _speedIndicator("DOWNLOAD", _isConnected ? "42.5" : "0.0", Icons.arrow_downward),
                      _speedIndicator("UPLOAD", _isConnected ? "12.1" : "0.0", Icons.arrow_upward),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 4. BOTÃO MELHORADO
                GestureDetector(
                  onTap: _toggleVpn,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isConnected 
                          ? [Colors.greenAccent, Colors.teal] 
                          : [Colors.redAccent, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnected ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.power_settings_new, 
                      size: 60, 
                      color: Colors.white.withOpacity(0.9)
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                Text(
                  _isConnected ? "CONECTADO" : (_stage == VpnStage.disconnected ? "DESCONECTADO" : "A PREPARAR..."),
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedIndicator(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const Text("Mbps", style: TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    );
  }
}
