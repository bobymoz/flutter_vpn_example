import 'package:flutter/material.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jinoca VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A), 
      ),
      home: const VpnHome(),
    );
  }
}

class VpnHome extends StatefulWidget {
  const VpnHome({super.key});

  @override
  State<VpnHome> createState() => _VpnHomeState();
}

class _VpnHomeState extends State<VpnHome> {
  // AQUI ESTÁ A CORREÇÃO: "G" maiúsculo no WireGuard
  final _wireguard = WireGuardFlutter.instance;
  bool _isConnected = false;
  String _statusText = "TOCAR PARA CONECTAR";

  // SUAS CREDENCIAIS DO WIREGUARD 
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
    _initWireguard();
  }

  void _initWireguard() async {
    try {
      // O WireGuard exige um nome de interface invisível, vamos usar 'wg0'
      await _wireguard.initialize(interfaceName: 'wg0');
      
      // Esse ouvinte vai atualizar o botão em tempo real
      _wireguard.vpnStageSnapshot.listen((event) {
        if (mounted) {
          setState(() {
            if (event == "connected") {
              _isConnected = true;
              _statusText = "CONECTADO E PROTEGIDO";
            } else if (event == "disconnected") {
              _isConnected = false;
              _statusText = "TOCAR PARA CONECTAR";
            } else if (event == "denied") {
              _isConnected = false;
              _statusText = "PERMISSÃO NEGADA";
            } else {
              _statusText = event.toUpperCase() + "...";
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Erro ao inicializar: \$e");
    }
  }

  void _toggleVpn() async {
    try {
      if (_isConnected) {
        // Comando nativo para desligar o motor
        await _wireguard.stopVpn();
      } else {
        // Comando nativo para iniciar o motor
        await _wireguard.startVpn(
          serverAddress: "51.79.117.132:53",
          wgQuickConfig: wgConfig,
          providerBundleIdentifier: "com.jinoca.vpn", 
        );
      }
    } catch (e) {
      debugPrint("Erro na VPN: \$e");
    }
  }

  Color get _buttonColor {
    return _isConnected ? Colors.greenAccent : Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jinoca VPN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleVpn,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _buttonColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _buttonColor, width: 4),
                  boxShadow: [
                    BoxShadow(color: _buttonColor.withOpacity(0.4), blurRadius: 25, spreadRadius: 5),
                  ],
                ),
                child: Icon(Icons.power_settings_new, size: 80, color: _buttonColor),
              ),
            ),
            const SizedBox(height: 50),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
