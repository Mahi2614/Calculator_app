import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = "";
  String _output = "0";
  String _funnyMessage = "";
  bool _isCalculating = false;

  final List<String> funnyLines = const [
    "Calculating...",
    "Almost there...",
    "Just a few seconds...",
    "Wait… math is hard 🧮",
    "Asking Einstein for help 🤓",
    "Brain.exe loading…",
    "Dividing by zero… jk 😂",
    "Crunching numbers…",
    "Thinking really hard 🤯",
    "Carrying the one… twice…",
  ];

  // ===== UI actions =====
  void _buttonPressed(String v) {
    if (_isCalculating) return;
    setState(() {
      if (v == "C") {
        _input = "";
        _output = "0";
        _funnyMessage = "";
      } else if (v == "DEL") {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (v == "=") {
        _startFunnyCalculation();
      } else {
        _input += v;
      }
    });
  }

  void _startFunnyCalculation() {
    if (_input.trim().isEmpty) {
      setState(() => _output = "Error");
      return;
    }

    setState(() {
      _isCalculating = true;
      _funnyMessage = _randLine();
      _output = "";
    });

    int ticks = 0;
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (ticks < 3) {
        setState(() => _funnyMessage = _randLine());
        ticks++;
      } else {
        t.cancel();
        // Do the math
        final res = _evaluate(_input);
        setState(() {
          _output = res == null ? "Error" : _formatNumber(res);
          _funnyMessage = "";
          _isCalculating = false;
        });
      }
    });
  }

  String _randLine() => funnyLines[Random().nextInt(funnyLines.length)];

  // ===== Expression evaluator (handles spaces, negatives, precedence) =====
  double? _evaluate(String expr) {
    final s = expr.replaceAll(' ', '');
    if (s.isEmpty) return null;

    final List<double> nums = [];
    final List<String> ops = [];
    String buf = "";

    bool isOperator(String ch) => "+-*/".contains(ch);

    for (int i = 0; i < s.length; i++) {
      final ch = s[i];

      if ((ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || ch == '.') {
        buf += ch;
      } else if (isOperator(ch)) {
        // unary minus handling
        if (ch == '-' && (i == 0 || isOperator(s[i - 1]))) {
          buf += ch; // part of the number (negative sign)
          continue;
        }
        if (buf.isEmpty) return null; // operator without a number
        nums.add(double.tryParse(buf) ?? double.nan);
        buf = "";
        ops.add(ch);
      } else {
        return null; // invalid char
      }
    }

    if (buf.isEmpty) return null;
    nums.add(double.tryParse(buf) ?? double.nan);

    if (nums.any((e) => e.isNaN)) return null;
    if (nums.length != ops.length + 1) return null;

    // Pass 1: * and /
    int i = 0;
    while (i < ops.length) {
      final op = ops[i];
      if (op == '*' || op == '/') {
        final a = nums[i], b = nums[i + 1];
        if (op == '/' && b == 0) return double.nan;
        final r = op == '*' ? (a * b) : (a / b);
        nums[i] = r;
        nums.removeAt(i + 1);
        ops.removeAt(i);
      } else {
        i++;
      }
    }

    // Pass 2: + and -
    double result = nums[0];
    for (int j = 0; j < ops.length; j++) {
      final op = ops[j];
      final b = nums[j + 1];
      result = (op == '+') ? (result + b) : (result - b);
    }

    return result;
  }

  String _formatNumber(double v) {
    if (v.isNaN || v.isInfinite) return "Error";
    String s = v.toStringAsFixed(10);
    s = s.replaceFirst(RegExp(r'\.?0+$'), ''); // trim trailing zeros
    return s.isEmpty ? "0" : s;
  }

  // ===== UI =====
  Widget _btn(
    String text, {
    double height = 70,
    bool wide = false,
    Color? color,
  }) {
    return Expanded(
      flex: wide ? 2 : 1,
      child: GestureDetector(
        onTap: () => _buttonPressed(text),
        child: Container(
          margin: const EdgeInsets.all(8),
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _input,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.black54,
                      ),
                    ),
                    if (_funnyMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                        child: Text(
                          _funnyMessage,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    Text(
                      _output,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons
            Column(
              children: [
                Row(
                  children: [
                    _btn("C", color: Colors.red),
                    _btn("DEL"),
                    _btn("/", color: Colors.blue),
                    _btn("*", color: Colors.blue),
                  ],
                ),
                Row(
                  children: [
                    _btn("7"),
                    _btn("8"),
                    _btn("9"),
                    _btn("-", color: Colors.blue),
                  ],
                ),
                Row(
                  children: [
                    _btn("4"),
                    _btn("5"),
                    _btn("6"),
                    _btn("+", color: Colors.blue),
                  ],
                ),
                Row(
                  children: [
                    _btn("1"),
                    _btn("2"),
                    _btn("3"),
                    _btn("=", color: Colors.green),
                  ],
                ),
                Row(children: [_btn("0", wide: true), _btn(".")]),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
