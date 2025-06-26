import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dealit_app/providers/hotdeal_provider.dart';
import 'package:dealit_app/providers/category_provider.dart';
import 'package:dealit_app/widgets/hotdeal_card.dart';
import 'package:dealit_app/widgets/drawer_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RefreshController _refreshController = RefreshController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<HotdealProvider>().fetchHotdeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          '딜잇',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const DrawerWidget(),
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

          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: hotdealProvider.hasMorePages,
            onRefresh: () async {
              await hotdealProvider.fetchHotdeals(refresh: true);
              _refreshController.refreshCompleted();
            },
            onLoading: () async {
              await hotdealProvider.fetchHotdeals();
              _refreshController.loadComplete();
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: hotdealProvider.hotdeals.length + 
                         (hotdealProvider.loading ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= hotdealProvider.hotdeals.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return HotdealCard(hotdeal: hotdealProvider.hotdeals[index]);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}