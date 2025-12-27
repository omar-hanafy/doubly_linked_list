/// A non-intrusive doubly linked list for Dart.
///
/// This package provides [DoublyLinkedList], a generic doubly linked list that
/// implements `List<E>` and exposes stable [Node] handles for O(1) operations.
///
/// Unlike `dart:collection`'s intrusive `LinkedList`, this works with any type:
/// ```dart
/// final list = DoublyLinkedList<int>([1, 2, 3]);
/// final node = list.append(4);
/// list.moveToFront(node);  // O(1)
/// ```
///
/// See the [README](https://github.com/omar-hanafy/doubly_linked_list) for
/// detailed usage and examples.
library;

export 'src/doubly_linked_list.dart';
