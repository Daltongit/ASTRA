import 'dart:math';

class AIService {
  static Future<String> generateResponse(
    String userInput,
    List<Map<String, dynamic>> conversationHistory,
  ) async {
    // Simulación de procesamiento de IA
    await Future.delayed(const Duration(milliseconds: 500));
    
    final lowerInput = userInput.toLowerCase();
    
    // Detección de emociones y respuestas contextuales
    if (lowerInput.contains('triste') || lowerInput.contains('mal') || 
        lowerInput.contains('deprimido') || lowerInput.contains('solo')) {
      return _getSadnessResponse();
    } else if (lowerInput.contains('estresado') || lowerInput.contains('ansiedad') || 
               lowerInput.contains('preocupado') || lowerInput.contains('nervioso')) {
      return _getStressResponse();
    } else if (lowerInput.contains('feliz') || lowerInput.contains('bien') || 
               lowerInput.contains('contento') || lowerInput.contains('alegre')) {
      return _getHappinessResponse();
    } else if (lowerInput.contains('enojado') || lowerInput.contains('molesto') || 
               lowerInput.contains('furioso') || lowerInput.contains('irritado')) {
      return _getAngerResponse();
    } else if (lowerInput.contains('trabajo') || lowerInput.contains('estudio') || 
               lowerInput.contains('escuela') || lowerInput.contains('universidad')) {
      return _getWorkStressResponse();
    } else if (lowerInput.contains('familia') || lowerInput.contains('pareja') || 
               lowerInput.contains('amigos') || lowerInput.contains('relación')) {
      return _getRelationshipResponse();
    } else {
      return _getGenericResponse();
    }
  }
  
  static String _getSadnessResponse() {
    final responses = [
      'Entiendo que te sientas triste. Es completamente válido sentirse así. '
      '¿Quieres contarme qué ha estado pasando en tu vida últimamente?',
      'Lamento que estés pasando por un momento difícil. Recuerda que estos sentimientos '
      'son temporales. ¿Hay algo específico que te esté afectando?',
      'La tristeza es una emoción natural. Gracias por compartir conmigo cómo te sientes. '
      '¿Cómo ha sido tu día hoy?',
    ];
    return responses[Random().nextInt(responses.length)];
  }
  
  static String _getStressResponse() {
    final responses = [
      'El estrés puede ser abrumador. Vamos a trabajar juntos para identificar qué lo causa. '
      '¿Puedes describir qué situaciones te generan más ansiedad?',
      'Entiendo que te sientas estresado. Respirar profundamente puede ayudar. '
      '¿Has intentado alguna técnica de relajación últimamente?',
      'El estrés es una respuesta normal, pero no tienes que manejarlo solo. '
      '¿Qué aspectos de tu vida te generan más presión?',
    ];
    return responses[Random().nextInt(responses.length)];
  }
  
  static String _getHappinessResponse() {
    final responses = [
      '¡Me alegra mucho saber que te sientes bien! Es importante celebrar estos momentos. '
      '¿Qué cosas positivas han ocurrido recientemente?',
      'Qué maravilloso que te sientas feliz. Cuéntame más sobre lo que te hace sentir así.',
      'Es genial escuchar que estás contento. Mantener esta energía positiva es importante. '
      '¿Cómo has logrado sentirte así?',
    ];
    return responses[Random().nextInt(responses.length)];
  }
  
  static String _getAngerResponse() {
    final responses = [
      'Entiendo que estés molesto. El enojo es una emoción válida. '
      '¿Qué situación te ha hecho sentir así?',
      'La frustración puede ser intensa. Estoy aquí para escucharte. '
      '¿Qué te gustaría cambiar en esta situación?',
      'Es natural sentir enojo a veces. Hablemos sobre lo que lo está causando. '
      '¿Puedes contarme más al respecto?',
    ];
    return responses[Random().nextInt(responses.length)];
  }
  
  static String _getWorkStressResponse() {
    final responses = [
      'El trabajo puede ser muy demandante. ¿Cómo ha sido tu carga laboral últimamente?',
      'Los estudios requieren mucho esfuerzo. ¿Te sientes abrumado con tus responsabilidades?',
      'Equilibrar trabajo y vida personal es un desafío. ¿Cómo te sientes respecto a eso?',
    ];
    return responses[Random().nextInt(responses.length)];
  }
  
  static String _getRelationshipResponse() {
    final responses = [
      'Las relaciones son una parte importante de nuestra vida. '
      '¿Cómo te sientes con las personas cercanas a ti?',
      'Los vínculos familiares pueden ser complejos. ¿Hay algo específico que te preocupe?',
      'Las relaciones requieren trabajo y comunicación. '
      '¿Cómo ha sido tu conexión con los demás últimamente?',
    ];
    return responses[Random().nextInt(responses.length)];
  }
  
  static String _getGenericResponse() {
    final responses = [
      'Gracias por compartir eso conmigo. ¿Cómo te hace sentir esta situación?',
      'Entiendo. Cuéntame más sobre cómo has estado últimamente.',
      'Interesante. ¿Qué más te gustaría compartir conmigo hoy?',
      'Estoy aquí para escucharte. ¿Hay algo más en tu mente?',
    ];
    return responses[Random().nextInt(responses.length)];
  }
  
  static Map<String, dynamic> analyzeEmotions(List<Map<String, dynamic>> messages) {
    double happiness = 50.0;
    double sadness = 20.0;
    double stress = 30.0;
    double anxiety = 25.0;
    double anger = 15.0;
    
    // Análisis básico de palabras clave en los mensajes del usuario
    for (var message in messages) {
      if (message['speaker'] == 'user') {
        final text = message['text'].toString().toLowerCase();
        
        if (text.contains('feliz') || text.contains('bien') || text.contains('alegre')) {
          happiness += 10;
          sadness -= 5;
        }
        if (text.contains('triste') || text.contains('mal') || text.contains('deprimido')) {
          sadness += 10;
          happiness -= 5;
        }
        if (text.contains('estresado') || text.contains('preocupado')) {
          stress += 10;
          anxiety += 5;
        }
        if (text.contains('ansiedad') || text.contains('nervioso')) {
          anxiety += 10;
          stress += 5;
        }
        if (text.contains('enojado') || text.contains('molesto')) {
          anger += 10;
        }
      }
    }
    
    // Normalizar valores entre 0 y 100
    happiness = happiness.clamp(0, 100);
    sadness = sadness.clamp(0, 100);
    stress = stress.clamp(0, 100);
    anxiety = anxiety.clamp(0, 100);
    anger = anger.clamp(0, 100);
    
    String overallMood;
    if (happiness > 60) {
      overallMood = 'Positivo';
    } else if (sadness > 50) {
      overallMood = 'Necesita apoyo';
    } else if (stress > 60 || anxiety > 60) {
      overallMood = 'Estresado';
    } else {
      overallMood = 'Neutral';
    }
    
    return {
      'happiness_score': happiness,
      'sadness_score': sadness,
      'stress_score': stress,
      'anxiety_score': anxiety,
      'anger_score': anger,
      'overall_mood': overallMood,
    };
  }
  
  static List<Map<String, String>> generateRecommendations(
    Map<String, dynamic> emotionAnalysis,
  ) {
    List<Map<String, String>> recommendations = [];
    
    final happiness = emotionAnalysis['happiness_score'] as double;
    final sadness = emotionAnalysis['sadness_score'] as double;
    final stress = emotionAnalysis['stress_score'] as double;
    final anxiety = emotionAnalysis['anxiety_score'] as double;
    
    if (sadness > 50) {
      recommendations.add({
        'text': 'Realiza una actividad que disfrutes, como escuchar música o ver una película',
        'category': 'activity',
        'priority': '5',
      });
      recommendations.add({
        'text': 'Conecta con un amigo o familiar cercano',
        'category': 'social',
        'priority': '4',
      });
    }
    
    if (stress > 50 || anxiety > 50) {
      recommendations.add({
        'text': 'Practica ejercicios de respiración profunda durante 5 minutos',
        'category': 'mindfulness',
        'priority': '5',
      });
      recommendations.add({
        'text': 'Sal a caminar al aire libre por 20 minutos',
        'category': 'physical',
        'priority': '4',
      });
      recommendations.add({
        'text': 'Escribe en un diario sobre tus preocupaciones',
        'category': 'creative',
        'priority': '3',
      });
    }
    
    if (happiness < 40) {
      recommendations.add({
        'text': 'Haz una lista de 3 cosas por las que estés agradecido',
        'category': 'mindfulness',
        'priority': '4',
      });
      recommendations.add({
        'text': 'Dedica tiempo a un hobby que te apasione',
        'category': 'creative',
        'priority': '3',
      });
    }
    
    recommendations.add({
      'text': 'Asegúrate de dormir al menos 7-8 horas esta noche',
      'category': 'rest',
      'priority': '5',
    });
    
    recommendations.add({
      'text': 'Practica 10 minutos de meditación o relajación',
      'category': 'mindfulness',
      'priority': '4',
    });
    
    return recommendations;
  }
}
