### Stubbing

Support is provided for stubbing constants. Like with method stubs, the stubbed constants
will be restored to their original state when an example completes.

``` ruby
stub_const("Foo", fake_foo)
Foo # => fake_foo
```

Stubbed constant names must be fully qualified; the current module nesting is not
considered.

``` ruby
module MyGem
  class SomeClass; end
end

module MyGem
  describe "Something" do
    let(:fake_class) { Class.new }

    it "accidentally stubs the wrong constant" do
      # this stubs ::SomeClass (in the top-level namespace),
      # not MyGem::SomeClass like you probably mean.
      stub_const("SomeClass", fake_class)
    end

    it "stubs the right constant" do
      stub_const("MyGem::SomeClass", fake_class)
    end
  end
end
```

When you stub a constant that is a module or a class, nested constants on the original
module or class are not transferred by default, but you can use the
`:transfer_nested_constants` option to tell rspec-mocks to transfer them:

``` ruby
class CardDeck
  SUITS = [:Spades, :Diamonds, :Clubs, :Hearts]
  NUM_CARDS = 52
end

fake_class = Class.new
stub_const("CardDeck", fake_class)
CardDeck # => fake_class
CardDeck::SUITS # => raises uninitialized constant error
CardDeck::NUM_CARDS # => raises uninitialized constant error

stub_const("CardDeck", fake_class, :transfer_nested_constants => true)
CardDeck::SUITS # => [:Spades, :Diamonds, :Clubs, :Hearts]
CardDeck::NUM_CARDS # => 52

stub_const("CardDeck", fake_class, :transfer_nested_constants => [:SUITS])
CardDeck::SUITS # => [:Spades, :Diamonds, :Clubs, :Hearts]
CardDeck::NUM_CARDS # => raises uninitialized constant error
```

### Hiding

Support is also provided for hiding constants. Hiding a constant temporarily removes it; it is
restored to its original value after the test completes.

```ruby
FOO = 42
hide_const("FOO")
FOO # => NameError: uninitialized constant FOO
```

Like stubbed constants, names must be fully qualified.

Hiding constants that are already undefined has no effect.

```ruby
hide_const("NO_OP")
```
