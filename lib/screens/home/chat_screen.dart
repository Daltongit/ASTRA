import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AnimationController _animController;
  
  bool _isListening = false;
  bool _isSpeaking = false;
  String _text = '';
  String? _sessionId;
  Timer? _sessionTimer;
  int _sessionDuration = 0;
  final int _maxSessionDuration = 1800;
  
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _initializeTts();
    _createSession();
    _startSessionTimer();
  }

  void _initializeTts() async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.1);
    
    final voices = await _flutterTts.getVoices;
    if (voices != null) {
      for (var voice in voices) {
        if (voice['name'].toString().contains('es') && 
            voice['name'].toString().contains('female')) {
          await _flutterTts.setVoice({'name': voice['name'], 'locale': voice['locale']});
          break;
        }
      }
    }
    
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    
    _speakWelcome();
  }

  Future<void> _speakWelcome() async {
    const welcomeMessage = 'Hola, soy ASTRA, tu compañero de bienestar. '
        'Estoy aquí para escucharte y apoyarte. ¿Cómo te sientes hoy?';
    await _speak(welcomeMessage);
    _addMessage('assistant', welcomeMessage);
  }

  Future<void> _createSession() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('therapy_sessions')
          .insert({
            'user_id': user.id,
            'session_status': 'active',
          })
          .select()
          .single();

      setState(() => _sessionId = response['id']);
    } catch (e) {
      debugPrint('Error creating session: $e');
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _sessionDuration++);
      
      if (_sessionDuration >= _maxSessionDuration) {
        _endSession(autoEnd: true);
      }
    });
  }

  void _addMessage(String speaker, String text) {
    setState(() {
      _messages.add({'speaker': speaker, 'text': text});
    });
    
    if (_sessionId != null) {
      Supabase.instance.client.from('conversation_messages').insert({
        'session_id': _sessionId,
        'speaker': speaker,
        'message_text': text,
      });
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            if (_text.isNotEmpty) {
              _processUserInput(_text);
            }
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() => _text = result.recognizedWords);
          },
          localeId: 'es_ES',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _processUserInput(String userText) async {
    _addMessage('user', userText);
    
    final aiResponse = await AIService.generateResponse(userText, _messages);
    await _speak(aiResponse);
    _addMessage('assistant', aiResponse);
    
    setState(() => _text = '');
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _endSession({bool autoEnd = false}) async {
    _sessionTimer?.cancel();
    
    if (autoEnd) {
      const farewell = 'Lamentablemente nuestra sesión ha llegado a su fin. '
          'Ha sido un placer acompañarte hoy. Cuídate mucho y nos vemos pronto.';
      await _speak(farewell);
      await Future.delayed(const Duration(seconds: 5));
    }
    
    if (_sessionId != null) {
      await Supabase.instance.client
          .from('therapy_sessions')
          .update({
            'ended_at': DateTime.now().toIso8601String(),
            'duration_seconds': _sessionDuration,
            'session_status': 'completed',
          })
          .eq('id', _sessionId!);
      
      await _generateEmotionAnalysis();
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _generateEmotionAnalysis() async {
    if (_sessionId == null) return;
    
    final analysis = AIService.analyzeEmotions(_messages);
    
    await Supabase.instance.client.from('emotion_analysis').insert({
      'session_id': _sessionId,
      ...analysis,
    });
    
    final recommendations = AIService.generateRecommendations(analysis);
    for (var rec in recommendations) {
      await Supabase.instance.client.from('recommendations').insert({
        'session_id': _sessionId,
        'recommendation_text': rec['text'],
        'category': rec['category'],
        'priority': rec['priority'],
      });
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _speech.stop();
    _flutterTts.stop();
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0221), Color(0xFF1A0033), Color(0xFF6A0DAD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_sessionDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_maxSessionDuration - _sessionDuration) ~/ 60} min restantes',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Esfera animada reactiva
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final size = _isSpeaking ? 220.0 : 200.0;
                  return Container(
                    width: size + (_animController.value * 20),
                    height: size + (_animController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                          blurRadius: _isSpeaking ? 80 : 40,
                          spreadRadius: _isSpeaking ? 20 : 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isSpeaking 
                            ? Icons.volume_up_rounded 
                            : _isListening 
                                ? Icons.mic_rounded 
                                : Icons.auto_awesome_rounded,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              if (_text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const Spacer(),
              
              Padding(
                padding: const EdgeInsets.all(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton.extended(
                      onPressed: () => _endSession(),
                      backgroundColor: Colors.red.shade700,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Finalizar'),
                    ),
                    
                    FloatingActionButton.large(
                      onPressed: _listen,
                      backgroundColor: _isListening 
                          ? Colors.red 
                          : Theme.of(context).primaryColor,
                      child: Icon(
                        _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
