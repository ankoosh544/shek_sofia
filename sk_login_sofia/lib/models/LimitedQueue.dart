import 'dart:collection';

class LimitedQueue<T> {
  final int limit;
  final Queue<T> _queue;

  LimitedQueue(this.limit) : _queue = Queue<T>();

  void enqueue(T item) {
    while (_queue.length >= limit) {
      _queue.removeFirst();
    }
    _queue.add(item);
  }

  T? dequeue() {
    if (_queue.isEmpty) {
      return null;
    }
    return _queue.removeFirst();
  }

  int get length => _queue.length;

  bool get isEmpty => _queue.isEmpty;

  bool get isNotEmpty => _queue.isNotEmpty;

  List<T> toList() => _queue.toList();

  bool any(bool Function(T) test) {
    return _queue.toList().any(test);
  }

  T? get last {
    if (_queue.isEmpty) {
      return null;
    }
    return _queue.last;
  }

  Iterable<T> where(bool Function(T) test) {
    return _queue.toList().where(test);
  }
}
