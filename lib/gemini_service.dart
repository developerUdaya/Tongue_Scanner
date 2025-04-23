import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import the package

// --- Securely get your API Key ---
// Using String.fromEnvironment (requires passing --dart-define=GEMINI_API_KEY=YOUR_KEY during build/run)
// const apiKey = String.fromEnvironment('GEMINI_API_KEY');
const apiKey = "369AIzaSyCciixZqmcOZf-OVphWpqSI0bbBLTkWgf0";//remove the 369 at the front
// Or use another method like flutter_dotenv

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    if (apiKey.isEmpty) {
      // Handle missing API key - throw error, show message, etc.
      print("FATAL: GEMINI_API_KEY environment variable not found.");
      throw Exception("API Key not configured.");
      // In a real app, you might want to disable functionality gracefully
    }

    _model = GenerativeModel(
      // Use gemini-pro-vision or the latest model supporting image input
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      // Optional: Configure safety settings, generation config
      // safetySettings: [ ... ],
      // generationConfig: GenerationConfig( ... ),
    );
  }

  Future<String> analyzeImage(String prompt, Uint8List imageBytes) async {
    try {
      // Create the content parts: text prompt and image data
      final content = [
        Content.multi([
          TextPart(prompt),
          // Ensure correct MIME type (jpeg, png, etc.)
          // You might need to determine this from the XFile if not always jpeg
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // Call the Gemini API
      final response = await _model.generateContent(content);

      // Check for response and text
      if (response.text == null) {
        // Handle cases where the API might have blocked the response
        // or didn't generate text (check response.promptFeedback)
        print('API Response was null or blocked.');
        print('Prompt Feedback: ${response.promptFeedback}');
        print('Finish Reason: ${response.candidates.first.finishReason}');
        print('Safety Ratings: ${response.candidates.first.safetyRatings}');
        throw Exception("Failed to get analysis from AI. The content might have been blocked.");
      }

      return response.text!;

    } on InvalidApiKey catch (e) {
       print("API Key Error: $e");
       throw Exception("Invalid API Key. Please check your configuration.");
    } catch (e) {
      // Handle other potential errors (network, API specific)
      print("Error calling Gemini API: $e");
      // Rethrow or return a user-friendly error message
      throw Exception("An error occurred while contacting the analysis service. $e");
    }
  }
}