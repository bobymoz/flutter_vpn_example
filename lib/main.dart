import 'package:flutter/material.dart';
import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:flutter_vpn/state.dart'; // <-- A LINHA MÁGICA QUE FALTAVA!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jinoca VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Fundo escuro moderno
      ),
      home: const VpnScreen(),
    );
  }
}

class VpnScreen extends StatefulWidget {
  const VpnScreen({Key? key}) : super(key: key);

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  var _state = FlutterVpnState.disconnected;
  
  // SUAS CREDENCIAIS CHUMBADAS (HARDCODED)
  final String serverIp = '51.79.117.132';
  final String username = 'vpnuser';
  final String password = 'FTaPM5psjEbB2HGD';

  @override
  void initState() {
    super.initState();
    FlutterVpn.prepare();
    FlutterVpn.onStateChanged.listen((FlutterVpnState state) {
      if (mounted) {
        setState(() {
          _state = state;
        });
      }
    });
  }

  void _toggleVpn() async {
    if (_state == FlutterVpnState.disconnected) {
      await FlutterVpn.connectIkev2EAP(
        server: serverIp,
        username: username,
        password: password,
      );
    } else {
      await FlutterVpn.disconnect();
    }
  }

  String get _stateText {
    switch (_state) {
      case FlutterVpnState.connected:
        return 'CONECTADO';
      case FlutterVpnState.connecting:
        return 'CONECTANDO...';
      case FlutterVpnState.disconnected:
        return 'TOCAR PARA CONECTAR';
      case FlutterVpnState.disconnecting:
        return 'DESCONECTANDO...';
      case FlutterVpnState.error:
        return 'ERRO NA CONEXÃO';
      default:
        return 'DESCONHECIDO';
    }
  }

  Color get _buttonColor {
    if (_state == FlutterVpnState.connected) return Colors.greenAccent;
    if (_state == FlutterVpnState.connecting || _state == FlutterVpnState.disconnecting) return Colors.orangeAccent;
    return Colors.redAccent;
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
                    BoxShadow(
                      color: _buttonColor.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  size: 80,
                  color: _buttonColor,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Text(
              _stateText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
