import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DepressionForm extends StatefulWidget {
  @override
  _DepressionFormState createState() => _DepressionFormState();
}

class _DepressionFormState extends State<DepressionForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int? gender;
  double age = 20;
  int? profession = 11;
  double academicPressure = 3;
  double cgpa = 7;
  double studySatisfaction = 3;
  int? sleepDuration;
  int? dietaryHabits;
  int? degree;
  int? suicidalThoughts;
  double workStudyHours = 6;
  double financialStress = 3;
  int? familyHistory;

  String? result;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (gender == null || sleepDuration == null || dietaryHabits == null ||
        degree == null || suicidalThoughts == null || familyHistory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      result = null;
    });

    final body = jsonEncode({
      "Gender": gender,
      "Age": age,
      "Profession": profession,
      "Academic_Pressure": academicPressure,
      "CGPA": cgpa,
      "Study_Satisfaction": studySatisfaction,
      "Sleep_Duration": sleepDuration,
      "Dietary_Habits": dietaryHabits,
      "Degree": degree,
      "Suicidal_Thoughts": suicidalThoughts,
      "Work_Study_Hours": workStudyHours,
      "Financial_Stress": financialStress,
      "Family_History": familyHistory,
    });

    try {
      final uri = Uri.parse("http://192.168.0.18:8000/predict");
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('{"error":"timeout"}', 408),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = data['recommendations'] ?? 'Öneri alınamadı.';
          isLoading = false;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('depression_responses')
              .add({
            'uid': user.uid,
            'gender': gender,
            'age': age,
            'profession': profession,
            'academicPressure': academicPressure,
            'cgpa': cgpa,
            'studySatisfaction': studySatisfaction,
            'sleepDuration': sleepDuration,
            'dietaryHabits': dietaryHabits,
            'degree': degree,
            'suicidalThoughts': suicidalThoughts,
            'workStudyHours': workStudyHours,
            'financialStress': financialStress,
            'familyHistory': familyHistory,
            'prediction': data['result'],
            'recommendations': data['recommendations'],
            'timestamp': DateTime.now(),
          });
        }

        _animationController.forward();
        _showResultDialog(data);
      } else if (response.statusCode == 408) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sunucuya bağlanılamadı. API sunucusunun çalıştığından emin olun.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          result = "Sunucu hatası: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        result = "Bağlantı hatası: $e";
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası. API sunucusunu kontrol edin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showResultDialog(Map<String, dynamic> data) {
    final isDepressed = data['result'] == 'Depressed';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 16,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDepressed
                    ? [Colors.orange[50]!, Colors.red[50]!]
                    : [Colors.green[50]!, Colors.blue[50]!],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDepressed ? Colors.orange[100] : Colors.green[100],
                      boxShadow: [
                        BoxShadow(
                          color: (isDepressed ? Colors.orange : Colors.green)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isDepressed ? Icons.psychology_outlined : Icons.mood,
                      size: 40,
                      color: isDepressed ? Colors.orange[700] : Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isDepressed ? "Dikkat Gerekiyor" : "Harika Durumdasın!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDepressed ? Colors.orange[800] : Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDepressed
                        ? "Seninle birlikte bu durumu aşacağız"
                        : "Ruh sağlığın için bu önerileri takip et",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        data['recommendations'] ?? 'Öneri alınamadı.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _animationController.reset();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: isDepressed
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                          child: Text(
                            "Kapat",
                            style: TextStyle(
                              color: isDepressed
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _resetForm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDepressed ? Colors.orange : Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: const Text(
                            "Yeni Test",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      gender = null;
      age = 20;
      academicPressure = 3;
      cgpa = 7;
      studySatisfaction = 3;
      sleepDuration = null;
      dietaryHabits = null;
      degree = null;
      suicidalThoughts = null;
      workStudyHours = 6;
      financialStress = 3;
      familyHistory = null;
      result = null;
    });
    _animationController.reset();
  }

  Color get _cardColor => Theme.of(context).cardColor;
  Color get _bgColor => Theme.of(context).scaffoldBackgroundColor;

  // Modern bottom sheet seçici
  Future<void> _showSelector<T>({
    required String title,
    required List<Map<String, dynamic>> options,
    required T? currentValue,
    required void Function(T) onSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = currentValue == option['value'];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.indigo
                                : Colors.indigo.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            option['icon'] as IconData? ?? Icons.circle,
                            color:
                                isSelected ? Colors.white : Colors.indigo,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.indigo : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Colors.indigo)
                            : null,
                        onTap: () {
                          onSelected(option['value'] as T);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Modern seçici butonu
  Widget _buildSelector({
    required String label,
    required String? selectedLabel,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? Colors.red : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedLabel ?? 'Seçiniz...',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedLabel != null
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderWidget({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) display,
    required void Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  display(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.indigo,
              inactiveTrackColor: Colors.indigo.withOpacity(0.15),
              thumbColor: Colors.indigo,
              overlayColor: Colors.indigo.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.toInt()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              Text('${max.toInt()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  String? _genderLabel() => gender == null
      ? null
      : gender == 0
          ? 'Kadın'
          : 'Erkek';

  String? _sleepLabel() {
    const labels = ['5-6 saat', '7-8 saat', '5 saatten az', '8 saatten fazla', 'Diğer'];
    return sleepDuration == null ? null : labels[sleepDuration!];
  }

  String? _dietLabel() {
    const labels = ['Sağlıklı', 'Orta', 'Diğer', 'Sağlıksız'];
    return dietaryHabits == null ? null : labels[dietaryHabits!];
  }

  String? _degreeLabel() {
    const labels = [
      'B.Arch (Mimarlık)', 'B.Com (Ticaret)', 'B.Ed (Eğitim)',
      'B.Pharm (Eczacılık)', 'B.Tech (Mühendislik)', 'BA (Sanat)',
      'BBA (İşletme)', 'BCA (Bilgisayar)', 'BE (Mühendislik)',
      'BHM (Otelcilik)', 'BSc (Fen Bilimleri)', 'Lise Mezunu',
      'LLB (Hukuk)', 'LLM (Y.L. Hukuk)', 'M.Com', 'M.Ed',
      'M.Pharm', 'M.Tech', 'MA', 'MBA', 'MBBS (Tıp)', 'MCA',
      'MD (Tıp Doktoru)', 'ME', 'MHM', 'MSc', 'Diğer', 'PhD (Doktora)',
    ];
    return degree == null ? null : labels[degree!];
  }

  String? _suicidalLabel() => suicidalThoughts == null
      ? null
      : suicidalThoughts == 0
          ? 'Hayır'
          : 'Evet';

  String? _familyLabel() => familyHistory == null
      ? null
      : familyHistory == 0
          ? 'Hayır'
          : 'Evet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Ruh Sağlığı Analizi",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık kartı
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [Colors.indigo, Colors.blue]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.psychology, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Ruh Sağlığın Önemli",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Lütfen soruları dürüstçe yanıtlayın",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Cinsiyet
              _buildSelector(
                label: 'Cinsiyet',
                selectedLabel: _genderLabel(),
                onTap: () => _showSelector<int>(
                  title: 'Cinsiyet',
                  currentValue: gender,
                  options: [
                    {'value': 0, 'label': 'Kadın', 'icon': Icons.female},
                    {'value': 1, 'label': 'Erkek', 'icon': Icons.male},
                  ],
                  onSelected: (val) => setState(() => gender = val),
                ),
              ),

              // Yaş slider
              _buildSliderWidget(
                label: 'Yaş',
                value: age,
                min: 15,
                max: 60,
                divisions: 45,
                display: (v) => '${v.toInt()}',
                onChanged: (val) => setState(() => age = val),
              ),

              // Uyku Süresi
              _buildSelector(
                label: 'Uyku Süresi',
                selectedLabel: _sleepLabel(),
                onTap: () => _showSelector<int>(
                  title: 'Uyku Süresi',
                  currentValue: sleepDuration,
                  options: [
                    {'value': 2, 'label': '5 saatten az', 'icon': Icons.bedtime},
                    {'value': 0, 'label': '5-6 saat', 'icon': Icons.bedtime_outlined},
                    {'value': 1, 'label': '7-8 saat', 'icon': Icons.bed},
                    {'value': 3, 'label': '8 saatten fazla', 'icon': Icons.king_bed},
                    {'value': 4, 'label': 'Diğer', 'icon': Icons.more_horiz},
                  ],
                  onSelected: (val) => setState(() => sleepDuration = val),
                ),
              ),

              // Beslenme
              _buildSelector(
                label: 'Beslenme Alışkanlığı',
                selectedLabel: _dietLabel(),
                onTap: () => _showSelector<int>(
                  title: 'Beslenme Alışkanlığı',
                  currentValue: dietaryHabits,
                  options: [
                    {'value': 0, 'label': 'Sağlıklı', 'icon': Icons.eco},
                    {'value': 1, 'label': 'Orta', 'icon': Icons.balance},
                    {'value': 3, 'label': 'Sağlıksız', 'icon': Icons.fastfood},
                    {'value': 2, 'label': 'Diğer', 'icon': Icons.more_horiz},
                  ],
                  onSelected: (val) => setState(() => dietaryHabits = val),
                ),
              ),

              // Eğitim Seviyesi
              _buildSelector(
                label: 'Eğitim Seviyesi',
                selectedLabel: _degreeLabel(),
                onTap: () => _showSelector<int>(
                  title: 'Eğitim Seviyesi',
                  currentValue: degree,
                  options: [
                    {'value': 11, 'label': 'Lise Mezunu', 'icon': Icons.school},
                    {'value': 5, 'label': 'BA (Sanat)', 'icon': Icons.school},
                    {'value': 6, 'label': 'BBA (İşletme)', 'icon': Icons.business},
                    {'value': 7, 'label': 'BCA (Bilgisayar)', 'icon': Icons.computer},
                    {'value': 4, 'label': 'B.Tech (Mühendislik)', 'icon': Icons.engineering},
                    {'value': 8, 'label': 'BE (Mühendislik)', 'icon': Icons.engineering},
                    {'value': 10, 'label': 'BSc (Fen Bilimleri)', 'icon': Icons.science},
                    {'value': 1, 'label': 'B.Com (Ticaret)', 'icon': Icons.account_balance},
                    {'value': 2, 'label': 'B.Ed (Eğitim)', 'icon': Icons.cast_for_education},
                    {'value': 0, 'label': 'B.Arch (Mimarlık)', 'icon': Icons.architecture},
                    {'value': 3, 'label': 'B.Pharm (Eczacılık)', 'icon': Icons.local_pharmacy},
                    {'value': 9, 'label': 'BHM (Otelcilik)', 'icon': Icons.hotel},
                    {'value': 12, 'label': 'LLB (Hukuk)', 'icon': Icons.gavel},
                    {'value': 13, 'label': 'LLM (Y.L. Hukuk)', 'icon': Icons.gavel},
                    {'value': 19, 'label': 'MBA', 'icon': Icons.business_center},
                    {'value': 20, 'label': 'MBBS (Tıp)', 'icon': Icons.medical_services},
                    {'value': 22, 'label': 'MD (Tıp Doktoru)', 'icon': Icons.medical_services},
                    {'value': 27, 'label': 'PhD (Doktora)', 'icon': Icons.workspace_premium},
                    {'value': 26, 'label': 'Diğer', 'icon': Icons.more_horiz},
                  ],
                  onSelected: (val) => setState(() => degree = val),
                ),
              ),

              // İntihar Düşüncesi
              _buildSelector(
                label: 'İntihar Düşüncesi',
                selectedLabel: _suicidalLabel(),
                onTap: () => _showSelector<int>(
                  title: 'İntihar Düşüncesi Yaşadınız mı?',
                  currentValue: suicidalThoughts,
                  options: [
                    {'value': 0, 'label': 'Hayır', 'icon': Icons.check_circle_outline},
                    {'value': 1, 'label': 'Evet', 'icon': Icons.warning_amber_outlined},
                  ],
                  onSelected: (val) => setState(() => suicidalThoughts = val),
                ),
              ),

              // Akademik Baskı slider
              _buildSliderWidget(
                label: 'Akademik Baskı',
                value: academicPressure,
                min: 1,
                max: 5,
                divisions: 4,
                display: (v) => '${v.toInt()}/5',
                onChanged: (val) => setState(() => academicPressure = val),
              ),

              // CGPA slider
              _buildSliderWidget(
                label: 'CGPA (Not Ortalaması)',
                value: cgpa,
                min: 0,
                max: 10,
                divisions: 20,
                display: (v) => v.toStringAsFixed(1),
                onChanged: (val) => setState(() => cgpa = val),
              ),

              // Öğrenim Memnuniyeti slider
              _buildSliderWidget(
                label: 'Öğrenim Memnuniyeti',
                value: studySatisfaction,
                min: 1,
                max: 5,
                divisions: 4,
                display: (v) => '${v.toInt()}/5',
                onChanged: (val) => setState(() => studySatisfaction = val),
              ),

              // Çalışma saati slider
              _buildSliderWidget(
                label: 'Günlük Çalışma / Ders Saati',
                value: workStudyHours,
                min: 0,
                max: 16,
                divisions: 16,
                display: (v) => '${v.toInt()} sa',
                onChanged: (val) => setState(() => workStudyHours = val),
              ),

              // Finansal Stres slider
              _buildSliderWidget(
                label: 'Finansal Stres',
                value: financialStress,
                min: 1,
                max: 5,
                divisions: 4,
                display: (v) => '${v.toInt()}/5',
                onChanged: (val) => setState(() => financialStress = val),
              ),

              // Aile geçmişi
              _buildSelector(
                label: 'Ailede Ruhsal Hastalık Geçmişi',
                selectedLabel: _familyLabel(),
                onTap: () => _showSelector<int>(
                  title: 'Ailede Ruhsal Hastalık Geçmişi',
                  currentValue: familyHistory,
                  options: [
                    {'value': 0, 'label': 'Hayır', 'icon': Icons.check_circle_outline},
                    {'value': 1, 'label': 'Evet', 'icon': Icons.family_restroom},
                  ],
                  onSelected: (val) => setState(() => familyHistory = val),
                ),
              ),

              const SizedBox(height: 30),

              // Analiz Et butonu
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.indigo, Colors.blue]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Analiz Ediliyor...",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        )
                      : const Text(
                          "Analiz Et",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
