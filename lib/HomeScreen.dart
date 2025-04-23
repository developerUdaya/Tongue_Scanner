import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tongue_scanner/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService(); // Instantiate your service

  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _analysisResult;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null; // Clear previous errors
      _analysisResult = null; // Clear previous results
    });
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error picking image: ${e.toString()}";
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) {
      setState(() {
        _errorMessage = "Please select an image first.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      // --- Your Specific Prompt ---
      const String prompt = """
      Analyze the provided image. Follow these steps precisely:
      1. Determine if the image clearly contains a human tongue. If not, state that a tongue is not clearly visible and stop.
      2. If a tongue is visible, assess its general appearance. Is it generally pink and smooth (normal variation allowed), or does it show significant abnormalities like deep fissures, unusual coloration (white patches, bright red, black), swelling, or unusual textures?
      3. Based *only* on the visual evidence in the image, state whether the tongue appears 'Normal' or 'Abnormal'.
      4. If assessed as 'Abnormal', briefly describe the *most prominent* visual abnormality observed (e.g., 'Deep fissures noted', 'Significant white coating observed', 'Unusually smooth and red appearance').
      5. If the abnormality strongly resembles a known condition like 'Fissured Tongue' or 'Geographic Tongue', you may mention it as a *possible* visual similarity, but emphasize this is not a diagnosis.
      6. Add a clear disclaimer: 'This is an AI analysis based on visual patterns and is NOT a medical diagnosis. Consult a healthcare professional for any health concerns.'
      Present the result clearly, following the steps above.
      """;
      // --- End of Prompt ---

      final result = await _geminiService.analyzeImage(prompt, _imageBytes!);
      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error analyzing image: ${e.toString()}";
        // Consider more specific error handling based on Gemini API errors
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tongue Analyzer (AI Demo)'),
        backgroundColor: Colors.teal, // Example color
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // --- Image Display ---
              Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: _imageBytes != null
                    ? ClipRRect( // Ensure image fits the bounds
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.memory(
                           _imageBytes!,
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) =>
                             const Center(child: Text('Error loading image')),
                        ),
                      )
                    : const Center(child: Text('No image selected')),
              ),
              const SizedBox(height: 20),

              // --- Image Picker Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[300]),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[300]),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Analyze Button ---
              ElevatedButton(
                onPressed: (_imageBytes != null && !_isLoading) ? _analyzeImage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Analyze Tongue'),
              ),
              const SizedBox(height: 30),

              // --- Loading Indicator ---
              if (_isLoading) const CircularProgressIndicator(),

              // --- Error Message ---
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // --- Analysis Result ---
              if (_analysisResult != null && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.teal[50]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Analysis:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                      ),
                      const SizedBox(height: 8),
                      Text(_analysisResult!),
                    ],
                  ),
                ),

               // --- Disclaimer ---
              const Padding(
                 padding: EdgeInsets.only(top: 40.0),
                 child: Text(
                   'Disclaimer: This app uses AI for visual pattern analysis and is for informational purposes only. It is NOT a substitute for professional medical advice, diagnosis, or treatment.',
                   style: TextStyle(fontSize: 12, color: Colors.grey),
                   textAlign: TextAlign.center,
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}