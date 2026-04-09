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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Fundo noturno ultra moderno
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
  final _wireguard = WireguardFlutter.instance;
  bool _isConnected = false;
  String _statusText = "TOCAR PARA CONECTAR";

  // SUAS CREDENCIAIS DO WIREGUARD (Injetadas exatamente como a VPS gerou)
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
    _checkStatus();
  }

  void _checkStatus() async {
    try {
      final status = await _wireguard.isConnected();
      if (mounted) {
        setState(() {
          _isConnected = status;
          _statusText = _isConnected ? "CONECTADO E PROTEGIDO" : "TOCAR PARA CONECTAR";
        });
      }
    } catch (e) {
      debugPrint("Erro ao checar status: \$e");
    }
  }

  void _toggleVpn() async {
    setState(() {
      _statusText = _isConnected ? "DESCONECTANDO..." : "CONECTANDO...";
    });

    try {
      if (_isConnected) {
        await _wireguard.disconnect();
      } else {
        // Inicializa a configuração do WireGuard no sistema Android
        await _wireguard.initialize(packageId: "com.jinoca.vpn");
        
        // Pede a permissão, salva a configuração e liga
        await _wireguard.startVpn(
          serverAddress: "51.79.117.132:53",
          wgQuickConfig: wgConfig,
          providerBundleIdentifier: "com.jinoca.vpn.VPNExtension",
        );
      }
      
      // Aguarda 1 segundo para o Android respirar e checa se deu certo
      await Future.delayed(const Duration(seconds: 1));
      _checkStatus();
      
    } catch (e) {
      debugPrint("Erro na VPN: \$e");
      if (mounted) {
        setState(() {
          _statusText = "ERRO NA CONEXÃO";
        });
      }
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
