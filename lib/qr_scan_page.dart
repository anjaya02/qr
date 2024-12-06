// lib/qr_scan_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  bool isProcessing = false;
  String resultMessage = '';
  MobileScannerController cameraController = MobileScannerController();

  // Update the API URL based on your backend setup
  final String apiUrl = 'http://10.0.2.2:5000/scan'; // For Android Emulator
  // final String apiUrl = 'http://localhost:5000/scan'; // For iOS Simulator or Web
  // final String apiUrl = 'http://YOUR_LOCAL_IP:5000/scan'; // For Physical Devices

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _sendScanData(String qrValue) async {
    setState(() {
      isProcessing = true;
      resultMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qr_value': qrValue}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          resultMessage = data['message'];
        });
      } else if (response.statusCode == 404) {
        setState(() {
          resultMessage = 'Record not found.';
        });
      } else {
        setState(() {
          resultMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = 'Failed to connect to the server.';
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _onDetect(Barcode barcode, MobileScannerArguments? args) async {
    if (isProcessing) return;

    final String? code = barcode.rawValue;
    if (code == null) {
      setState(() {
        resultMessage = 'Failed to scan QR code.';
      });
      return;
    }

    setState(() {
      isProcessing = true;
      resultMessage = '';
    });

    await _sendScanData(code);

    // Optionally, you can add a delay before allowing the next scan
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isProcessing = false;
    });
  }

  Widget _buildResult() {
    if (isProcessing) {
      return const CircularProgressIndicator();
    } else if (resultMessage.isNotEmpty) {
      return Text(
        resultMessage,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'Scan a QR code',
        style: TextStyle(fontSize: 18),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner App'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: cameraController,
              allowDuplicates: false,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _buildResult(),
            ),
          )
        ],
      ),
    );
  }
}
