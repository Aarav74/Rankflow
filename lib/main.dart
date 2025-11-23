import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart'; // Uncomment to use Google Fonts
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const RankFlowApp());
}

// --- 1. DATA MODELS & SYLLABUS ---

enum ExamType { GATE_DA, JEE, NEET, CAT }

class Topic {
  String id;
  String title;
  bool isCompleted;

  Topic({required this.id, required this.title, this.isCompleted = false});
}

class Module {
  String title;
  Color color;
  List<Topic> topics;

  Module({required this.title, required this.color, required this.topics});

  double get progress =>
      topics.isEmpty ? 0 : topics.where((t) => t.isCompleted).length / topics.length;
}

// Detailed GATE DA 2026 Syllabus from your PDF
List<Module> getSyllabus(ExamType type) {
  if (type == ExamType.GATE_DA) {
    return [
      Module(
        title: "Probability & Statistics",
        color: const Color(0xFFFF6B6B),
        topics: [
          Topic(id: "ps1", title: "Counting: Permutations & Combinations"),
          Topic(id: "ps2", title: "Probability Axioms & Bayes Theorem"),
          Topic(id: "ps3", title: "Random Variables (Discrete & Continuous)"),
          Topic(id: "ps4", title: "Distributions: Normal, Poisson, Exponential"),
          Topic(id: "ps5", title: "Hypothesis Testing: z-test, t-test, chi-squared"),
          Topic(id: "ps6", title: "Correlation & Covariance"),
        ],
      ),
      Module(
        title: "Linear Algebra",
        color: const Color(0xFF4ECDC4),
        topics: [
          Topic(id: "la1", title: "Vector Space & Subspaces"),
          Topic(id: "la2", title: "Matrices: Rank, Determinant, Inverse"),
          Topic(id: "la3", title: "Eigenvalues & Eigenvectors (High Weightage)"),
          Topic(id: "la4", title: "Matrix Decompositions: LU, SVD"),
          Topic(id: "la5", title: "Projections & Orthogonal Matrices"),
        ],
      ),
      Module(
        title: "Calculus & Optimization",
        color: const Color(0xFFFFD93D),
        topics: [
          Topic(id: "co1", title: "Limits, Continuity, Differentiability"),
          Topic(id: "co2", title: "Maxima & Minima (Single Variable)"),
          Topic(id: "co3", title: "Taylor Series"),
        ],
      ),
      Module(
        title: "Machine Learning (Core)",
        color: const Color(0xFF6C63FF),
        topics: [
          Topic(id: "ml1", title: "Supervised: Linear & Logistic Regression"),
          Topic(id: "ml2", title: "Supervised: Decision Trees, SVM, k-NN"),
          Topic(id: "ml3", title: "Unsupervised: K-Means & PCA"),
          Topic(id: "ml4", title: "Model Eval: Bias-Variance, Cross-Validation"),
          Topic(id: "ml5", title: "Neural Networks: MLP, Feed-forward"),
        ],
      ),
      Module(
        title: "AI & Logic",
        color: const Color(0xFFAB47BC),
        topics: [
          Topic(id: "ai1", title: "Search: A*, Minimax, Alpha-Beta"),
          Topic(id: "ai2", title: "Logic: Propositional & Predicate"),
          Topic(id: "ai3", title: "Reasoning: Conditional Independence"),
        ],
      ),
      Module(
        title: "Programming & DBMS",
        color: const Color(0xFF26A69A),
        topics: [
          Topic(id: "pd1", title: "Python & Data Structures (Stack, Queue, Tree)"),
          Topic(id: "pd2", title: "Algorithms: Sorting (Merge/Quick) & Search"),
          Topic(id: "pd3", title: "DBMS: ER-Model, SQL, Normalization"),
          Topic(id: "pd4", title: "Warehousing: Schema & Hierarchies"),
        ],
      ),
    ];
  }
  // Basic placeholders for others
  return [Module(title: "Physics", color: Colors.red, topics: [])];
}

// --- 2. MAIN APP WIDGET ---

class RankFlowApp extends StatelessWidget {
  const RankFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RankFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFF6C63FF),
        // fontFamily: GoogleFonts.inter().fontFamily, // Uncomment if using GoogleFonts
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainTabNavigator(),
    );
  }
}

class MainTabNavigator extends StatefulWidget {
  const MainTabNavigator({super.key});

  @override
  State<MainTabNavigator> createState() => _MainTabNavigatorState();
}

class _MainTabNavigatorState extends State<MainTabNavigator> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const WeekendWarriorScreen(),
    const ChatbotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Study'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Weekend'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Doubts AI'),
        ],
      ),
    );
  }
}

// --- 3. DASHBOARD SCREEN ---

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ExamType selectedExam = ExamType.GATE_DA;
  late List<Module> syllabus;
  double successProbability = 0.0;

  @override
  void initState() {
    super.initState();
    syllabus = getSyllabus(selectedExam);
    _calculateProbability();
  }

  void _calculateProbability() {
    int total = syllabus.fold(0, (sum, m) => sum + m.topics.length);
    int done = syllabus.fold(0, (sum, m) => sum + m.topics.where((t) => t.isCompleted).length);
    double score = total == 0 ? 0 : (done / total);
    
    // Random fluctuation for "Realism" based on completion
    setState(() {
      successProbability = (score * 0.8 + 0.1).clamp(0.0, 0.99);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("GATE DA 2026", style: TextStyle(color: Colors.grey, letterSpacing: 1)),
                      Text("Dashboard", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.grey),
                    onPressed: () => _showSettings(context),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Success AI Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4834D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         const Text("Prediction", style: TextStyle(color: Colors.white70)),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                           child: const Text("AI MODEL v2", style: TextStyle(fontSize: 10, color: Colors.white)),
                         )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${(successProbability * 100).toInt()}%", style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
                        const Padding(padding: EdgeInsets.only(bottom: 10, left: 10), child: Text("Probability of\nTop 100 Rank", style: TextStyle(color: Colors.white70, height: 1.2))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Focus Mode Button (Wide)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusFlipClockScreen())),
                child: Container(
                  width: double.infinity,
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.timer, color: Colors.orangeAccent, size: 30),
                      SizedBox(width: 15),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Enter Focus Mode", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Landscape Flip Clock", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text("Syllabus Progress", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              ...syllabus.map((mod) => _buildModuleTile(mod)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleTile(Module mod) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          CircularProgressIndicator(
            value: mod.progress,
            backgroundColor: Colors.grey[800],
            color: mod.color,
            strokeWidth: 4,
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(mod.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
        ],
      ),
      children: mod.topics.map((t) => CheckboxListTile(
        title: Text(t.title, style: TextStyle(color: t.isCompleted ? Colors.grey : Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
        value: t.isCompleted,
        activeColor: mod.color,
        onChanged: (val) {
          setState(() {
            t.isCompleted = val!;
            _calculateProbability();
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      )).toList(),
    );
  }

  void _showSettings(BuildContext context) {
    // Placeholder for API Key settings
    showDialog(context: context, builder: (_) => const AlertDialog(title: Text("Settings"), content: Text("API Key setup in Chat Tab.")));
  }
}

// --- 4. WEEKEND WARRIOR SCREEN ---

class WeekendWarriorScreen extends StatelessWidget {
  const WeekendWarriorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weekend Protocol", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              Text("The Deep Work Zone", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildTaskCard("Saturday: 8 Hours", "Linear Algebra & SQL Deep Dive", Colors.blueAccent),
                    _buildTaskCard("Sunday: Mock Test", "Full length mock test + Analysis", Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text("Resources", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.video_library, color: Colors.purple),
                      title: const Text("Linear Algebra (Gilbert Strang)"),
                      subtitle: const Text("Downloaded for offline viewing"),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

// --- 5. FOCUS MODE & FLIP CLOCK ---

class FocusFlipClockScreen extends StatefulWidget {
  const FocusFlipClockScreen({super.key});

  @override
  State<FocusFlipClockScreen> createState() => _FocusFlipClockScreenState();
}

class _FocusFlipClockScreenState extends State<FocusFlipClockScreen> {
  Timer? _timer;
  Duration _duration = const Duration(minutes: 25);

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Lock to landscape if desired, but we will make it responsive
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_duration.inSeconds > 0) {
        setState(() => _duration = _duration - const Duration(seconds: 1));
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Layout logic
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          bool isLandscape = orientation == Orientation.landscape;
          
          return Stack(
            children: [
              // Ambient Glow
              Center(
                child: Container(
                  width: isLandscape ? 400 : 300,
                  height: isLandscape ? 200 : 300,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.2), blurRadius: 100, spreadRadius: 20)],
                  ),
                ),
              ),
              
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlipDigit(value: _duration.inMinutes, label: "MIN"),
                      const SizedBox(width: 20),
                      // Separator dots
                      Column(
                        children: [
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle)),
                          const SizedBox(height: 20),
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      FlipDigit(value: _duration.inSeconds % 60, label: "SEC"),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 20, left: 20,
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              )
            ],
          );
        },
      ),
    );
  }
}

// ANIMATED FLIP DIGIT WIDGET
class FlipDigit extends StatelessWidget {
  final int value;
  final String label;

  const FlipDigit({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    String text = value.toString().padLeft(2, '0');
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 10), blurRadius: 20)],
          ),
          child: Stack(
            children: [
              // The Card Look
              Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                  ),
                  Container(height: 2, color: Colors.black), // The split line
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF252525),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              // The Number
              Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE0E0E0),
                    fontFamily: 'Courier', // Monospace helps the flip look
                    letterSpacing: -5,
                  ),
                ),
              ),
              // Gloss Effect
              Positioned(
                top: 0, left: 0, right: 0, height: 90,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- 6. CHATBOT SCREEN (OPENROUTER) ---

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _apiController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, String>> messages = [
    {"role": "system", "content": "Hello! I am your GATE AI Tutor. Ask me about Linear Algebra, Python, or any doubt."}
  ];
  
  bool _isLoading = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('openrouter_key');
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_key', key);
    setState(() {
      _apiKey = key;
    });
    Navigator.pop(context);
  }

  void _sendMessage() async {
    if (_msgController.text.isEmpty) return;
    if (_apiKey == null || _apiKey!.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    String input = _msgController.text;
    setState(() {
      messages.add({"role": "user", "content": input});
      _isLoading = true;
      _msgController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });

    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct", // Cheap/Free model
          "messages": messages.map((m) => {"role": m["role"] == "system" ? "assistant" : m["role"], "content": m["content"]}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data['choices'][0]['message']['content'];
        setState(() {
          messages.add({"role": "system", "content": reply});
        });
      } else {
        setState(() {
          messages.add({"role": "system", "content": "Error: ${response.statusCode}. Check API Key."});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"role": "system", "content": "Connection Error."});
      });
    } finally {
      setState(() => _isLoading = false);
       Future.delayed(const Duration(milliseconds: 100), () {
        if(_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }

  void _showApiKeyDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Enter OpenRouter API Key"),
      content: TextField(
        controller: _apiController,
        decoration: const InputDecoration(hintText: "sk-or-...", border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () => _saveApiKey(_apiController.text), child: const Text("Save")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Doubts AI"),
        actions: [
          IconButton(icon: const Icon(Icons.key), onPressed: _showApiKeyDialog)
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isUser = messages[index]['role'] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isUser ? 15 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 15),
                      ),
                    ),
                    child: Text(messages[index]['content']!, style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Color(0xFF6C63FF)),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Ask a doubt...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}