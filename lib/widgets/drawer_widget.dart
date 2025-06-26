import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dealit_app/providers/category_provider.dart';
import 'package:dealit_app/providers/hotdeal_provider.dart';
import 'package:dealit_app/models/category.dart' as models;

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              '카테고리',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('선별핫딜'),
                  onTap: () {
                    context.read<HotdealProvider>().fetchHotdeals(categoryId: null, refresh: true);
                    Navigator.pop(context);
                  },
                ),
                if (categoryProvider.loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (categoryProvider.error)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('카테고리 불러오기 실패')),
                  )
                else
                  ...categoryProvider.categories.map((models.Category category) => ListTile(
                    title: Text(category.categoryName),
                    onTap: () {
                      context.read<HotdealProvider>().fetchHotdeals(categoryId: category.id, refresh: true);
                      Navigator.pop(context);
                    },
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}