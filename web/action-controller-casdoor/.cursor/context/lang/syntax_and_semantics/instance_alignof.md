# instance_alignof

The `instance_alignof` expression returns an `Int32` with the instance alignment of a given class.

Unlike [`alignof`](alignof.md) which would return the alignment of the reference
(pointer) to the allocated object, `instance_alignof` returns the alignment of
the allocated object itself.

For example:

```crystal
class Foo
end

class Bar
  def initialize(@x : Int64)
  end
end

instance_alignof(Foo) # => 4
instance_alignof(Bar) # => 8
```

Even though `Foo` has no instance variables, the compiler always includes an extra `Int32` field for the type id of the object. That's why the instance alignment ends up being 4 and not 1.
