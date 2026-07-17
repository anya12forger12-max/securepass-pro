enum BatchAction { copy, delete, export, tag, favorite, unfavorite, secureDelete, move }

class BatchOperation {
  const BatchOperation({
    required this.action,
    required this.itemIds,
    this.tagId,
    this.targetWorkspaceId,
  });

  final BatchAction action;
  final List<String> itemIds;
  final String? tagId;
  final String? targetWorkspaceId;

  int get count => itemIds.length;
}
