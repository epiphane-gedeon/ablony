import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String userName;
  final String userAvatar;

  const ChatPage({
    super.key,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Liste simulée de messages pour la démo
  // Type: 'text' ou 'offer'
  final List<Map<String, dynamic>> _messages = [
    {
      'type': 'offer',
      'amount': 1.00, // Legacy euro value from mockup, will display as FCFA in logic
      'status': 'rejected',
      'isMe': false,
      'timestamp': '24/11/2025',
      'text': '1,00 €', // Mockup display
    },
    {
      'type': 'text',
      'isMe': false,
      'text': 'Salut je voudrais vraiment acheter ton article',
      'timestamp': '24/11/2025',
    },
    {
      'type': 'reply_offer', // Mocking the black bubble "1,50 € 1,00 €" from mockup
      'isMe': true,
      'amount': 1.50,
      'originalAmount': 1.00,
    },
    {
      'type': 'offer',
      'amount': 3000.0, // FCFA value
      'status': 'pending',
      'isMe': false, // Received offer
      'timestamp': 'Aujourd\'hui',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.userAvatar),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'France • Dernière connexion il y a 14 heures', // Mockup data
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Infos utilisateur mockup (encadré en haut)
          // _buildUserInfoCard(theme), // Déjà dans l'appbar plus ou moins, le mockup montre un doublon parfois ou un header interne

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                
                return MessageBubble(
                  isMe: msg['isMe'],
                  text: msg['text'],
                  isOffer: msg['type'] == 'offer',
                  offerAmount: msg['amount'] is num ? (msg['amount'] as num).toDouble() : null,
                  originalOfferAmount: msg['originalAmount'] is num ? (msg['originalAmount'] as num).toDouble() : null,
                  offerStatus: msg['status'],
                  onAccept: () {
                     setState(() {
                       msg['status'] = 'accepted';
                     });
                  },
                  onRefuse: () {
                    setState(() {
                       msg['status'] = 'rejected';
                     });
                  },
                  onCounterOffer: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contre-offre simulée')),
                    );
                  },
                );
              },
            ),
          ),
          
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Envoyer un message', style: TextStyle(color: Colors.grey)),
              ),
            ),
            IconButton(icon: const Icon(Icons.send, color: Colors.grey), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
