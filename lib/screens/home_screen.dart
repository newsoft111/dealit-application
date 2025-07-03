import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dealit_app/providers/hotdeal_provider.dart';
import 'package:dealit_app/providers/category_provider.dart';
import 'package:dealit_app/widgets/hotdeal_card.dart';
import 'package:dealit_app/widgets/drawer_widget.dart';
import 'package:dealit_app/widgets/notification_permission_widget.dart';
import 'package:dealit_app/providers/sse_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedCategoryName;
  int? _selectedCategoryId;
  bool _showNotificationWidget = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<HotdealProvider>().fetchHotdeals(categoryId: null);
      
      // SSE 연결 시작 (Next.js와 동일)
      context.read<SSEProvider>().startSSEConnection();
    });
  }

  void _onCategorySelected(String? categoryName, int? categoryId) {
    setState(() {
      _selectedCategoryName = categoryName;
      _selectedCategoryId = categoryId;
    });
  }

  void _dismissNotificationWidget() {
    setState(() {
      _showNotificationWidget = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _selectedCategoryName == null
              ? '딜잇'
              : '딜잇 - ${_selectedCategoryName!}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: DrawerWidget(onCategorySelected: _onCategorySelected),
      body: Consumer<HotdealProvider>(
        builder: (context, hotdealProvider, child) {
          if (hotdealProvider.error && hotdealProvider.hotdeals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('데이터를 불러오는 중 오류가 발생했습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => hotdealProvider.fetchHotdeals(refresh: true),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (hotdealProvider.loading && hotdealProvider.hotdeals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              print('새로고침 시작 - 카테고리 이름: $_selectedCategoryName, 카테고리 ID: $_selectedCategoryId');
              try {
                // 슈퍼핫딜인 경우 categoryId를 null로 전달
                int? categoryId = _selectedCategoryName == '슈퍼핫딜' ? null : _selectedCategoryId;
                await hotdealProvider.fetchHotdeals(categoryId: categoryId, refresh: true);
                print('새로고침 완료');
              } catch (e) {
                print('새로고침 오류: $e');
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // 스크롤이 맨 아래에 도달했는지 확인
                if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                  print('스크롤 위치: ${scrollInfo.metrics.pixels}/${scrollInfo.metrics.maxScrollExtent}');
                  print('hasMorePages: ${hotdealProvider.hasMorePages}, loading: ${hotdealProvider.loading}');
                  
                  if (hotdealProvider.hasMorePages && !hotdealProvider.loading) {
                    print('무한 스크롤 트리거 - 현재 핫딜 수: ${hotdealProvider.hotdeals.length}');
                    print('현재 카테고리: $_selectedCategoryName, 카테고리 ID: $_selectedCategoryId');
                    // 슈퍼핫딜인 경우 categoryId를 null로 전달
                    int? categoryId = _selectedCategoryName == '슈퍼핫딜' ? null : _selectedCategoryId;
                    hotdealProvider.fetchHotdeals(categoryId: categoryId);
                  }
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  // 알림 권한 위젯
                  if (_showNotificationWidget)
                    SliverToBoxAdapter(
                      child: NotificationPermissionWidget(
                        onDismiss: _dismissNotificationWidget,
                      ),
                    ),
                  // 핫딜 목록
                  hotdealProvider.hotdeals.isEmpty && !hotdealProvider.loading
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text('표시할 핫딜이 없습니다.'),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == hotdealProvider.hotdeals.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return HotdealCard(hotdeal: hotdealProvider.hotdeals[index]);
                              },
                              childCount: hotdealProvider.hotdeals.length + (hotdealProvider.hasMorePages ? 1 : 0),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // SSE 연결 해제
    context.read<SSEProvider>().stopSSEConnection();
    super.dispose();
  }
}