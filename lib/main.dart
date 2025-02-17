import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/painting.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Beauty',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Inter',
      ),
      home: const HandAnalysisPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HandAnalysisPage extends StatefulWidget {
  const HandAnalysisPage({Key? key}) : super(key: key);

  @override
  _HandAnalysisPageState createState() => _HandAnalysisPageState();
}

class _HandAnalysisPageState extends State<HandAnalysisPage> {
  File? _image;
  Uint8List? _processedImageBytes;
  bool _isLoading = false;
  Color _selectedColor = Color(0xFFFF8B7E);

  // Default colors
  final List<Color> defaultColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  // Add new color lists for nude and red tones
  final List<Color> nudeColors = [
    Color(0xFFE6BE8A),
    Color(0xFFD1A278),
    Color(0xFFC68642),
    Color(0xFFAE7242),
    Color(0xFF85563C),
    Color(0xFFF1C27D),
    Color(0xFFFFDBAC),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
  ];

  final List<Color> redColors = [
    Color(0xFFFF0000),
    Color(0xFFDC143C),
    Color(0xFFB22222),
    Color(0xFF8B0000),
    Color(0xFF800000),
    Color(0xFFFF6347),
    Color(0xFFFF4500),
    Color(0xFFFF69B4),
    Color(0xFFC71585),
    Color(0xFF990000),
  ];

  Future<void> _getImage() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _processedImageBytes = null;
        });
      }
    } else {
      _showPermissionDialog(
          'Camera permission denied. Please allow camera access.');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('https://virtualtryon-totu.onrender.com/process-image');
      final request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));

      String colorString =
          '${_selectedColor.red},${_selectedColor.green},${_selectedColor.blue}';
      request.fields['color'] = colorString;

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        setState(() {
          _processedImageBytes = bytes;
          _isLoading = false;
        });
      } else {
        _showError('Image upload failed. Server error.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error occurred while uploading image: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Color(0xFF1E3D59)),
        ),
        content: Text(
          message,
          style: TextStyle(color: Color(0xFF1E3D59).withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFFF8B7E))),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings',
                style: TextStyle(color: Color(0xFFFF8B7E))),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Select Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: 100,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: _selectedColor.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          ...defaultColors,
                          ...nudeColors,
                          ...redColors,
                        ].map((color) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                            this.setState(() {}); // Update the main UI
                          },
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedColor == color
                                      ? color.withOpacity(0.8)
                                      : color.withOpacity(0.4),
                                  blurRadius: _selectedColor == color ? 6 : 4,
                                  spreadRadius: _selectedColor == color ? 2 : 1,
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                _buildImageArea(),
                SizedBox(height: 20),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFFFFC0B6),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.brush, color: Color(0xFFFF8B7E), size: 24),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Create Beauty',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Playfair Display',
                letterSpacing: 1.2,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      Color(0xFFFF8B7E),
                      Color(0xFFFFC0B6),
                      Color(0xFFFF8B7E),
                    ],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                shadows: [
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/small_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Pick your nail color',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _showColorPicker,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _selectedColor.withOpacity(0.6),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.color_lens, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildImageArea() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFFFFF5F3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8B7E)),
        ),
      );
    }

    if (_processedImageBytes != null) {
      return Image.memory(
        _processedImageBytes!,
        fit: BoxFit.cover,
      );
    }

    if (_image != null) {
      return Image.file(
        _image!,
        fit: BoxFit.cover,
      );
    }

    // Default image when no photo is taken or processed
    return Image.asset(
      'assets/default_hand.png',
      fit: BoxFit.cover,
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _getImage,
          child: Text('TAKE HAND PHOTO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF8B7E),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        SizedBox(height: 10),
        OutlinedButton(
          onPressed: _image != null && !_isLoading ? _uploadImage : null,
          child: Text('APPLY THE COLOR'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Color(0xFFFF8B7E),
            foregroundColor: Colors.white,
            side: BorderSide(color: Color(0xFFFF8B7E)),
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

