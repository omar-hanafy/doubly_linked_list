import 'package:doubly_linked_list/doubly_linked_list.dart';

void main() {
  // Basic usage - just like a List
  final list = DoublyLinkedList<int>([1, 2, 3]);
  print('Initial: $list'); // [1, 2, 3]

  // Append and prepend in O(1)
  list.add(4);
  list.insert(0, 0);
  print('After add/insert: $list'); // [0, 1, 2, 3, 4]

  // ═══════════════════════════════════════════════════════════════════════════
  // The Real Power: Node Handles for O(1) Operations
  // ═══════════════════════════════════════════════════════════════════════════

  final cache = DoublyLinkedList<String>();

  // Get stable handles when inserting
  final nodeA = cache.append('A');
  final nodeB = cache.append('B');
  final nodeC = cache.append('C');
  print('\nCache: $cache'); // [A, B, C]

  // O(1) move to front (LRU cache pattern)
  cache.moveToFront(nodeC);
  print('After moveToFront(C): $cache'); // [C, A, B]

  // O(1) insert relative to a known node
  cache.insertAfter(nodeA, 'A.5');
  print('After insertAfter(A, "A.5"): $cache'); // [C, A, A.5, B]

  // O(1) remove by handle (no searching!)
  cache.unlink(nodeB);
  print('After unlink(B): $cache'); // [C, A, A.5]

  // Check if node is still attached
  print('nodeB.isAttached: ${nodeB.isAttached}'); // false

  // ═══════════════════════════════════════════════════════════════════════════
  // Simple LRU Cache Example
  // ═══════════════════════════════════════════════════════════════════════════

  print('\n--- LRU Cache Demo ---');
  final lru = SimpleLruCache<String, int>(capacity: 3);

  lru.put('a', 1);
  lru.put('b', 2);
  lru.put('c', 3);
  print('After adding a, b, c: ${lru.keys}'); // [c, b, a] (most recent first)

  lru.get('a'); // Access 'a', moves it to front
  print('After accessing a: ${lru.keys}'); // [a, c, b]

  lru.put('d', 4); // Exceeds capacity, evicts oldest ('b')
  print('After adding d: ${lru.keys}'); // [d, a, c]
}

/// A simple LRU cache using DoublyLinkedList + Map.
class SimpleLruCache<K, V> {
  SimpleLruCache({required this.capacity});

  final int capacity;
  final DoublyLinkedList<MapEntry<K, V>> _list = DoublyLinkedList();
  final Map<K, Node<MapEntry<K, V>>> _lookup = {};

  Iterable<K> get keys => _list.map((e) => e.key);

  V? get(K key) {
    final node = _lookup[key];
    if (node == null) return null;

    // Move to front on access (O(1))
    _list.moveToFront(node);
    return node.data.value;
  }

  void put(K key, V value) {
    if (_lookup.containsKey(key)) {
      // Update existing
      final node = _lookup[key]!;
      node.data = MapEntry(key, value);
      _list.moveToFront(node);
    } else {
      // Evict if at capacity
      if (_list.length >= capacity) {
        final oldest = _list.tail!;
        _lookup.remove(oldest.data.key);
        _list.unlink(oldest);
      }

      // Insert new
      final node = _list.prepend(MapEntry(key, value));
      _lookup[key] = node;
    }
  }
}
