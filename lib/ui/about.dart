import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../ii.dart';

class AboutUI extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<AboutUI> with TickerProviderStateMixin {
  String appVersion = '';
  late AnimationController _animationController;

  // Анимация оленя
  final List<String> frames = [
    'images/logo-an-1.png',
    'images/logo-an-2.png',
    'images/logo-an-3.png',
  ];
  int frameIndex = 0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _startDeerAnimation();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startDeerAnimation() {
    timer = Timer.periodic(const Duration(seconds: 3), (t) {
      // Моргаем 3 кадра по 150 мс
      for (int i = 0; i < frames.length; i++) {
        Future.delayed(Duration(milliseconds: 150 * i), () {
          if (mounted) {
            setState(() => frameIndex = i);
          }
        });
      }
      // Возврат к первому кадру после моргания
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) {
          setState(() => frameIndex = 0);
        }
      });
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        appVersion = '1.0.0';
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'.ii()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!.withOpacity(0.3)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              // App Icon and Title
              _buildHeader(),

              SizedBox(height: 30),

              // App Description
              _buildDescription(),

              SizedBox(height: 30),

              // Features Section
              _buildFeatures(),

              SizedBox(height: 30),

              // How It Works
              _buildHowItWorks(),

              SizedBox(height: 30),

              // Contact & Links
              _buildContactSection(),

              SizedBox(height: 30),

              // Version Info
              _buildVersionInfo(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(frameIndex),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                frames[frameIndex],
                fit: BoxFit.cover,
                width: 120,
                height: 120,
              ),
            ),
          ),
        ),
        SizedBox(height: 15),
        Text(
          'Mysterious Santa',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'The Ultimate Secret Gift Exchange App',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Card(
      elevation: 5,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
            ),
            SizedBox(height: 15),
            Text(
              'About Mysterious Santa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Welcome to Mysterious Santa - the most exciting way to organize Secret Santa gift exchanges! '
              'Whether it\'s for your office party, family gathering, or friend group, we make gift giving magical and stress-free. '
              'Create rooms, add wishlists, get matched with recipients, and enjoy the surprise!',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      {
        'icon': Icons.group_add,
        'title': 'Create Magic Rooms',
        'description': 'Set up Secret Santa rooms in seconds for any group size'
      },
      {
        'icon': Icons.psychology,
        'title': 'AI-Powered Wishlists',
        'description':
            'Smart AI helps create perfect wishlists based on your interests'
      },
      {
        'icon': Icons.shuffle,
        'title': 'Smart Matching',
        'description':
            'Advanced algorithm ensures perfect gift pairings while keeping secrets'
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Real-time Updates',
        'description':
            'Stay updated with notifications for all room activities and deadlines'
      },
      {
        'icon': Icons.photo_camera,
        'title': 'Photo Sharing',
        'description':
            'Share photos and messages to make exchanges more personal'
      },
      {
        'icon': Icons.security,
        'title': 'Privacy First',
        'description':
            'Advanced privacy features keep your Secret Santa truly secret'
      },
    ];

    return Card(
      elevation: 5,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '✨ Amazing Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ...features
                .map((feature) => _buildFeatureItem(
                      feature['icon'] as IconData,
                      feature['title'] as String,
                      feature['description'] as String,
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      'Create or join a Secret Santa room',
      'Add your wishlist with AI assistance',
      'Wait for the magical matching process',
      'Buy the perfect gift for your assigned person',
      'Enjoy the surprise reveal and celebration!'
    ];

    return Card(
      elevation: 5,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '🎯 How It Works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              int index = entry.key;
              String step = entry.value;
              return _buildStepItem(index + 1, step);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int number, String step) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              step,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 5,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '📞 Contact & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildContactItem(
              Icons.web,
              'Website',
              'ms.afisha.news',
              () => _launchURL('https://ms.afisha.news'),
            ),
            _buildContactItem(
              Icons.email,
              'Support Email',
              'support@afisha.news',
              () => _launchURL('mailto:support@afisha.news'),
            ),
            _buildContactItem(
              Icons.privacy_tip,
              'Privacy Policy',
              'View our privacy policy',
              () => _launchURL('https://ms.afisha.news/privacy_policy.html'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            'App Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version:',
              ),
              Text(
                appVersion.isNotEmpty ? appVersion : 'Loading...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Made with:',
              ),
              Row(
                children: [
                  Text(
                    '❤️ Flutter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
