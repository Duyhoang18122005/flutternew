import 'package:flutter/material.dart';
import 'hire_player_screen.dart';
import 'player_detail_screen.dart';
import 'api_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> players = [];
  bool isLoading = true;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];

  // Biến trạng thái cho bộ lọc
  String? filterGame;
  String? filterRank;
  String? filterRole;
  String? filterServer;
  String? filterStatus;
  double? filterMinPrice;
  double? filterMaxPrice;
  List<dynamic> filterResults = [];
  bool isFiltering = false;

  // Thêm các giá trị mẫu cho dropdown
  final List<String> gameList = [
    'PUBG Mobile',
    'PUBG PC',
    'Liên Quân Mobile',
  ];
  final List<String> rankList = [
    'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu',
  ];
  final List<String> roleList = [
    'Tank', 'Support', 'AD', 'Mid', 'Top', 'Jungle',
  ];
  final List<String> serverList = [
    'Asia', 'VN', 'KR', 'NA', 'EU',
  ];

  @override
  void initState() {
    super.initState();
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    final data = await ApiService.fetchAllPlayers();
    setState(() {
      players = data;
      isLoading = false;
    });
  }

  void onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    setState(() {
      searchResults = players.where((player) {
        final username = (player['username'] ?? '').toLowerCase();
        final description = (player['description'] ?? '').toLowerCase();
        return username.contains(query.toLowerCase()) || description.contains(query.toLowerCase());
      }).toList();
    });
  }

  void stopSearching() {
    setState(() {
      isSearching = false;
      searchController.clear();
      searchResults = [];
    });
  }

  void applyFilter() {
    setState(() {
      filterResults = players.where((player) {
        bool matches = true;
        if (filterGame != null && filterGame!.isNotEmpty) {
          matches &= (player['gameName'] ?? '').toLowerCase() == filterGame!.toLowerCase();
        }
        if (filterRank != null && filterRank!.isNotEmpty) {
          matches &= (player['rank'] ?? '').toLowerCase() == filterRank!.toLowerCase();
        }
        if (filterRole != null && filterRole!.isNotEmpty) {
          matches &= (player['role'] ?? '').toLowerCase() == filterRole!.toLowerCase();
        }
        if (filterServer != null && filterServer!.isNotEmpty) {
          matches &= (player['server'] ?? '').toLowerCase() == filterServer!.toLowerCase();
        }
        if (filterStatus != null && filterStatus!.isNotEmpty) {
          matches &= (player['status'] ?? '').toLowerCase() == filterStatus!.toLowerCase();
        }
        if (filterMinPrice != null) {
          matches &= (player['pricePerHour'] ?? 0) >= filterMinPrice!;
        }
        if (filterMaxPrice != null) {
          matches &= (player['pricePerHour'] ?? 0) <= filterMaxPrice!;
        }
        return matches;
      }).toList();
      isFiltering = true;
    });
  }

  void clearFilter() {
    setState(() {
      filterGame = null;
      filterRank = null;
      filterRole = null;
      filterServer = null;
      filterStatus = null;
      filterMinPrice = null;
      filterMaxPrice = null;
      filterResults = [];
      isFiltering = false;
    });
  }

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double minPrice = 0;
        double maxPrice = 100000;
        double rangeStart = filterMinPrice ?? minPrice;
        double rangeEnd = filterMaxPrice ?? maxPrice;
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const Text('Bộ lọc chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 20),
                          // Game
                          DropdownButtonFormField<String>(
                            value: filterGame,
                            decoration: InputDecoration(
                              labelText: 'Tên game',
                              prefixIcon: const Icon(Icons.sports_esports, color: Colors.deepOrange),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: Colors.orange[50],
                            ),
                            items: gameList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (v) => setState(() => filterGame = v),
                            isExpanded: true,
                          ),
                          const SizedBox(height: 14),
                          // Rank
                          DropdownButtonFormField<String>(
                            value: filterRank,
                            decoration: InputDecoration(
                              labelText: 'Rank',
                              prefixIcon: const Icon(Icons.emoji_events, color: Colors.amber),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: Colors.orange[50],
                            ),
                            items: rankList.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: (v) => setState(() => filterRank = v),
                            isExpanded: true,
                          ),
                          const SizedBox(height: 14),
                          // Role
                          DropdownButtonFormField<String>(
                            value: filterRole,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              prefixIcon: const Icon(Icons.group, color: Colors.blue),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: Colors.orange[50],
                            ),
                            items: roleList.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: (v) => setState(() => filterRole = v),
                            isExpanded: true,
                          ),
                          const SizedBox(height: 14),
                          // Server
                          DropdownButtonFormField<String>(
                            value: filterServer,
                            decoration: InputDecoration(
                              labelText: 'Server',
                              prefixIcon: const Icon(Icons.cloud, color: Colors.green),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: Colors.orange[50],
                            ),
                            items: serverList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => filterServer = v),
                            isExpanded: true,
                          ),
                          const SizedBox(height: 14),
                          // Trạng thái
                          DropdownButtonFormField<String>(
                            value: filterStatus,
                            decoration: InputDecoration(
                              labelText: 'Trạng thái',
                              prefixIcon: const Icon(Icons.circle, color: Colors.teal),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: Colors.orange[50],
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Tất cả')),
                              DropdownMenuItem(value: 'AVAILABLE', child: Text('Online')),
                              DropdownMenuItem(value: 'UNAVAILABLE', child: Text('Offline')),
                            ],
                            onChanged: (v) => setState(() => filterStatus = v),
                            isExpanded: true,
                          ),
                          const SizedBox(height: 18),
                          // Giá
                          Row(
                            children: [
                              const Icon(Icons.attach_money, color: Colors.deepOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RangeSlider(
                                  values: RangeValues(rangeStart, rangeEnd),
                                  min: minPrice,
                                  max: maxPrice,
                                  divisions: 20,
                                  labels: RangeLabels(
                                    '${rangeStart.toInt()}đ',
                                    '${rangeEnd.toInt()}đ',
                                  ),
                                  onChanged: (values) {
                                    setModalState(() {
                                      rangeStart = values.start;
                                      rangeEnd = values.end;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${rangeStart.toInt()} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${rangeEnd.toInt()} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    clearFilter();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.clear, color: Colors.black),
                                  label: const Text('Xóa lọc', style: TextStyle(color: Colors.black)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      filterMinPrice = rangeStart;
                                      filterMaxPrice = rangeEnd;
                                    });
                                    applyFilter();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.check_circle, color: Colors.white),
                                  label: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: isSearching
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Tìm kiếm player...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: stopSearching,
                                    ),
                                  ),
                                  onChanged: onSearchChanged,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(Icons.sports_esports, color: Colors.deepOrange, size: 36),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'PLAYERDUO',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1),
                                  ),
                                  Text(
                                    'GAME COMMUNITY',
                                    style: TextStyle(fontSize: 12, color: Colors.black54, letterSpacing: 1),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.black54),
                                onPressed: () {
                                  setState(() {
                                    isSearching = true;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.filter_alt_outlined, color: Colors.black54),
                                onPressed: showFilterSheet,
                              ),
                            ],
                          ),
                  ),
                  // Kết nối
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      children: const [
                        Icon(Icons.movie_filter, color: Colors.deepOrange, size: 22),
                        SizedBox(width: 8),
                        Text('Kết nối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: const [
                        _GameIcon(title: 'PUBG Mobile', icon: Icons.sports_motorsports),
                        _GameIcon(title: 'PUBG PC', icon: Icons.sports_esports),
                        _GameIcon(title: 'Liên Quân Mobile', icon: Icons.sports_handball),
                      ],
                    ),
                  ),
                  // VIP Player hoặc Kết quả tìm kiếm
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.movie_filter, color: Colors.deepOrange, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isSearching && searchController.text.isNotEmpty ? 'Kết quả tìm kiếm' : 'VIP Player',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: () {
                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (isSearching && searchController.text.isNotEmpty) {
                        if (searchResults.isEmpty) {
                          return const Center(child: Text('Không tìm thấy player nào'));
                        } else {
                          return ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: searchResults.map<Widget>((player) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayerDetailScreen(player: player),
                                    ),
                                  );
                                },
                                child: _VipPlayerCard(
                                  name: player['username'] ?? '',
                                  price: '${player['pricePerHour'] ?? ''} đ / giờ',
                                  description: player['description'] ?? '',
                                  tags: '${player['gameName'] ?? ''},${player['rank'] ?? ''},${player['role'] ?? ''}',
                                  isOnline: player['status'] == 'AVAILABLE',
                                  isGray: false,
                                ),
                              );
                            }).toList(),
                          );
                        }
                      } else if (isFiltering) {
                        if (filterResults.isEmpty) {
                          return const Center(child: Text('Không tìm thấy player nào'));
                        } else {
                          return ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: filterResults.map<Widget>((player) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayerDetailScreen(player: player),
                                    ),
                                  );
                                },
                                child: _VipPlayerCard(
                                  name: player['username'] ?? '',
                                  price: '${player['pricePerHour'] ?? ''} đ / giờ',
                                  description: player['description'] ?? '',
                                  tags: '${player['gameName'] ?? ''},${player['rank'] ?? ''},${player['role'] ?? ''}',
                                  isOnline: player['status'] == 'AVAILABLE',
                                  isGray: false,
                                ),
                              );
                            }).toList(),
                          );
                        }
                      } else {
                        if (players.isEmpty) {
                          return const Center(child: Text('Chưa có player nào'));
                        } else {
                          return ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: players.map<Widget>((player) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayerDetailScreen(player: player),
                                    ),
                                  );
                                },
                                child: _VipPlayerCard(
                                  name: player['username'] ?? '',
                                  price: '${player['pricePerHour'] ?? ''} đ / giờ',
                                  description: player['description'] ?? '',
                                  tags: '${player['gameName'] ?? ''},${player['rank'] ?? ''},${player['role'] ?? ''}',
                                  isOnline: player['status'] == 'AVAILABLE',
                                  isGray: false,
                                ),
                              );
                            }).toList(),
                          );
                        }
                      }
                    }(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepOrange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class _GameIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  const _GameIcon({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              child: Icon(icon, size: 32, color: Colors.deepOrange),
              backgroundColor: Colors.white,
              radius: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VipPlayerCard extends StatelessWidget {
  final String name;
  final String price;
  final String description;
  final String tags;
  final bool isOnline;
  final bool isGray;
  const _VipPlayerCard({
    required this.name,
    required this.price,
    required this.description,
    required this.tags,
    required this.isOnline,
    required this.isGray,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh đại diện (icon thay thế)
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isGray ? Colors.grey[300] : Colors.orange[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Center(
              child: Icon(Icons.person, size: 48, color: isGray ? Colors.grey : Colors.deepOrange),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepOrange),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOnline)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.circle, color: Colors.green, size: 12),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              description,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              tags,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                price,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}