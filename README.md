## KeyedSet

A keyed set is a hybrid of a set and a dictionary. In a keyed set, some attribute of the elements in the set is used as a key with which dictionary subscript operations may be used.

For example, imagine that we want a set of `Order` items, keyed by an order identifier, and we want to be able to look up items in this set by order identifier using a simple subscript:

```swift
struct Order: Keyed {
  static let keyAttribute = \Order.identifier
  let identifier: UUID
  var items: KeyedSet<OrderItem> = []
  init(identifier: UUID) {
    self.identifier = identifier
  }
  init() {
    self.init(identifier: UUID())
  }
}

let identifier = UUID()
var orders: KeyedSet<Order> = [
  Order(identifier: identifier),
  Order(),
  Order()
]

// We can now perform lookups using the identifier:
if let order = orders[identifier] {
  // Do something fun with this order
}
```

A `KeyedSet` is far more `Set` than `Dictionary`. The only `Dictionary`-like operation it supports is subscripting. In all other respects, `KeyedSet` is an ordinary `Set`. (Of course, `Set` is a value type, so `KeyedSet` is not a subtype of `Set`. More like a fraternal twin.)

### `Keyed`

In order to be placed into a `KeyedSet`, the element type must implement the `Keyed` protocol:

```swift
protocol Keyed: Hashable {
  associatedtype Key: Hashable
  static var keyAttribute: KeyPath<Self, Key> { get }
}
```

This protocol tells `KeyedSet` which attribute of the element type is to be used for dictionary subscript operations. Let us call this attribute the `key attribute`. _No two elements having the same key attribute may be present in the set at the same time._ Otherwise, an unrecoverable runtime exception may occur.

It is up to you to enforce this rule, but the easiest way to do so is to ensure that the element type is both `Hashable` and `Equatable` by the key attribute. If the element type conforms to the `Keyed` protocol, default implementations of `Hashable` and `Equatable` which follow this rule are provided.

### Dictionary Operations

As mentioned earlier, a `KeyedSet` is a set. The only dictionary operation it supports is subscripting. Subscripting is type-safe, and the type of the key used in dictionary subscripting is declared by the element type's `Keyed` implementation.

Subscripting is both readable and writable. When writing, it is important that the keys match. Saying something like `people["Bob"] = Person(name: "Fred")` will cause a runtime exception (assuming `name` is the key attribute).

In general, it is best not to use writable subscripting directly. Instead, use the standard set operations, e.g., `people.update(with: Person(name: "Fred"))`. Writable subscripting exists to permit in-place attribute mutations, e.g., `people["Bob"]?.age = 44`.

### Dictionary Operations on Sequences

This framework adds a subscript to all sequences whose element type conforms to `Keyed`. This subscript allows read-only (but pretty inefficient) key lookup operations.

```swift
let orders = [Order(identifier: identifier), Order(), Order()]
print(orders[key: identifier]!)
```

This subscript finds the first element with a conforming key.
