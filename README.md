# Doubly Linked List

A **non-intrusive** doubly linked list for Dart that implements `List<E>`, featuring **O(1)** insertions and removals.

Suitable for **LRU Caches**, **Queues**, and scenarios requiring frequent **mid-list modifications** without list traversal.

## Why This Exists

Dart's `dart:collection` has a `LinkedList`, but it's **intrusive** — your elements must extend `LinkedListEntry<E>`. That means:

```dart
// ❌ You can't do this with dart:collection
LinkedList<int>();          // Nope. int doesn't extend LinkedListEntry.
LinkedList<String>();       // Nope.
LinkedList<YourModel>();    // Only if you modify YourModel to extend LinkedListEntry.
```

This package lets you do:

```dart
// ✅ This package
DoublyLinkedList<int>([1, 2, 3]);
DoublyLinkedList<String>(['a', 'b', 'c']);
DoublyLinkedList<YourModel>();  // No modification needed.
```

## The Real Value: O(1) Operations with Stable Handles

The killer feature isn't just "a linked list" — it's **stable node handles**:

```dart
final list = DoublyLinkedList<String>();

// Get a handle when you insert
final nodeA = list.append('A');
final nodeB = list.append('B');
final nodeC = list.append('C');

// Later: O(1) operations using that handle
list.moveToFront(nodeB);           // LRU cache pattern
list.insertAfter(nodeA, 'A.5');    // Insert without searching
list.unlink(nodeC);                // Remove without searching

print(list); // [B, A, A.5]
```

With a regular `List`, these operations require searching (O(n)).

## When to Use This

✅ **Use this when you need:**
- **O(1) remove/move/insert** at a known position (you have a node handle)
- **LRU caches** — move accessed items to front in O(1)
- **Editor buffers** — insert/delete at cursor position
- **Playlists / queues** — reorder items without index shuffling

❌ **Don't use this when:**
- You need fast random access (`list[500]` is O(n) here, O(1) in `List`)
- You're mostly iterating or mapping — just use `List`
- Your list is small and performance doesn't matter

## Alternatives (often simpler)

If any of these fit, they are usually the better choice:

- `List`: best for random access, mapping, sorting, and general use.
- `ListQueue`: fast queue/deque operations at both ends.
- `LinkedHashMap`: key-value LRU via delete-and-reinsert (no built-in access order).
- `dart:collection` `LinkedList`: fast non-List linked list when you can
  make your elements extend `LinkedListEntry`.

## Comparison

| Operation | `List<E>` | `dart:collection` LinkedList | This Package |
|-----------|-----------|------------------------------|--------------|
| **Random access** `[i]` | O(1) ⚡ | N/A | O(n) 🐢 |
| **Append/Prepend** | O(1) / O(n) | O(1) ⚡ | O(1) ⚡ |
| **Remove at known node** | O(n) 🐢 | O(1) ⚡ | O(1) ⚡ |
| **Move node to front** | O(n) 🐢 | O(1) ⚡ | O(1) ⚡ |
| **Store any type** | ✅ | ❌ (must extend) | ✅ |
| **Implements `List<E>`** | ✅ | ❌ | ✅ |

## Usage

### Basic (just like a List)

```dart
final list = DoublyLinkedList<int>([1, 2, 3]);

list.add(4);           // append
list.insert(0, 0);     // prepend
list.removeAt(2);      // remove by index

print(list);           // [0, 1, 3, 4]

// All Iterable methods work
list.where((e) => e.isEven).toList();
```

### Advanced (why you're here)

```dart
final list = DoublyLinkedList<String>();

// Save handles when inserting
final nodeA = list.append('A');
final nodeB = list.append('B');
final nodeC = list.append('C');

// O(1) operations using handles
list.moveToFront(nodeC);          // [C, A, B]
list.insertBefore(nodeB, 'X');    // [C, A, X, B]
list.unlink(nodeA);               // [C, X, B]

// Node is now detached
print(nodeA.isAttached); // false
```

### LRU Cache Pattern

```dart
final cache = DoublyLinkedList<CacheEntry>();
final Map<String, Node<CacheEntry>> lookup = {};

void access(String key) {
  final node = lookup[key];
  if (node != null) {
    cache.moveToFront(node);  // O(1) — no searching
  }
}

void evictOldest() {
  if (cache.isNotEmpty) {
    final oldest = cache.tail!;
    lookup.remove(oldest.data.key);
    cache.unlink(oldest);  // O(1)
  }
}
```

## Safety Features

- **Ownership tracking**: Can't accidentally unlink a node from the wrong list
- **Fail-fast iteration**: Throws `ConcurrentModificationError` if modified during iteration
- **Detached nodes**: After `unlink()`, the node's `isAttached` becomes `false`

```dart
final list1 = DoublyLinkedList<int>([1, 2, 3]);
final list2 = DoublyLinkedList<int>([4, 5, 6]);

final node = list1.nodeOf(2)!;

list2.unlink(node);  // Throws! Node doesn't belong to list2.
```

## Installation

```yaml
dependencies:
  doubly_linked_list: ^1.0.1
```

## License

MIT
