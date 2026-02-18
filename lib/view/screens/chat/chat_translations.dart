class ChatTranslations {
  // Get translation based on language code
  static String get(String key, String language) {
    final translations = _translations[key];
    if (translations == null) return key;
    return translations[language] ?? translations['EN'] ?? key;
  }

  // Translation map for all chat screen text
  static final Map<String, Map<String, String>> _translations = {
    // ========== PRAYER GUIDANCE TRANSLATIONS ==========
    'prayer_guidance_title': {
      'EN': 'Prayer Guidance',
      'HI': 'प्रार्थना मार्गदर्शन',
      'TN': 'ஜெப வழிகாட்டுதல்',
      'PT': 'Orientação de Oração',
    },
    'get_guidance_need': {
      'EN': 'Get Guidance Based On Your Need...',
      'HI': 'अपनी आवश्यकता के आधार पर मार्गदर्शन प्राप्त करें...',
      'TN': 'உங்கள் தேவையின் அடிப்படையில் வழிகாட்டுதலைப் பெறுங்கள்...',
      'PT': 'Obtenha orientação com base na sua necessidade...',
    },
    'custom_prayer': {
      'EN': 'Custom Prayer',
      'HI': 'कस्टम प्रार्थना',
      'TN': 'தனிப்பயன் ஜெபம்',
      'PT': 'Oração personalizada',
    },
    'prayer_thanksgiving': {
      'EN': 'Thanksgiving',
      'HI': 'धन्यवाद',
      'TN': 'நன்றியறிதல்',
      'PT': 'Ação de graças',
    },
    'prayer_forgiveness': {
      'EN': 'Forgiveness',
      'HI': 'क्षमा',
      'TN': 'மன்னிப்பு',
      'PT': 'Perdão',
    },
    'prayer_guidance': {
      'EN': 'Guidance',
      'HI': 'मार्गदर्शन',
      'TN': 'வழிகாட்டுதல்',
      'PT': 'Orientação',
    },
    'prayer_anxiety_peace': {
      'EN': 'Anxiety & Peace',
      'HI': 'चिंता और शांति',
      'TN': 'கவலை & அமைதி',
      'PT': 'Ansiedade e paz',
    },
    'prayer_healing': {'EN': 'Healing', 'HI': 'उपचार', 'TN': 'குணப்படுத்துதல்', 'PT': 'Cura'},
    'prayer_family': {'EN': 'Family', 'HI': 'परिवार', 'TN': 'குடும்பம்', 'PT': 'Família'},
    'prayer_strength': {'EN': 'Strength', 'HI': 'शक्ति', 'TN': 'பலம்', 'PT': 'Força'},
    'prayer_protection': {
      'EN': 'Protection',
      'HI': 'सुरक्षा',
      'TN': 'பாதுகாப்பு',
      'PT': 'Proteção',
    },
    'prayer_feelings': {'EN': 'Hope', 'HI': 'भावनाएं', 'TN': 'உணர்வுகள்', 'PT': 'Esperança'},
    'amen_button': {'EN': 'AMEN', 'HI': 'आमीन', 'TN': 'ஆமென்', 'PT': 'AMÉM'},

    // ========== CHAT SCREEN TRANSLATIONS ==========
    // App bar & titles
    'faith_chat': {
      'EN': 'Faith Chat',
      'HI': 'विश्वास चैट',
      'TN': 'நம்பிக்கை அரட்டை',
      'PT': 'Chat de Fé',
    },
    'faith_answers': {
      'EN': 'Faith Answers',
      'HI': 'विश्वास उत्तर',
      'TN': 'நம்பிக்கை பதில்கள்',
      'PT': 'Respostas de Fé',
    },
    'get_guidance': {
      'EN': 'Get Guidance Based On Your Need...',
      'HI': 'अपनी आवश्यकता के आधार पर मार्गदर्शन प्राप्त करें...',
      'TN': 'உங்கள் தேவையின் அடிப்படையில் வழிகாட்டுதலைப் பெறுங்கள்...',
      'PT': 'Obtenha orientação com base na sua necessidade...',
    },

    // Menu items
    'new_chat': {
      'EN': 'New Chat',
      'HI': 'नई चैट',
      'TN': 'புதிய அரட்டை',
      'PT': 'Nova conversa',
    },
    'history': {
      'EN': 'History',
      'HI': 'इतिहास',
      'TN': 'வரலாறு',
      'PT': 'Histórico',
    },
    'recent_conversations': {
      'EN': 'RECENT CONVERSATIONS',
      'HI': 'हाल की बातचीत',
      'TN': 'சமீபத்திய உரையாடல்கள்',
      'PT': 'CONVERSAS RECENTES',
    },

    // Topic questions
    'topic_anxious': {
      'EN': 'I feel anxious',
      'HI': 'मुझे चिंता है',
      'TN': 'எனக்கு கவலையாக உள்ளது',
      'PT': 'Sinto-me ansioso',
    },
    'question_anxious': {
      'EN': 'Show me verses that calm anxiety..',
      'HI': 'मुझे चिंता शांत करने वाले छंद दिखाएं..',
      'TN': 'கவலையை அமைதிப்படுத்தும் வசனங்களைக் காட்டு..',
      'PT': 'Mostre-me versículos que acalmam a ansiedade..',
    },
    'topic_confused': {
      'EN': 'I\'m confused',
      'HI': 'मैं भ्रमित हूं',
      'TN': 'நான் குழப்பமடைந்துள்ளேன்',
      'PT': 'Estou confuso',
    },
    'question_confused': {
      'EN': 'Show me verses about clarity and direction..',
      'HI': 'मुझे स्पष्टता और दिशा के बारे में छंद दिखाएं..',
      'TN': 'தெளிவு மற்றும் திசையைப் பற்றிய வசனங்களைக் காட்டு..',
      'PT': 'Mostre-me versículos sobre clareza e direção..',
    },
    'topic_strength': {
      'EN': 'I need strength',
      'HI': 'मुझे शक्ति चाहिए',
      'TN': 'எனக்கு பலம் தேவை',
      'PT': 'Preciso de força',
    },
    'question_strength': {
      'EN': 'How can I stay strong spiritually?',
      'HI': 'मैं आध्यात्मिक रूप से मजबूत कैसे रह सकता हूं?',
      'TN': 'நான் ஆன்மீக ரீதியாக வலிமையாக எப்படி இருக்க முடியும்?',
      'PT': 'Como posso permanecer forte espiritualmente?',
    },
    'topic_lost': {
      'EN': 'I feel lost',
      'HI': 'मैं खोया हुआ महसूस करता हूं',
      'TN': 'நான் தொலைந்து போனதாக உணர்கிறேன்',
      'PT': 'Sinto-me perdido',
    },
    'question_lost': {
      'EN': 'How does God guide me when I feel lost?',
      'HI':
          'जब मैं खोया हुआ महसूस करता हूं तो भगवान मुझे कैसे मार्गदर्शन करते हैं?',
      'TN':
          'நான் தொலைந்து போனதாக உணரும்போது கடவுள் என்னை எப்படி வழிநடத்துகிறார்?',
      'PT': 'Como Deus me guia quando me sinto perdido?',
    },
    'topic_stuck': {
      'EN': 'I feel stuck',
      'HI': 'मैं फंसा हुआ महसूस करता हूं',
      'TN': 'நான் சிக்கியதாக உணர்கிறேன்',
      'PT': 'Sinto-me preso',
    },
    'question_stuck': {
      'EN': 'Encourage me when everything feels heavy..',
      'HI': 'जब सब कुछ भारी लगे तो मुझे प्रोत्साहित करें..',
      'TN': 'எல்லாம் கனமாக உணரும்போது என்னை ஊக்குவியுங்கள்..',
      'PT': 'Encoraje-me quando tudo parecer pesado..',
    },
    'topic_promises': {
      'EN': 'God\'s promises',
      'HI': 'भगवान के वादे',
      'TN': 'கடவுளின் வாக்குறுதிகள்',
      'PT': 'Promessas de Deus',
    },
    'question_promises': {
      'EN': 'What promises remind me I\'m not alone?',
      'HI': 'कौन से वादे मुझे याद दिलाते हैं कि मैं अकेला नहीं हूं?',
      'TN': 'நான் தனியாக இல்லை என்று எனக்கு நினைவூட்டும் வாக்குறுதிகள் என்ன?',
      'PT': 'Que promessas me lembram que não estou sozinho?',
    },

    // Verse context labels
    'verse_context': {
      'EN': 'About this verse:',
      'HI': 'इस छंद के बारे में:',
      'TN': 'இந்த வசனத்தைப் பற்றி:',
      'PT': 'Sobre este versículo:',
    },
    'tap_to_ask': {
      'EN': 'Tap to ask a question...',
      'HI': 'प्रश्न पूछने के लिए टैप करें...',
      'TN': 'கேள்வி கேட்க தட்டவும்...',
      'PT': 'Toque para fazer uma pergunta...',
    },
    'type_message': {
      'EN': 'Type your message...',
      'HI': 'अपना संदेश लिखें...',
      'TN': 'உங்கள் செய்தியை தட்டச்சு செய்யுங்கள்...',
      'PT': 'Digite sua mensagem...',
    },

    // Actions & buttons
    'copy': {
      'EN': 'Copy',
      'HI': 'कॉपी करें',
      'TN': 'நகலெடு',
      'PT': 'Copiar',
    },
    'share': {
      'EN': 'Share',
      'HI': 'साझा करें',
      'TN': 'பகிர்',
      'PT': 'Partilhar',
    },
    'copied': {
      'EN': 'Copied to clipboard',
      'HI': 'क्लिपबोर्ड पर कॉपी किया गया',
      'TN': 'கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது',
      'PT': 'Copiado para a área de transferência',
    },

    // Error & status messages
    'no_internet': {
      'EN': 'No internet connection',
      'HI': 'कोई इंटरनेट कनेक्शन नहीं',
      'TN': 'இணைய இணைப்பு இல்லை',
      'PT': 'Sem ligação à internet',
    },
    'error_occurred': {
      'EN': 'An error occurred',
      'HI': 'एक त्रुटि हुई',
      'TN': 'ஒரு பிழை ஏற்பட்டது',
      'PT': 'Ocorreu um erro',
    },
    'insufficient_credits': {
      'EN': 'Insufficient credits',
      'HI': 'अपर्याप्त क्रेडिट',
      'TN': 'போதுமான கடன் இல்லை',
      'PT': 'Créditos insuficientes',
    },

    // New chat dialog
    'start_new_chat': {
      'EN': 'Start New Chat',
      'HI': 'नई चैट शुरू करें',
      'TN': 'புதிய அரட்டையைத் தொடங்கவும்',
      'PT': 'Iniciar nova conversa',
    },
    'new_chat_confirmation': {
      'EN':
          'Are you sure you want to start a new chat? The current conversation will be cleared.',
      'HI':
          'क्या आप वाकई नई चैट शुरू करना चाहते हैं? वर्तमान वार्तालाप साफ हो जाएगा।',
      'TN':
          'நீங்கள் நிச்சயமாக புதிய அரட்டையைத் தொடங்க விரும்புகிறீர்களா? தற்போதைய உரையாடல் அழிக்கப்படும்.',
      'PT': 'Tem certeza que quer iniciar uma nova conversa? A conversa atual será apagada.',
    },
    'cancel': {
      'EN': 'Cancel',
      'HI': 'रद्द करें',
      'TN': 'ரத்து செய்',
      'PT': 'Cancelar',
    },
    'proceed': {
      'EN': 'Proceed',
      'HI': 'आगे बढ़ें',
      'TN': 'தொடரவும்',
      'PT': 'Continuar',
    },

    // Language selector
    'select_language': {
      'EN': 'Select Language',
      'HI': 'भाषा चुनें',
      'TN': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'PT': 'Selecionar idioma',
    },
    'language_english': {
      'EN': 'English',
      'HI': 'अंग्रेज़ी',
      'TN': 'ஆங்கிலம்',
      'PT': 'Inglês',
    },
    'language_hindi': {
      'EN': 'Hindi',
      'HI': 'हिन्दी',
      'TN': 'இந்தி',
      'PT': 'Hindi',
    },
    'language_tamil': {
      'EN': 'Tamil',
      'HI': 'तमिल',
      'TN': 'தமிழ்',
      'PT': 'Tâmil',
    },

    // Input placeholders
    'ask_anything': {
      'EN': 'Ask anything here...',
      'HI': 'यहाँ कुछ भी पूछें...',
      'TN': 'இங்கே எதையும் கேளுங்கள்...',
      'PT': 'Pergunte qualquer coisa aqui...',
    },
    'listening': {
      'EN': 'Listening...',
      'HI': 'सुन रहा है...',
      'TN': 'கேட்கிறது...',
      'PT': 'A ouvir...',
    },
    'seeking_guidance': {
      'EN': 'Seeking guidance...',
      'HI': 'मार्गदर्शन खोज रहा है...',
      'TN': 'வழிகாட்டுதலைத் தேடுகிறது...',
      'PT': 'A procurar orientação...',
    },
    'new_chat_long': {
      'EN': 'New Chat ',
      'HI': 'नई चैट ',
      'TN': 'புதிய அரட்டை ',
      'PT': 'Nova conversa ',
    },

    // Suggestions section (chat_screen uses 'Suggestions' with capital S for heading)
    'Suggestions': {
      'EN': 'Suggestions',
      'HI': 'सुझाव',
      'TN': 'பரிந்துரைகள்',
      'PT': 'Sugestões',
    },
    'suggestions': {
      'EN': 'Suggestions',
      'HI': 'सुझाव',
      'TN': 'பரிந்துரைகள்',
      'PT': 'Sugestões',
    },
    'view_all': {
      'EN': 'View all',
      'HI': 'सभी देखें',
      'TN': 'அனைத்தையும் காண்க',
      'PT': 'Ver tudo',
    },

    // Verse context
    'ask_questions_verse': {
      'EN': 'Ask questions about this verse...',
      'HI': 'इस छंद के बारे में प्रश्न पूछें...',
      'TN': 'இந்த வசனத்தைப் பற்றி கேள்விகள் கேளுங்கள்...',
      'PT': 'Faça perguntas sobre este versículo...',
    },
    'suggestions_colon': {
      'EN': 'Suggestions :',
      'HI': 'सुझाव :',
      'TN': 'பரிந்துரைகள் :',
      'PT': 'Sugestões :',
    },
    'explain_verse': {
      'EN': 'Explain this verse',
      'HI': 'इस छंद को समझाएं',
      'TN': 'இந்த வசனத்தை விளக்குங்கள்',
      'PT': 'Explique este versículo',
    },
    'verse_daily_life': {
      'EN': 'What does this verse mean for my daily life?',
      'HI': 'मेरे दैनिक जीवन के लिए इस छंद का क्या अर्थ है?',
      'TN': 'என் அன்றாட வாழ்க்கைக்கு இந்த வசனம் என்ன அர்த்தம்?',
      'PT': 'O que significa este versículo para a minha vida diária?',
    },
    'verse_teach_about': {
      'EN': 'What does this verse teach about',
      'HI': 'यह छंद किस बारे में सिखाता है',
      'TN': 'இந்த வசனம் என்ன கற்பிக்கிறது',
      'PT': 'O que é que este versículo ensina sobre',
    },
    'god_say_about': {
      'EN': 'What does God say about',
      'HI': 'भगवान किस बारे में कहते हैं',
      'TN': 'கடவுள் என்ன சொல்கிறார்',
      'PT': 'O que diz Deus sobre',
    },
    'what_god_say_fear': {
      'EN': 'What does God say about fear?',
      'HI': 'भय के बारे में भगवान क्या कहते हैं?',
      'TN': 'பயத்தைப் பற்றி கடவுள் என்ன சொல்கிறார்?',
      'PT': 'O que diz Deus sobre o medo?',
    },
    'how_apply_teaching': {
      'EN': 'How can I apply this teaching?',
      'HI': 'मैं इस शिक्षा को कैसे लागू कर सकता हूं?',
      'TN': 'இந்த போதனையை நான் எவ்வாறு பயன்படுத்துவது?',
      'PT': 'Como posso aplicar este ensinamento?',
    },

    // Example questions
    'example_forgive': {
      'EN': 'How do I forgive someone who hurt me?',
      'HI': 'मैं किसी ऐसे व्यक्ति को कैसे माफ करूं जिसने मुझे चोट पहुंचाई?',
      'TN': 'என்னை காயப்படுத்தியவரை நான் எவ்வாறு மன்னிப்பது?',
      'PT': 'Como posso perdoar alguém que me magoou?',
    },
    'example_purpose': {
      'EN': 'What is God\'s purpose for my life?',
      'HI': 'मेरे जीवन के लिए भगवान का उद्देश्य क्या है?',
      'TN': 'என் வாழ்க்கைக்கான கடவுளின் நோக்கம் என்ன?',
      'PT': 'Qual é o propósito de Deus para a minha vida?',
    },

    // Dynamic suggestion questions
    'how_apply_verse_life': {
      'EN': 'How can I apply this verse in my life?',
      'HI': 'मैं अपने जीवन में इस छंद को कैसे लागू कर सकता हूं?',
      'TN': 'என் வாழ்க்கையில் இந்த வசனத்தை எவ்வாறு பயன்படுத்துவது?',
      'PT': 'Como posso aplicar este versículo na minha vida?',
    },
    'how_apply_this': {
      'EN': 'How can I apply this?',
      'HI': 'मैं इसे कैसे लागू कर सकता हूं?',
      'TN': 'இதை நான் எவ்வாறு பயன்படுத்துவது?',
      'PT': 'Como posso aplicar isto?',
    },
    'explain_more': {
      'EN': 'Can you explain more?',
      'HI': 'क्या आप और समझा सकते हैं?',
      'TN': 'மேலும் விளக்க முடியுமா?',
      'PT': 'Pode explicar mais?',
    },
    'explain_more_about': {
      'EN': 'Can you explain more about',
      'HI': 'क्या आप इसके बारे में और समझा सकते हैं',
      'TN': 'இதைப் பற்றி மேலும் விளக்க முடியுமா',
      'PT': 'Pode explicar mais sobre',
    },
    'why_verse_important': {
      'EN': 'Why is this verse important?',
      'HI': 'यह छंद क्यों महत्वपूर्ण है?',
      'TN': 'இந்த வசனம் ஏன் முக்கியமானது?',
      'PT': 'Por que é este versículo importante?',
    },
    'why_important': {
      'EN': 'Why is this important?',
      'HI': 'यह क्यों महत्वपूर्ण है?',
      'TN': 'இது ஏன் முக்கியமானது?',
      'PT': 'Por que é isto importante?',
    },
    'explain_verse_further': {
      'EN': 'Can you explain this verse further?',
      'HI': 'क्या आप इस छंद को और अधिक समझा सकते हैं?',
      'TN': 'இந்த வசனத்தை மேலும் விளக்க முடியுமா?',
      'PT': 'Pode explicar este versículo mais a fundo?',
    },
    'explain_further': {
      'EN': 'Can you explain this further?',
      'HI': 'क्या आप इसे और अधिक समझा सकते हैं?',
      'TN': 'இதை மேலும் விளக்க முடியுமா?',
      'PT': 'Pode explicar isto mais a fundo?',
    },
    'tell_more_verse': {
      'EN': 'Tell me more about this verse',
      'HI': 'इस छंद के बारे में मुझे और बताएं',
      'TN': 'இந்த வசனத்தைப் பற்றி மேலும் சொல்லுங்கள்',
      'PT': 'Diga-me mais sobre este versículo',
    },
    'what_else_verse_teach': {
      'EN': 'What else does this verse teach?',
      'HI': 'यह छंद और क्या सिखाता है?',
      'TN': 'இந்த வசனம் வேறு என்ன கற்பிக்கிறது?',
      'PT': 'O que mais ensina este versículo?',
    },
    'what_else_know': {
      'EN': 'What else should I know?',
      'HI': 'मुझे और क्या जानना चाहिए?',
      'TN': 'நான் வேறு என்ன தெரிந்து கொள்ள வேண்டும்?',
      'PT': 'O que mais devo saber?',
    },
    'how_verse_relate_to': {
      'EN': 'How does this verse relate to',
      'HI': 'यह छंद इससे कैसे संबंधित है',
      'TN': 'இந்த வசனம் இதனுடன் எவ்வாறு தொடர்புடையது',
      'PT': 'Como é que este versículo se relaciona com',
    },
    'how_relate_to': {
      'EN': 'How does this relate to',
      'HI': 'यह इससे कैसे संबंधित है',
      'TN': 'இது இதனுடன் எவ்வாறு தொடர்புடையது',
      'PT': 'Como é que isto se relaciona com',
    },
    'what_steps_take': {
      'EN': 'What steps should I take?',
      'HI': 'मुझे कौन से कदम उठाने चाहिए?',
      'TN': 'நான் என்ன படிகளை எடுக்க வேண்டும்?',
      'PT': 'Que passos devo dar?',
    },
    'what_practical_steps': {
      'EN': 'What practical steps can I take?',
      'HI': 'मैं कौन से व्यावहारिक कदम उठा सकता हूं?',
      'TN': 'நான் என்ன நடைமுறை படிகளை எடுக்க முடியும்?',
      'PT': 'Que passos práticos posso dar?',
    },
  };
}
