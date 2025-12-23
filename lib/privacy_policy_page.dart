import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for NoiseSense',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: [Date]',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 24),
            Text(
              'Your privacy is important to us. It is NoiseSense\'s policy to respect your privacy regarding any information we may collect from you across our app, NoiseSense.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '1. Information We Collect',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Noise Data: Our app measures sound levels using your device\'s microphone. When you choose to save a session, we store this data (average/max decibels, duration, and a timestamp) locally on your device in a private database. We do not have access to this data, and it is not transmitted to any server.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 8),
            Text(
              'Microphone Access: To function, the app requires access to your device\'s microphone. Audio is processed in real-time to calculate decibel levels. No audio is ever recorded or stored.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '2. How We Use Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'The data collected is used solely for the purpose of providing the app\'s features, which include displaying real-time noise levels, showing historical data, and providing reports. All data remains on your device.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '3. Data Storage and Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All session data is stored in a local SQLite database on your device. This data is not encrypted but is protected by the operating system\'s sandboxing features, which prevent other apps from accessing it.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '4. Children\'s Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We do not knowingly collect personally identifiable information from children under 13. If we discover that a child under 13 has provided us with personal information, we will delete it. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '5. Changes to This Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 24),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at [Your Contact Email].',
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
