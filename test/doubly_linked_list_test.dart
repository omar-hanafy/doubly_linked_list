import 'package:test/test.dart';
import 'package:doubly_linked_list/doubly_linked_list.dart';

void main() {
  // ---- Helpers ----

  void expectInvariants<E>(DoublyLinkedList<E> list) {
    expect(list.length, greaterThanOrEqualTo(0));

    if (list.isEmpty) {
      expect(list.head, isNull);
      expect(list.tail, isNull);
      expect(list.nodes, isEmpty);
      expect(list.nodesReversed, isEmpty);
      return;
    }

    final head = list.head!;
    final tail = list.tail!;

    expect(head.prev, isNull, reason: 'Head.prev must be null');
    expect(tail.next, isNull, reason: 'Tail.next must be null');
    expect(head.isAttached, isTrue);
    expect(tail.isAttached, isTrue);

    // Forward traversal: count, link consistency, no cycles.
    var count = 0;
    Node<E>? prev;
    var n = list.head;
    while (n != null) {
      expect(
        n.isAttached,
        isTrue,
        reason: 'All nodes in list must be attached',
      );

      if (prev == null) {
        expect(n.prev, isNull, reason: 'Head.prev must be null');
      } else {
        expect(
          n.prev,
          same(prev),
          reason: 'prev link must match the actual previous node',
        );
        expect(
          prev.next,
          same(n),
          reason: 'next link of previous must point to current',
        );
      }

      prev = n;
      n = n.next;

      count++;
      if (count > list.length) {
        fail('Cycle detected or length mismatch while walking next pointers.');
      }
    }

    expect(count, list.length, reason: 'Forward node count must equal length');
    expect(prev, same(tail), reason: 'Last node reached must equal tail');

    // Backward traversal: count, link consistency, no cycles.
    count = 0;
    Node<E>? next;
    n = list.tail;
    while (n != null) {
      expect(
        n.isAttached,
        isTrue,
        reason: 'All nodes in list must be attached',
      );

      if (next == null) {
        expect(n.next, isNull, reason: 'Tail.next must be null');
      } else {
        expect(
          n.next,
          same(next),
          reason: 'next link must match the actual next node',
        );
        expect(
          next.prev,
          same(n),
          reason: 'prev link of next must point back to current',
        );
      }

      next = n;
      n = n.prev;

      count++;
      if (count > list.length) {
        fail('Cycle detected or length mismatch while walking prev pointers.');
      }
    }

    expect(count, list.length, reason: 'Backward node count must equal length');
    expect(next, same(head), reason: 'Last node reached must equal head');

    // Cross-check nodes iterable vs list iteration.
    final valuesFromNodes = list.nodes.map((x) => x.data).toList();
    final valuesFromList = list.toList();
    expect(valuesFromNodes, valuesFromList);

    final valuesFromNodesRev = list.nodesReversed.map((x) => x.data).toList();
    expect(valuesFromNodesRev, valuesFromList.reversed.toList());

    // Basic getters.
    expect(list.first, equals(head.data));
    expect(list.last, equals(tail.data));
    if (list.length == 1) {
      expect(list.single, equals(head.data));
    }
  }

  void expectValues<E>(DoublyLinkedList<E> list, List<E> expected) {
    expect(list.length, expected.length);
    expect(list.toList(), expected);
    if (expected.isEmpty) {
      expect(list.head, isNull);
      expect(list.tail, isNull);
    } else {
      expect(list.head, isNotNull);
      expect(list.tail, isNotNull);
      expect(list.head!.data, equals(expected.first));
      expect(list.tail!.data, equals(expected.last));
    }
    expectInvariants(list);
  }

  final throwsCME = throwsA(isA<ConcurrentModificationError>());
  final throwsArgError = throwsA(isA<ArgumentError>());
  final throwsRangeError = throwsA(isA<RangeError>());
  final throwsStateError = throwsA(isA<StateError>());
  final throwsUnsupported = throwsA(isA<UnsupportedError>());

  // ---- Tests ----

  group('DoublyLinkedList - construction', () {
    test('starts empty by default', () {
      final list = DoublyLinkedList<int>();
      expectValues(list, const []);
    });

    test('constructs from iterable', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      expectValues(list, const [1, 2, 3]);
    });

    test('filled(length=0) is empty', () {
      final list = DoublyLinkedList<int>.filled(0, 7);
      expectValues(list, const []);
    });

    test('filled builds correct values', () {
      final list = DoublyLinkedList<String>.filled(3, 'x');
      expectValues(list, const ['x', 'x', 'x']);
    });

    test('filled throws on negative length', () {
      expect(() => DoublyLinkedList<int>.filled(-1, 0), throwsRangeError);
    });

    test('generate builds correct values', () {
      final list = DoublyLinkedList<int>.generate(5, (i) => i * 2);
      expectValues(list, const [0, 2, 4, 6, 8]);
    });

    test('generate throws on negative length', () {
      expect(
        () => DoublyLinkedList<int>.generate(-2, (i) => i),
        throwsRangeError,
      );
    });
  });

  group('Basic operations - append/prepend/access/iteration', () {
    test('append returns node and updates head/tail', () {
      final list = DoublyLinkedList<int>();

      final n1 = list.append(1);
      expect(n1.isAttached, isTrue);
      expect(list.head, same(n1));
      expect(list.tail, same(n1));
      expectValues(list, const [1]);

      final n2 = list.append(2);
      expect(list.head, same(n1));
      expect(list.tail, same(n2));
      expect(n2.prev, same(n1));
      expect(n1.next, same(n2));
      expectValues(list, const [1, 2]);
    });

    test('prepend returns node and updates head/tail', () {
      final list = DoublyLinkedList<int>();

      final n1 = list.prepend(2);
      expect(list.head, same(n1));
      expect(list.tail, same(n1));
      expectValues(list, const [2]);

      final n0 = list.prepend(1);
      expect(list.head, same(n0));
      expect(list.tail, same(n1));
      expect(n0.next, same(n1));
      expect(n1.prev, same(n0));
      expectValues(list, const [1, 2]);
    });

    test('indexing and assignment work', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      expect(list[0], 1);
      expect(list[1], 2);
      expect(list[2], 3);

      list[1] = 99;
      expectValues(list, const [1, 99, 3]);
    });

    test('for-in iteration yields elements in order', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final seen = <int>[];
      for (final e in list) {
        seen.add(e);
      }
      expect(seen, const [1, 2, 3, 4]);
      expectInvariants(list);
    });

    test('nodes iterable yields stable node handles', () {
      final list = DoublyLinkedList<String>(['a', 'b', 'c']);
      final ns = list.nodes.toList();
      expect(ns.length, 3);
      expect(ns.map((n) => n.data).toList(), const ['a', 'b', 'c']);

      expect(ns[0].next, same(ns[1]));
      expect(ns[1].prev, same(ns[0]));
      expect(ns[1].next, same(ns[2]));
      expect(ns[2].prev, same(ns[1]));

      expectInvariants(list);
    });

    test('mutating node.data reflects in the list (non-structural)', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n2 = list.nodeOf(2)!;
      n2.data = 200;
      expectValues(list, const [1, 200, 3]);
    });
  });

  group('Node operations - nodeAt/nodeOf/insert/unlink/remove', () {
    test('nodeAt returns correct nodes and throws out-of-range', () {
      final list = DoublyLinkedList<int>([10, 20, 30]);
      expect(list.nodeAt(0).data, 10);
      expect(list.nodeAt(2).data, 30);

      expect(() => list.nodeAt(-1), throwsRangeError);
      expect(() => list.nodeAt(3), throwsRangeError);
    });

    test('nodeAtOrNull returns null out-of-range', () {
      final list = DoublyLinkedList<int>([10, 20, 30]);
      expect(list.nodeAtOrNull(-1), isNull);
      expect(list.nodeAtOrNull(3), isNull);
      expect(list.nodeAtOrNull(1)!.data, 20);
      expectInvariants(list);
    });

    test('nodeOf returns first matching node', () {
      final list = DoublyLinkedList<int>([1, 2, 1, 3]);
      final n = list.nodeOf(1)!;
      expect(n, same(list.head));
      expect(n.data, 1);
      expectInvariants(list);
    });

    test('insertAfter inserts in middle', () {
      final list = DoublyLinkedList<int>([1, 3]);
      final one = list.nodeOf(1)!;

      final inserted = list.insertAfter(one, 2);
      expect(inserted.isAttached, isTrue);
      expectValues(list, const [1, 2, 3]);

      expect(inserted.prev, same(one));
      expect(inserted.next!.data, 3);
    });

    test('insertAfter on tail behaves like append', () {
      final list = DoublyLinkedList<int>([1]);
      final tail = list.tail!;

      final inserted = list.insertAfter(tail, 2);
      expect(list.tail, same(inserted));
      expectValues(list, const [1, 2]);
    });

    test('insertBefore inserts in middle', () {
      final list = DoublyLinkedList<int>([2, 3]);
      final two = list.nodeOf(2)!;

      final inserted = list.insertBefore(two, 1);
      expect(inserted.isAttached, isTrue);
      expectValues(list, const [1, 2, 3]);

      expect(inserted.next, same(two));
      expect(inserted.prev, isNull);
    });

    test('insertBefore on head behaves like prepend', () {
      final list = DoublyLinkedList<int>([2]);
      final head = list.head!;

      final inserted = list.insertBefore(head, 1);
      expect(list.head, same(inserted));
      expectValues(list, const [1, 2]);
    });

    test('unlink detaches a middle node', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n2 = list.nodeOf(2)!;

      list.unlink(n2);

      expectValues(list, const [1, 3]);
      expect(n2.isAttached, isFalse);
      expect(n2.prev, isNull);
      expect(n2.next, isNull);
    });

    test('unlink detaches head and updates head', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n1 = list.head!;

      list.unlink(n1);

      expectValues(list, const [2, 3]);
      expect(n1.isAttached, isFalse);
      expect(n1.prev, isNull);
      expect(n1.next, isNull);
    });

    test('unlink detaches tail and updates tail', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n3 = list.tail!;

      list.unlink(n3);

      expectValues(list, const [1, 2]);
      expect(n3.isAttached, isFalse);
      expect(n3.prev, isNull);
      expect(n3.next, isNull);
    });

    test('tryUnlink returns false for detached node', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n2 = list.nodeOf(2)!;

      list.unlink(n2);
      expect(list.tryUnlink(n2), isFalse);
      expectValues(list, const [1, 3]);
    });

    test('removeNode delegates to tryUnlink', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n2 = list.nodeOf(2)!;

      expect(list.removeNode(n2), isTrue);
      expectValues(list, const [1, 3]);

      // Already detached -> false
      expect(list.removeNode(n2), isFalse);
      expectValues(list, const [1, 3]);
    });

    test('removeAt returns removed value', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final removed = list.removeAt(1);
      expect(removed, 2);
      expectValues(list, const [1, 3]);
    });

    test('remove(value) removes first matching', () {
      final list = DoublyLinkedList<int>([1, 2, 2, 3]);
      final removed = list.remove(2);
      expect(removed, isTrue);
      expectValues(list, const [1, 2, 3]);

      expect(list.remove(999), isFalse);
      expectValues(list, const [1, 2, 3]);
    });
  });

  group('Move operations - moveToFront/moveToBack/moveAfter/moveBefore', () {
    test('moveToFront moves a middle node to head', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final n3 = list.nodeOf(3)!;

      list.moveToFront(n3);

      expect(list.head, same(n3));
      expectValues(list, const [3, 1, 2, 4]);
      expect(n3.isAttached, isTrue);
    });

    test('moveToFront on head is a no-op', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final head = list.head!;
      list.moveToFront(head);
      expectValues(list, const [1, 2, 3]);
    });

    test('moveToBack moves a middle node to tail', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final n2 = list.nodeOf(2)!;

      list.moveToBack(n2);

      expect(list.tail, same(n2));
      expectValues(list, const [1, 3, 4, 2]);
      expect(n2.isAttached, isTrue);
    });

    test('moveToBack on tail is a no-op', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final tail = list.tail!;
      list.moveToBack(tail);
      expectValues(list, const [1, 2, 3]);
    });

    test('moveAfter moves node after target', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final n1 = list.nodeOf(1)!;
      final n3 = list.nodeOf(3)!;

      list.moveAfter(n1, n3);

      expectValues(list, const [2, 3, 1, 4]);
      expect(n1.isAttached, isTrue);
      expect(n3.next, same(n1));
      expect(n1.prev, same(n3));
    });

    test('moveAfter to tail works', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n1 = list.nodeOf(1)!;
      final tail = list.tail!;

      list.moveAfter(n1, tail);

      expect(list.tail, same(n1));
      expectValues(list, const [2, 3, 1]);
    });

    test('moveAfter when already after target is a no-op', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n2 = list.nodeOf(2)!;
      final n1 = list.nodeOf(1)!;

      // n2 is already after n1
      list.moveAfter(n2, n1);

      expectValues(list, const [1, 2, 3]);
    });

    test('moveBefore moves node before target', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final n4 = list.nodeOf(4)!;
      final n2 = list.nodeOf(2)!;

      list.moveBefore(n4, n2);

      expectValues(list, const [1, 4, 2, 3]);
      expect(n4.isAttached, isTrue);
      expect(n4.next, same(n2));
      expect(n2.prev, same(n4));
    });

    test('moveBefore to head works', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n3 = list.nodeOf(3)!;
      final head = list.head!;

      list.moveBefore(n3, head);

      expect(list.head, same(n3));
      expectValues(list, const [3, 1, 2]);
    });

    test('moveBefore when already before target is a no-op', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n1 = list.nodeOf(1)!;
      final n2 = list.nodeOf(2)!;

      // n1 is already before n2
      list.moveBefore(n1, n2);

      expectValues(list, const [1, 2, 3]);
    });
  });

  group('Swap operations - adjacent and non-adjacent', () {
    test('swap adjacent nodes (head <-> next)', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n1 = list.nodeOf(1)!;
      final n2 = list.nodeOf(2)!;

      list.swapNodes(n1, n2);

      expect(list.head, same(n2));
      expectValues(list, const [2, 1, 3]);
    });

    test('swap adjacent nodes (prev <-> tail)', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n2 = list.nodeOf(2)!;
      final n3 = list.nodeOf(3)!;

      list.swapNodes(n2, n3);

      expect(list.tail, same(n2));
      expectValues(list, const [1, 3, 2]);
    });

    test('swap non-adjacent nodes in middle', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final n1 = list.nodeOf(1)!;
      final n3 = list.nodeOf(3)!;

      list.swapNodes(n1, n3);

      expectValues(list, const [3, 2, 1, 4]);
      expect(list.head, same(n3));
    });

    test('swap head and tail', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final head = list.head!;
      final tail = list.tail!;

      list.swapNodes(head, tail);

      expectValues(list, const [4, 2, 3, 1]);
      expect(list.head, same(tail));
      expect(list.tail, same(head));
    });

    test('swap same node is a no-op', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final n2 = list.nodeOf(2)!;

      list.swapNodes(n2, n2);

      expectValues(list, const [1, 2, 3]);
    });
  });

  group('Reverse', () {
    test('reverse empty does nothing', () {
      final list = DoublyLinkedList<int>();
      list.reverse();
      expectValues(list, const []);
    });

    test('reverse single does nothing', () {
      final list = DoublyLinkedList<int>([1]);
      list.reverse();
      expectValues(list, const [1]);
    });

    test('reverse multiple reverses order and fixes head/tail', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final oldHead = list.head!;
      final oldTail = list.tail!;

      list.reverse();

      expectValues(list, const [4, 3, 2, 1]);
      expect(list.head, same(oldTail));
      expect(list.tail, same(oldHead));
    });
  });

  group('Edge cases - empty/single/boundaries/length', () {
    test('empty list getters throw', () {
      final list = DoublyLinkedList<int>();
      expect(() => list.first, throwsStateError);
      expect(() => list.last, throwsStateError);
      expect(() => list.single, throwsStateError);
    });

    test('single list single getter returns element', () {
      final list = DoublyLinkedList<int>([42]);
      expect(list.single, 42);
      expectValues(list, const [42]);
    });

    test('insert boundary cases', () {
      final list = DoublyLinkedList<int>([2, 3]);
      list.insert(0, 1); // prepend
      expectValues(list, const [1, 2, 3]);

      list.insert(list.length, 4); // append
      expectValues(list, const [1, 2, 3, 4]);
    });

    test('insert out-of-range throws', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      expect(() => list.insert(-1, 0), throwsRangeError);
      expect(() => list.insert(4, 0), throwsRangeError);
    });

    test('removeAt out-of-range throws', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      expect(() => list.removeAt(-1), throwsRangeError);
      expect(() => list.removeAt(3), throwsRangeError);
    });

    test('length shrink truncates and detaches removed nodes', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final n3 = list.nodeOf(3)!;
      final n4 = list.nodeOf(4)!;

      list.length = 2;

      expectValues(list, const [1, 2]);
      expect(n3.isAttached, isFalse);
      expect(n4.isAttached, isFalse);
      expect(n3.prev, isNull);
      expect(n3.next, isNull);
      expect(n4.prev, isNull);
      expect(n4.next, isNull);
    });

    test('length = 0 clears and detaches all nodes', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final nodes = list.nodes.toList();

      list.length = 0;

      expectValues(list, const []);
      for (final n in nodes) {
        expect(n.isAttached, isFalse);
        expect(n.prev, isNull);
        expect(n.next, isNull);
      }
    });

    test('length increase throws for non-nullable E', () {
      final list = DoublyLinkedList<int>([1, 2]);
      expect(() => list.length = 3, throwsUnsupported);
      expectValues(list, const [1, 2]);
    });

    test('length increase pads nulls for nullable E', () {
      final list = DoublyLinkedList<int?>([1]);
      list.length = 4;
      expectValues(list, const [1, null, null, null]);
      expect(list.tail!.data, isNull);
    });

    test('length negative throws', () {
      final list = DoublyLinkedList<int>([1, 2]);
      expect(() => list.length = -1, throwsRangeError);
      expectValues(list, const [1, 2]);
    });
  });

  group('Fail-fast - ConcurrentModificationError', () {
    test('iterator throws CME on structural modification (append)', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final it = list.iterator;

      expect(it.moveNext(), isTrue);
      list.append(4);

      expect(() => it.moveNext(), throwsCME);
    });

    test('iterator throws CME even if modified before first moveNext', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final it = list.iterator;

      list.prepend(0);
      expect(() => it.moveNext(), throwsCME);
    });

    test('nodes iterator throws CME on structural modification', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final it = list.nodes.iterator;

      expect(it.moveNext(), isTrue);
      list.append(4);

      expect(() => it.moveNext(), throwsCME);
    });

    test('nodesReversed iterator throws CME on structural modification', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final it = list.nodesReversed.iterator;

      expect(it.moveNext(), isTrue);
      list.prepend(0);

      expect(() => it.moveNext(), throwsCME);
    });

    test('reversed iterable throws CME on structural modification', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final it = list.reversed.iterator;

      expect(it.moveNext(), isTrue);
      list.removeAt(0);

      expect(() => it.moveNext(), throwsCME);
    });

    test('for-in throws CME if structurally modified during iteration', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);

      expect(() {
        for (final e in list) {
          if (e == 1) {
            list.append(999); // structural
          }
        }
      }, throwsCME);
    });

    test('NO CME when only modifying element values (list[i] = ...)', () {
      final list = DoublyLinkedList<int>([1, 2, 3, 4]);
      final it = list.iterator;

      expect(it.moveNext(), isTrue); // current is 1
      list[1] = 200; // non-structural
      expect(() => it.moveNext(), returnsNormally);

      // Ensure list reflects change.
      expectValues(list, const [1, 200, 3, 4]);
    });

    test('NO CME when only modifying node.data during iteration', () {
      final list = DoublyLinkedList<int>([1, 2, 3]);
      final node2 = list.nodeOf(2)!;

      final it = list.iterator;
      expect(it.moveNext(), isTrue); // 1
      node2.data = 222; // non-structural
      expect(() => it.moveNext(), returnsNormally);

      expectValues(list, const [1, 222, 3]);
    });
  });

  group('Ownership - cross-list corruption prevention', () {
    test('node from another list cannot be unlinked/inserted/moved/swapped',
        () {
      final a = DoublyLinkedList<int>([1, 2, 3]);
      final b = DoublyLinkedList<int>([10, 20]);

      final aNode = a.nodeOf(2)!;
      final bNode = b.nodeOf(10)!;

      // Structural methods that require ownership should throw.
      expect(() => b.unlink(aNode), throwsArgError);
      expect(() => b.insertAfter(aNode, 99), throwsArgError);
      expect(() => b.insertBefore(aNode, 99), throwsArgError);
      expect(() => b.moveToFront(aNode), throwsArgError);
      expect(() => b.moveToBack(aNode), throwsArgError);
      expect(() => b.moveAfter(aNode, bNode), throwsArgError);
      expect(() => b.moveBefore(aNode, bNode), throwsArgError);
      expect(() => b.swapNodes(bNode, aNode), throwsArgError);

      // Non-throwing "try" API should return false and not modify either list.
      expect(b.tryUnlink(aNode), isFalse);

      expectValues(a, const [1, 2, 3]);
      expectValues(b, const [10, 20]);
    });

    test(
      'detached node cannot be used again (throws) and tryUnlink returns false',
      () {
        final list = DoublyLinkedList<int>([1, 2, 3]);
        final n2 = list.nodeOf(2)!;

        list.unlink(n2);
        expectValues(list, const [1, 3]);

        expect(n2.isAttached, isFalse);
        expect(list.tryUnlink(n2), isFalse);

        expect(() => list.unlink(n2), throwsArgError);
        expect(() => list.insertAfter(n2, 99), throwsArgError);
        expect(() => list.moveToFront(n2), throwsArgError);
      },
    );
  });

  group(
    'ListBase/ListMixin compliance - addAll/insertAll/removeWhere/etc.',
    () {
      test('addAll appends values in order', () {
        final list = DoublyLinkedList<int>([1]);
        list.addAll([2, 3, 4]);
        expectValues(list, const [1, 2, 3, 4]);
      });

      test('addAll with empty iterable does nothing', () {
        final list = DoublyLinkedList<int>([1, 2]);
        list.addAll(const []);
        expectValues(list, const [1, 2]);
      });

      test('insertAll at head', () {
        final list = DoublyLinkedList<int>([3, 4]);
        list.insertAll(0, [1, 2]);
        expectValues(list, const [1, 2, 3, 4]);
      });

      test('insertAll at tail', () {
        final list = DoublyLinkedList<int>([1, 2]);
        list.insertAll(list.length, [3, 4]);
        expectValues(list, const [1, 2, 3, 4]);
      });

      test('insertAll in middle', () {
        final list = DoublyLinkedList<int>([1, 4]);
        list.insertAll(1, [2, 3]);
        expectValues(list, const [1, 2, 3, 4]);
      });

      test('insertAll with empty iterable does nothing', () {
        final list = DoublyLinkedList<int>([1, 2, 3]);
        list.insertAll(1, const []);
        expectValues(list, const [1, 2, 3]);
      });

      test('insertAll out-of-range throws', () {
        final list = DoublyLinkedList<int>([1, 2, 3]);
        expect(() => list.insertAll(-1, [9]), throwsRangeError);
        expect(() => list.insertAll(4, [9]), throwsRangeError);
        expectValues(list, const [1, 2, 3]);
      });

      test('removeWhere removes matching and detaches nodes', () {
        final list = DoublyLinkedList<int>([1, 2, 3, 4, 5]);
        final n2 = list.nodeOf(2)!;
        final n4 = list.nodeOf(4)!;

        list.removeWhere((e) => e.isEven);

        expectValues(list, const [1, 3, 5]);
        expect(n2.isAttached, isFalse);
        expect(n4.isAttached, isFalse);
        expect(n2.prev, isNull);
        expect(n2.next, isNull);
      });

      test('retainWhere keeps matching and detaches others', () {
        final list = DoublyLinkedList<int>([1, 2, 3, 4, 5]);
        final n1 = list.nodeOf(1)!;
        final n3 = list.nodeOf(3)!;
        final n5 = list.nodeOf(5)!;

        list.retainWhere((e) => e.isEven);

        expectValues(list, const [2, 4]);
        expect(n1.isAttached, isFalse);
        expect(n3.isAttached, isFalse);
        expect(n5.isAttached, isFalse);
      });

      test('indexOf supports start parameter', () {
        final list = DoublyLinkedList<int>([1, 2, 1, 2]);
        expect(list.indexOf(1), 0);
        expect(list.indexOf(1, 1), 2);
        expect(list.indexOf(2, -10), 1);
        expect(list.indexOf(1, 999), -1);
        expectInvariants(list);
      });

      test('lastIndexOf supports start parameter', () {
        final list = DoublyLinkedList<int>([1, 2, 1, 2]);
        expect(list.lastIndexOf(1), 2);
        expect(list.lastIndexOf(2), 3);
        expect(list.lastIndexOf(2, 2), 1);
        expect(list.lastIndexOf(2, -1), -1);
        expectInvariants(list);
      });

      test('sublist works', () {
        final list = DoublyLinkedList<int>([1, 2, 3, 4, 5]);
        expect(list.sublist(1, 4), const [2, 3, 4]);
        expectInvariants(list);
      });

      test('removeRange works', () {
        final list = DoublyLinkedList<int>([1, 2, 3, 4, 5]);
        list.removeRange(1, 4); // removes 2,3,4
        expectValues(list, const [1, 5]);
      });

      test('replaceRange works', () {
        final list = DoublyLinkedList<int>([1, 2, 3, 4]);
        list.replaceRange(1, 3, [9, 8]); // replaces 2,3 with 9,8
        expectValues(list, const [1, 9, 8, 4]);
      });

      test('setAll works', () {
        final list = DoublyLinkedList<int>([1, 2, 3, 4]);
        list.setAll(1, [9, 8]);
        expectValues(list, const [1, 9, 8, 4]);
      });

      test('fillRange works', () {
        final list = DoublyLinkedList<int>([1, 2, 3, 4]);
        list.fillRange(1, 3, 0);
        expectValues(list, const [1, 0, 0, 4]);
      });

      test('toString matches List-like formatting', () {
        final list = DoublyLinkedList<int>([1, 2, 3]);
        expect(list.toString(), '[1, 2, 3]');
        expectInvariants(list);
      });

      test('reversed returns elements in reverse order', () {
        final list = DoublyLinkedList<int>([1, 2, 3]);
        expect(list.reversed.toList(), const [3, 2, 1]);
        expectInvariants(list);
      });
    },
  );
}
