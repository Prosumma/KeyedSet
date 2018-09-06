## KeyedSet

A hybrid of `Set` and `Dictionary`. Mostly a `Set`, but with `Dictionary`-like subscripting.

Imagine that we want a set of `Person` instances, unique by social security number, and we wish to perform lookups by social security number.

```swift
let belle = Person(ssn: "111-11-2222", name: "Isabella")
let greg = Person(ssn: "9876-54-321", name: "Greg")
let bob = Person(ssn: "123-45-6789", name: "Bob")
var people: KeyedSet<Person> = [belle, greg]
// A KeyedSet is a set, with all the usual SetAlgebra operations.
people.update(with: bob)
// But it provides dictionary-style lookup by key.
if let belle = people["111-11-2222"] {
  print(belle.name)
}
```

A `KeyedSet` is far more `Set` than `Dictionary`. The only `Dictionary` operation it supports is subscripting. In all other respects, `KeyedSet` is an ordinary `Set`. (Of course, `Set` is a value type, so `KeyedSet` is not a subtype of `Set`. More like a fraternal twin.)

### `Keyed`

In order to be placed into a `KeyedSet`, the element type must implement the `Keyed` protocol:

```swift
protocol Keyed: Hashable {
  associatedtype KeyedSetKey: Hashable
  static var keyedSetKeyAttribute: KeyPath<Self, Key> { get }
}

// `Keyed` provides `KeyedSet`-compliant default
// implementations of `Hashable` and `Equatable`.
struct Person: Keyed {
  // This is how our first example knew which attribute
  // to use for key lookup.
  static let keyedSetKeyAttribute = \Person.ssn
  let ssn: String
  let name: String
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
