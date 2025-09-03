import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget untuk testing edge cases pada fitur chat
/// Digunakan untuk development dan debugging
class ChatEdgeCaseTest extends StatefulWidget {
  const ChatEdgeCaseTest({super.key});

  @override
  State<ChatEdgeCaseTest> createState() => _ChatEdgeCaseTestState();
}

class _ChatEdgeCaseTestState extends State<ChatEdgeCaseTest> {
  final List<Map<String, dynamic>> _testCases = [
    {
      'title': 'Empty Chat List',
      'description': 'Test tampilan ketika tidak ada chat',
      'action': 'Test Empty State',
    },
    {
      'title': 'Network Error',
      'description': 'Test handling error jaringan',
      'action': 'Simulate Error',
    },
    {
      'title': 'Long Message',
      'description': 'Test pesan yang sangat panjang',
      'action': 'Send Long Message',
    },
    {
      'title': 'Image Message',
      'description': 'Test pengiriman gambar',
      'action': 'Send Image',
    },
    {
      'title': 'Offline Mode',
      'description': 'Test behavior saat offline',
      'action': 'Test Offline',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Edge Case Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Development Tool',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Widget ini digunakan untuk testing edge cases pada fitur chat. Hanya tersedia dalam mode development.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Test Cases',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test cases list
            Expanded(
              child: ListView.builder(
                itemCount: _testCases.length,
                itemBuilder: (context, index) {
                  final testCase = _testCases[index];
                  return _buildTestCaseCard(testCase);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestCaseCard(Map<String, dynamic> testCase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              testCase['title'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              testCase['description'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _executeTestCase(testCase),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(testCase['action']),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _executeTestCase(Map<String, dynamic> testCase) {
    final String title = testCase['title'];
    
    // Show dialog with test case execution
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Executing: $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test case: ${testCase['description']}'),
            const SizedBox(height: 16),
            const Text('Status: '),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Test case executed successfully!\n\nNote: This is a mock execution for development purposes.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    
    // Log test case execution
    debugPrint('Chat Edge Case Test: Executed "$title"');
  }
}