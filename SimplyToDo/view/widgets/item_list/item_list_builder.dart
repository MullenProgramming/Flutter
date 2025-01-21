import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simply_todo/controller/cubits/item_cubit.dart';
import 'package:simply_todo/controller/cubits/item_cubit_state.dart';
import 'package:simply_todo/controller/cubits/settings_cubit_state.dart';
import 'package:simply_todo/model/object_models/item.dart';
import 'package:simply_todo/util/values/enums.dart';
import 'package:simply_todo/view/widgets/item_list/item_list_tile.dart';

Widget buildItemList(
  BuildContext context,
  ItemState itemState,
  SettingsState settingsState,
  ItemCategory selectedCategory,
  Function(int, int) onReorder,
  Function(BuildContext, ItemCubit, TextEditingController, Item) onEdit,
  TextEditingController titleController,
  List<Item> givenList,
) {
  return ReorderableListView.builder(
    itemCount: selectedCategory != ItemCategory.Calendar
        ? itemState.itemsList.length
        : givenList.length,
    onReorder: onReorder,
    itemBuilder: (context, index) {
      final item = selectedCategory != ItemCategory.Calendar
          ? itemState.itemsList[index]
          : givenList[index];
      final itemCubit = context.read<ItemCubit>();

      // Define bit positions for each category
      const int urgentBit = 1 << 3; // 8
      const int importantBit = 1 << 2; // 4
      const int miscBit = 1 << 1; // 2
      const int shoppingBit = 1 << 0; // 1

      if (selectedCategory == ItemCategory.All) {
        int filterMask = settingsState.allItemsFilter;

        // Check if the item's category bit is set in the filter mask
        if ((filterMask & urgentBit) != 0 &&
                item.category == ItemCategory.Urgent ||
            (filterMask & importantBit) != 0 &&
                item.category == ItemCategory.Important ||
            (filterMask & miscBit) != 0 && item.category == ItemCategory.Misc ||
            (filterMask & shoppingBit) != 0 &&
                item.category == ItemCategory.Shopping) {
          log("Filter Value: ${settingsState.allItemsFilter}");
          return buildSlidableItem(
              context, item, itemCubit, onEdit, titleController);
        }
      } else if (item.category == selectedCategory) {
        return buildSlidableItem(
            context, item, itemCubit, onEdit, titleController);
      } else if (selectedCategory == ItemCategory.Calendar) {
        return buildSlidableItem(
            context, item, itemCubit, onEdit, titleController,
            hasDragHandle: false);
      }

      return Container(key: Key(item.id.toString()));
    },
  );
}
