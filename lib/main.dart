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
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
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
  VpnStatus? status;
  VPNStage? stage; // <-- O novo controlador de estágios adicionado aqui

  
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
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            ba:22:f2:da:cf:fb:85:70:d5:69:15:74:96:d8:71:c0
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=Easy-RSA CA
        Validity
            Not Before: Apr  9 21:54:53 2026 GMT
            Not After : Apr  6 21:54:53 2036 GMT
        Subject: CN=jinoca
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:d6:03:26:6e:28:dc:f9:79:fb:0b:26:02:d0:6b:
                    2e:9f:4c:b0:02:13:62:74:87:14:0e:b9:c6:08:99:
                    5f:cd:71:54:0d:03:8d:15:70:5b:60:c6:e6:75:14:
                    43:a8:49:01:51:4f:08:fe:de:b7:94:b1:ba:cc:65:
                    f0:0f:9d:58:6f:b9:76:50:b6:44:e7:fb:64:5f:e2:
                    cd:a9:1e:6d:76:c5:4c:b9:42:c5:95:99:45:ae:ac:
                    3c:f5:aa:e2:e5:e3:81:6b:71:cc:d4:f7:fa:5d:56:
                    30:3f:05:f6:36:78:d9:96:9f:be:3f:36:f1:9c:cf:
                    f2:19:e5:d1:cb:92:40:bb:83:29:01:76:32:10:27:
                    79:65:01:d0:0e:62:f1:f6:15:99:03:ff:03:e6:05:
                    26:85:88:c9:1f:b8:41:24:ef:a6:db:93:6a:c6:1b:
                    f5:26:a5:75:b0:87:1a:09:15:6d:cb:de:2a:3b:0e:
                    43:63:7e:61:44:17:6c:a3:67:c0:9c:d4:3d:54:36:
                    c8:73:cc:81:da:6a:02:97:ec:04:01:cc:a5:82:72:
                    c6:d4:9f:f6:9d:a7:7b:f2:43:5d:b6:0d:64:65:24:
                    cf:e0:e9:fb:d4:d2:88:98:3b:90:8a:74:50:de:91:
                    71:e8:07:5c:35:f8:dc:12:0a:30:c5:b0:e5:8a:e5:
                    27:19
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                85:31:06:7F:75:62:8B:C0:47:22:7F:E1:99:CB:85:BD:C5:BD:42:7A
            X509v3 Authority Key Identifier: 
                keyid:E8:3E:16:A1:D2:8C:2F:5C:FE:65:1B:84:2B:C2:EF:FC:6D:27:9B:C4
                DirName:/CN=Easy-RSA CA
                serial:5F:60:13:44:C1:6A:C5:48:76:B2:1A:9B:01:83:16:E4:BA:8B:89:18
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Key Usage: 
                Digital Signature
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        83:a9:e1:bc:db:fa:e8:e0:00:f4:62:16:35:cd:18:f6:2d:13:
        fa:2b:09:13:4a:bc:1b:6a:70:d3:5a:fe:9b:b9:98:56:06:98:
        b7:8c:6b:25:79:45:7e:83:f9:d6:4e:ef:a0:63:a5:0d:e3:a5:
        ad:51:95:69:05:60:c3:7c:fd:a6:f4:f8:e6:5a:10:81:a7:b2:
        a5:b6:36:36:62:6b:a6:13:f7:49:e4:3d:24:c2:24:74:4b:88:
        60:fe:46:52:49:59:37:93:38:76:b6:cc:bf:00:b9:47:aa:e0:
        2f:df:91:b8:d1:5f:41:37:5e:65:eb:82:e9:f1:44:c6:d5:f6:
        c4:79:f9:50:7e:24:b1:5d:1c:ca:f3:0a:43:e7:18:6b:8c:3a:
        e4:d0:61:7d:6a:bf:e1:bf:38:cb:cc:58:1d:39:39:1f:7d:7c:
        6f:ef:9b:f0:23:9d:dc:7f:73:b9:9b:9f:ab:ab:34:e7:1b:b4:
        e8:58:e9:0a:81:0a:01:c2:3d:1e:1b:48:7c:e4:4e:45:94:5f:
        b5:8b:12:1d:53:3a:b5:34:e1:95:fb:2b:99:21:b9:1a:56:16:
        a6:b5:67:17:79:5c:6d:66:51:5c:02:6f:56:47:69:5d:50:73:
        84:c0:d7:91:95:72:89:62:95:78:77:4a:86:c6:02:dd:b5:7d:
        a4:c2:f1:d7
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
      engineCreated: () {
        engine.initialize(
          groupIdentifier: "group.com.jinoca.vpn",
          providerBundleIdentifier: "com.jinoca.vpn.VPNExtension",
          localizedDescription: "Jinoca VPN",
        );
      },
    );
    
    // Adicionamos os dois ouvintes separados agora
    engine.status.listen((VpnStatus? s) {
      if (mounted) setState(() { status = s; });
    });
    
    engine.vPNStage.listen((VPNStage? s) {
      if (mounted) setState(() { stage = s; });
    });
  }

  void _toggleVpn() {
    if (stage == VPNStage.connected) {
      engine.disconnect();
    } else {
      engine.connect(_getSecureConfig(), "JinocaVPN", username: "", password: "", certIsRequired: true);
    }
  }

  String get _stateText {
    if (stage == VPNStage.connected) return 'CONECTADO';
    if (stage == VPNStage.disconnected || stage == null) return 'TOCAR PARA CONECTAR';
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
