## 1.0.1

- Repository automation and CI/CD workflows.
- No API or behavior changes.

## 1.0.0

- Initial stable release.
- Non-intrusive doubly linked list implementing `List<E>`.
- Stable `Node<E>` handles for O(1) insert/remove/move operations.
- Move operations: `moveToFront`, `moveToBack`, `moveAfter`, `moveBefore`.
- Node swap and list reverse in O(1) / O(n).
- Fail-fast iteration with `ConcurrentModificationError`.
- Ownership tracking to prevent cross-list corruption.
- Full `ListBase` compliance (works with `map`, `where`, `sort`, etc.).
