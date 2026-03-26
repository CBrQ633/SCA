import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/services/models.dart';
import '../../data/news_repository.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final NewsRepository _repository = NewsRepository();
  List<NewsAnnouncement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final news = await _repository.getAllAnnouncements();
      if (mounted) {
        setState(() {
          // Only show active news to users
          _announcements = news.where((n) => n.isActive).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F172A);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Latest News / آخر الأخبار', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNews,
              child: _announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.newspaper_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No news available.\nلا توجد أخبار حالياً.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final item = _announcements[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (item.imageUrls.isNotEmpty)
                                Image.network(
                                  item.imageUrls.first,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: navy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                            DateFormat('MMM dd').format(item.createdAt),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navy),
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.push_pin_rounded, size: 16, color: Colors.orangeAccent),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy, height: 1.3),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.content,
                                      style: TextStyle(fontSize: 14, color: Colors.blueGrey[600], height: 1.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
