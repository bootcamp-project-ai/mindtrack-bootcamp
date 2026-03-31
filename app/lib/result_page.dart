import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cardColor = Theme.of(context).cardColor;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sonuçlarım")),
        body: const Center(child: Text("Giriş yapmış kullanıcı bulunamadı.")),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Geçmiş Anket Sonuçlarım")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('depression_responses')
            .where('uid', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            // Index hatası için yönlendirme
            if (error.contains('failed-precondition') ||
                error.contains('requires an index')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_circle_outlined,
                          size: 64, color: Colors.indigo),
                      const SizedBox(height: 16),
                      const Text(
                        'Firestore İndeksi Gerekli',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Firebase Console\'da otomatik oluşturulan indeks linki terminalde görünüyor. O linke tıklayıp indeksi oluşturun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text('Hata: $error'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.indigo));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Henüz anket sonucunuz yok.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isDepressed = data['prediction'] == 'Depressed' ||
                  data['prediction'] == 1;
              final recommendations =
                  data['recommendations'] ?? 'Öneri yok.';

              final timestamp = data['timestamp'];
              String dateStr = '';
              if (timestamp is Timestamp) {
                final dt = timestamp.toDate();
                dateStr =
                    '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDepressed
                            ? Colors.orange.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDepressed
                                ? Icons.psychology_outlined
                                : Icons.mood,
                            color: isDepressed
                                ? Colors.orange[700]
                                : Colors.green[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isDepressed
                                  ? 'Dikkat Gerekiyor'
                                  : 'Harika Durumdasın!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDepressed
                                    ? Colors.orange[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(dateStr,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Öneriler:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(recommendations,
                              style: const TextStyle(
                                  fontSize: 14, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
