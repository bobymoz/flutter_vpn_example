import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

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
        scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Fundo escuro
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
  late OpenVPN engine;
  VPNStage? stage;

  // CONFIGURAÇÃO LIMPA E SEM LIXO TEXTUAL (Com IP Fantasma)
  String _getSecureConfig() {
    final p1 = 102 ~/ 2;
    final p2 = 158 ~/ 2;
    final p3 = 234 ~/ 2;
    final p4 = 264 ~/ 2;
    final hiddenIp = '$p1.$p2.$p3.$p4';

    return '''
client
dev tun
proto udp
remote $hiddenIp 53
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
ignore-unknown-option block-outside-dns
verb 3

<cert>
-----BEGIN CERTIFICATE-----
MIIDVTCCAj2gAwIBAgIRALoi8trP+4Vw1WkVdJbYccAwDQYJKoZIhvcNAQELBQAw
FjEUMBIGA1UEAwwLRWFzeS1SU0EgQ0EwHhcNMjYwNDA5MjE1NDUzWhcNMzYwNDA2
MjE1NDUzWjARMQ8wDQYDVQQDDAZqaW5vY2EwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQDWAyZuKNz5efsLJgLQay6fTLACE2J0hxQOucYImV/NcVQNA40V
cFtgxuZ1FEOoSQFRTwj+3reUsbrMZfAPnVhvuXZQtkTn+2Rf4s2pHm12xUy5QsWV
mUWurDz1quLl44FrcczU9/pdVjA/BfY2eNmWn74/NvGcz/IZ5dHLkkC7gykBdjIQ
J3llAdAOYvH2FZkD/wPmBSaFiMkfuEEk76bbk2rGG/UmpXWwhxoJFW3L3io7DkNj
fmFEF2yjZ8Cc1D1UNshzzIHaagKX7AQBzKWCcsbUn/adp3vyQ122DWRlJM/g6fvU
0oiYO5CKdFDekXHoB1w1+NwSCjDFsOWK5ScZAgMBAAGjgaIwgZ8wCQYDVR0TBAIw
ADAdBgNVHQ4EFgQUhTEGf3Vii8BHIn/hmcuFvcW9QnowUQYDVR0jBEowSIAU6D4W
odKML1z+ZRuEK8Lv/G0nm8ShGqQYMBYxFDASBgNVBAMMC0Vhc3ktUlNBIENBghRf
YBNEwWrFSHayGpsBgxbkuouJGDATBgNVHSUEDDAKBggrBgEFBQcDAjALBgNVHQ8E
BAMCB4AwDQYJKoZIhvcNAQELBQADggEBAIOp4bzb+ujgAPRiFjXNGPYtE/orCRNK
vBtqcNNa/pu5mFYGmLeMayV5RX6D+dZO76BjpQ3jpa1RlWkFYMN8/ab0+OZaEIGn
sqW2NjZia6YT90nkPSTCJHRLiGD+RlJJWTeTOHa2zL8AuUeq4C/fkbjRX0E3XmXr
gunxRMbV9sR5+VB+JLFdHMrzCkPnGGuMOuTQYX1qv+G/OMvMWB05OR99fG/vm/Aj
ndx/c7mbn6urNOcbtOhY6QqBCgHCPR4bSHzkTkWUX7WLEh1TOrU04ZX7K5khuRpW
Fqa1Zxd5XG1mUVwCb1ZHaV1Qc4TA15GVcolilXh3SobGAt21faTC8dc=
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDWAyZuKNz5efsL
JgLQay6fTLACE2J0hxQOucYImV/NcVQNA40VcFtgxuZ1FEOoSQFRTwj+3reUsbrM
ZfAPnVhvuXZQtkTn+2Rf4s2pHm12xUy5QsWVmUWurDz1quLl44FrcczU9/pdVjA/
BfY2eNmWn74/NvGcz/IZ5dHLkkC7gykBdjIQJ3llAdAOYvH2FZkD/wPmBSaFiMkf
uEEk76bbk2rGG/UmpXWwhxoJFW3L3io7DkNjfmFEF2yjZ8Cc1D1UNshzzIHaagKX
7AQBzKWCcsbUn/adp3vyQ122DWRlJM/g6fvU0oiYO5CKdFDekXHoB1w1+NwSCjDF
sOWK5ScZAgMBAAECggEABqO94TyM0IOfjYK+Ixu0LFaLfmD+FLntHiDW20Tw4zWR
Iz85NRFRkHDTTQ4WJEYxj4V5dLjRrsAN2NIPztg1mm/BUzM4c48J1+y4LzdFs6He
5b+D1EaXUho/YOrOk83JYd07ut6/qn4mTIpBj4KT05e8pgbtG42bCAEoj12H+xlB
1aBpyf5GPg2Zucm26rRKSFameBWKKMY97ljGfD+eRoj9xrT+2mE/hPbxRoS1VGz3
1JJJB4msBxvMvXWJCFgZ8bDv050PkoptccCiFg32KXakmVg47XD6icCC9hkHXNie
OmcPFYGneMm2GPKOpZug61Cwv3cw8nO+9EGVB/q5BQKBgQD1z7QJOasaLTcQ+ByL
0k93SHZ+XVY9tqCBDbcNufu4HskqvfUvTYchAPW9ZKuwODPGYT7imSqVnkpY7nQa
PnpEhkkC64XvakRv7ZyATCNWLgHkIXpIz/0hjSRSlxtST34Cv8Q3unO/i2Eb+bP8
V/fqWp8AfWmUDfnVuVbv/xdJrQKBgQDe4gc64sD2I5J+cqqocJ0upz1A6qtKWLF8
d8Y8EiTgNReEiBn8WZf4LjQQ8hl+ewt2oy71yrYOuH0NAE3Eyky3I39ZXz6FpU+Y
n4krLGq9CRw8oVqWpbu7GAdQi3JwBtwlGrCspQbPiqyTpPipXb1gx7hdNlEYJzsE
tRfqlZ/YnQKBgFEaGYWdsFVvq6Z+pjR/zFZH40ioFQdBlU1fMBFoVqQWDDt890OH
Kdl6zpmReJAoyvReK3hqHsHEuzUCX+40xPSM9dPvz34BqtjfJe6ysEoD3f3eCdGy
Rgtm3SAe2RXcQnA3w067xurg2sZ3KapNf++jvKhVuJrvzYl1oDiJCq71AoGAeDsj
vU8+2khcKRwAFXcSQ21x7IfquONZcxRFengrLktVkWe95NQL15RM/+spd4I2r9vd
ZDfit9QrmQzV5tdeRNjARNzNJFkFtAYzf3epaKn2cnp0HJnwyD9xCrD+nZIFxXo9
XhRztRdQeyDeBrcLhp6WRKodWtMm0iZCbYgjPz0CgYB+UZlIPOFb4osadVD/adLf
4wEfJgw8/ubXNr4GhIbl/HUZKhBM7WHCHzgSd+4FzokFVqIK/Ew62rFBtkTVQm64
//eoCsK6pCyXok9EX9w6VTIEEzFR4p+zmwW95fxwaC7uUW8M06Zhqy6g9hN5/uLH
wLzF+E3AQSlFAiu7R3r0Xw==
-----END PRIVATE KEY-----
</key>

<ca>
-----BEGIN CERTIFICATE-----
MIIDTjCCAjagAwIBAgIUX2ATRMFqxUh2shqbAYMW5LqLiRgwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAwwLRWFzeS1SU0EgQ0EwHhcNMjYwNDA5MjE1NDUxWhcNMzYw
NDA2MjE1NDUxWjAWMRQwEgYDVQQDDAtFYXN5LVJTQSBDQTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBANdT0eoAG/AwrVrMdaXKmESoZT2410aZn14GLQZq
2iTVbXWh7EQcnsAigl5LPf4tQWQJEnQSjjmhjzF95XXNusSwHdgGosvmZm1Nsu5r
n7nx1dFlPZ0/4S7ogloM8u8hLTTHZeWBRHwEyZX2DWYOtMVp08JPlUPPStlKDNeN
qUO0Rlrxg7KztIJK864xB4+0dVIpvDKj52q2kKXOESrCmRddwf3YwzjRI1EOFkjP
XwiVCV+29+YJ5umEPg3qOLKA8j52kBbcZ2Um+a8KaCik42vUjxML6DPj2Teo9t9r
XaSqk3nBlmrgWBB5C8x9HrwfbXz4fTTsxbsA8Wzpq9hf2UUCAwEAAaOBkzCBkDAP
BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBToPhah0owvXP5lG4Qrwu/8bSebxDBR
BgNVHSMESjBIgBToPhah0owvXP5lG4Qrwu/8bSebxKEapBgwFjEUMBIGA1UEAwwL
RWFzeS1SU0EgQ0GCFF9gE0TBasVIdrIamwGDFuS6i4kYMAsGA1UdDwQEAwIBBjAN
BgkqhkiG9w0BAQsFAAOCAQEAnZ3As/vVkCdZMm1DEBgOEIjC2E+K0cSrEt8yhEyr
idbIzfUYms5ErrQVSEFeiCaUYgP7fWZl2CitLJkut/KyRAPS3XbtYheWiT9RQPsk
1KaLPtFWWDhcIfKks6mkuXpW/yGyaWPhz3vOjcS8gG/f1zRGXMl4KK8Wf6yujOkL
asKxJoG/Dx8O3poZ3x56CPnWPTLT/VQi6Aw/VrxBP19JMhRO9gRqS4fd0+T//M89
HS61JsIRNg1tSn1Ey6DTiGU6o7fr3JmsjJna8aIyx80FTAxdAE3t2sQYvPElkbeF
8WB26CJ1vFxnYEJMXPNaRaT6Df09ExtYXkhgbtMVQ0xHjw==
-----END CERTIFICATE-----
</ca>

<tls-crypt>
-----BEGIN OpenVPN Static key V1-----
4f36decba683df9ca70bfdabee41717d
6e831e74aaeaf40bce664256efe24894
5aa656d8fb9a0e8a191ea7ed0d686caa
a39c01fab63efe0ae39391754337a3b8
1eca3e736f7c1d660215db29b86dbfd0
ecc9afb83a3b44b5c13579d1e47310f0
c6156105ab9ab2c98281e3d837793b0d
92805815dcb31626d339dd5ff0458d23
349f54789e1cbef81ccf38c1575a0c3c
023b8f644b261c4274b968f9d0ecf36b
c7d8f4e07e6ebf00c561080caf81f315
6795f7b6ff08b0bbf5b79189638e7d03
fa810769ba03b7340687181ed91d0acf
9071dd8f6035543fbd16009273d12024
e6ebea0e3c969892527fb2d38ce679c4
a97a26f89af95d50488bae8ed6d1a9a3
-----END OpenVPN Static key V1-----
</tls-crypt>
''';
  }

  @override
  void initState() {
    super.initState();
    
    engine = OpenVPN(
      onVpnStatusChanged: (VpnStatus? s) {},
      onVpnStageChanged: (VPNStage? s, String? raw) {
        if (mounted) setState(() { stage = s; });
      },
    );
    
    engine.initialize(
      groupIdentifier: "group.com.jinoca.vpn",
      providerBundleIdentifier: "com.jinoca.vpn.VPNExtension",
      localizedDescription: "Jinoca VPN",
    );
  }

  void _toggleVpn() async {
    if (stage == VPNStage.connected) {
      engine.disconnect();
    } else {
      // Pede permissão de rede para o Android (Aparece o popup com a chavinha)
      engine.requestPermissionAndroid().then((value) {
        engine.connect(_getSecureConfig(), "JinocaVPN", username: "", password: "", certIsRequired: true);
      });
    }
  }

  String get _stateText {
    if (stage == VPNStage.connected) return 'CONECTADO';
    if (stage == VPNStage.disconnected || stage == null) return 'TOCAR PARA CONECTAR';
    if (stage == VPNStage.authenticating) return 'AUTENTICANDO...';
    return 'CONECTANDO...';
  }

  Color get _buttonColor {
    if (stage == VPNStage.connected) return Colors.greenAccent;
    if (stage == VPNStage.disconnected || stage == null) return Colors.redAccent;
    return Colors.orangeAccent;
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
              _stateText,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
