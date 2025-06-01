import 'package:flutter/material.dart';
import 'hire_player_screen.dart';
import 'donate_player_screen.dart';
import 'chat_screen.dart';
import 'api_service.dart';

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  const _StatItem({required this.label, required this.value, this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon != null
            ? Icon(icon, color: Colors.grey, size: 28)
            : Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool selected;
  const _TabButton({required this.title, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.orange : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class PlayerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  int followerCount = 0;
  int hireHours = 0;
  bool isLoadingStats = true;
  bool isFollowing = false;
  bool isLoadingFollow = false;
  int selectedTab = 0; // 0: Thông tin, 1: Đánh giá, 2: Thành tích

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkFollowing();
  }

  Future<void> _loadStats() async {
    final id = widget.player['id'] is int ? widget.player['id'] : int.tryParse(widget.player['id'].toString() ?? '');
    if (id != null) {
      final followers = await ApiService.fetchFollowerCount(id);
      final hours = await ApiService.fetchHireHours(id);
      setState(() {
        followerCount = followers;
        hireHours = hours;
        isLoadingStats = false;
      });
    }
  }

  Future<void> _checkFollowing() async {
    final id = widget.player['id'] is int ? widget.player['id'] : int.tryParse(widget.player['id'].toString() ?? '');
    if (id != null) {
      final following = await ApiService.checkFollowing(id);
      setState(() {
        isFollowing = following;
      });
    }
  }

  Future<void> _handleFollow() async {
    setState(() { isLoadingFollow = true; });
    final id = widget.player['id'] is int ? widget.player['id'] : int.tryParse(widget.player['id'].toString() ?? '');
    print('[LOG] Bắt đầu gửi request theo dõi player: $id');
    if (id != null) {
      bool success = false;
      final wasFollowing = isFollowing; // Lưu trạng thái trước khi gọi API
      if (!isFollowing) {
        success = await ApiService.followPlayer(id);
        print('[LOG] Kết quả followPlayer: $success');
      } else {
        success = await ApiService.unfollowPlayer(id);
        print('[LOG] Kết quả unfollowPlayer: $success');
      }
      if (success) {
        setState(() {
          isFollowing = !wasFollowing;
        });
        await _loadStats();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(!wasFollowing ? 'Đã theo dõi người chơi!' : 'Đã hủy theo dõi!')),
        );
      } else {
        print('[LOG] Theo dõi thất bại! (wasFollowing: $wasFollowing)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(!wasFollowing ? 'Theo dõi thất bại!' : 'Hủy theo dõi thất bại!')),
        );
      }
    } else {
      print('[LOG] ID player không hợp lệ!');
    }
    setState(() { isLoadingFollow = false; });
  }

  Widget _buildPlayerInfo(Map<String, dynamic> player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Tên:', player['username']),
          _infoRow('Tuổi:', player['age']?.toString()),
          _infoRow('Vị trí:', player['position']),
          _infoRow('Quốc tịch:', player['nationality']),
          _infoRow('Giá thuê:', player['pricePerHour'] != null ? '${player['pricePerHour']} đ/h' : ''),
          _infoRow('Trạng thái:', player['status']),
          _infoRow('Mô tả:', player['description']),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value ?? '', style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Chi tiết ${player['username'] ?? ''}'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar, tên, trạng thái
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.orange[100],
                      child: const Icon(Icons.person, size: 52, color: Colors.deepOrange),
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  right: MediaQuery.of(context).size.width / 2 - 56 - 16,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.circle, color: Colors.green, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              player['username'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 4),
            // Đánh giá và theo dõi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (i) => const Icon(Icons.star, color: Colors.amber, size: 20)),
                const SizedBox(width: 6),
                const Text('(106 đánh giá)', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey : Colors.orange,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: isLoadingFollow ? null : _handleFollow,
                  icon: isLoadingFollow
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(isFollowing ? Icons.remove_circle_outline : Icons.favorite, color: Colors.white, size: 18),
                  label: Text(isFollowing ? 'Hủy theo dõi' : 'Theo dõi', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nút thuê lớn ở giữa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange, width: 2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DonatePlayerScreen(player: player),
                                  ),
                                );
                              },
                              child: const Icon(Icons.attach_money, color: Colors.orange, size: 28),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HirePlayerScreen(player: player),
                              ),
                            );
                          },
                          child: Text(
                            'Thuê\n${player['pricePerHour'] ?? ''} đ/h',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange, width: 2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(player: player),
                                  ),
                                );
                              },
                              child: const Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 28),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Các chỉ số
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Người\nTheo dõi', value: isLoadingStats ? '...' : followerCount.toString()),
                  _StatItem(label: 'Giờ\nĐược thuê', value: isLoadingStats ? '...' : hireHours.toString()),
                  const _StatItem(label: '%\nHoàn thành', value: '94.34'),
                  const _StatItem(label: 'Thiết bị', value: '', icon: Icons.block),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 0),
                      child: _TabButton(title: 'Thông tin', selected: selectedTab == 0),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 1),
                      child: _TabButton(title: 'Đánh giá', selected: selectedTab == 1),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 2),
                      child: _TabButton(title: 'Thành tích', selected: selectedTab == 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (selectedTab == 0) _buildPlayerInfo(player),
            // Ảnh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.orange[100],
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.orange[100],
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.orange[100],
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.orange[100],
                        ),
                        child: const Icon(Icons.person, size: 36, color: Colors.deepOrange),
                      ),
                      const Positioned.fill(
                        child: Center(
                          child: Text('+5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (selectedTab == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: const [
                    Text(
                      'VUI LÒNG NHẮN TIN TRƯỚC KHI THUÊ !',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'CHỈ DÙNG DUY NHẤT MỘT ACC PLAYDUO NÀY VÀ MỘT FACEBOOK NHƯ LINK DƯỚI',
                      style: TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 