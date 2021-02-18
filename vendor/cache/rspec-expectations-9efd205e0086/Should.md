# `should` and `should_not` syntax

From the  beginning RSpec::Expectations provided `should` and `should_not` methods
to define expectations on any object. In version 2.11 `expect` method was
introduced which is now the recommended way to define expectations on an object.

### Why switch over from `should` to `expect`

#### Fix edge case issues

`should` and `should_not` work by being added to every object. However, RSpec
does not own every object and cannot ensure they work consistently on every object.
In particular, they can lead to surprising failures when used with BasicObject-subclassed
proxy objects.

`expect` avoids these problems altogether by not needing to be available on all objects.

#### Unification of block and value syntaxes

Before version 2.11 `expect` was just a more readable alternative for block
expectations. Since version 2.11 `expect` can be used for both block and value
expectations.

```ruby
expect(actual).to eq(expected)
expect { ... }.to raise_error(ErrorClass)
```

See
[http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax](http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax)
For a detailed explanation

### One-liners

The one-liner syntax supported by
[rspec-core](http://rubydoc.info/gems/rspec-core)  uses `should` even when
`config.syntax = :expect`. It reads better than the alternative, and does not
require a global monkey patch:

```ruby
describe User do
  it { should validate_presence_of :email }
end
```

It can also be expressed with the `is_expected` syntax:

```ruby
describe User do
  it { is_expected.to validate_presence_of :email }
end
```

### Using either `expect` or `should` or both

By default, both `expect` and `should` syntaxes are available. In the future,
the default may be changed to only enable the `expect` syntax.

If you want your project to only use any one of these syntaxes, you can configure
it:

```ruby
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect             # disables `should`
    # or
    c.syntax = :should             # disables `expect`
    # or
    c.syntax = [:should, :expect]  # default, enables both `should` and `expect`
  end
end
```

See
[RSpec::Expectations::Syntax#expect](http://rubydoc.info/gems/rspec-expectations/RSpec/Expectations/Syntax:expect)
for more information.

## Usage

The `should` and `should_not` methods can be used to define expectations on any
object.

```ruby
actual.should eq expected
actual.should be > 3
[1, 2, 3].should_not include 4
```

## Using Built-in matchers

### Equivalence

```ruby
actual.should     eq(expected)  # passes if actual == expected
actual.should     == expected   # passes if actual == expected
actual.should_not eql(expected) # passes if actual.eql?(expected)
```

Note: we recommend the `eq` matcher over `==` to avoid Ruby's "== in a
useless context" warning when the `==` matcher is used anywhere but the
last statement of an example.

### Identity

```ruby
actual.should     be(expected)    # passes if actual.equal?(expected)
actual.should_not equal(expected) # passes if actual.equal?(expected)
```

### Comparisons

```ruby
actual.should be >  expected
actual.should be >= expected
actual.should be <= expected
actual.should be <  expected
actual.should be_within(delta).of(expected)
```

### Regular expressions

```ruby
actual.should match(/expression/)
actual.should =~ /expression/
```

### Types/classes

```ruby
actual.should     be_an_instance_of(expected)
actual.should_not be_a_kind_of(expected)
```

### Truthiness

```ruby
actual.should be_true  # passes if actual is truthy (not nil or false)
actual.should be_false # passes if actual is falsy (nil or false)
actual.should be_nil   # passes if actual is nil
```

### Predicate matchers

```ruby
actual.should     be_xxx         # passes if actual.xxx?
actual.should_not have_xxx(:arg) # passes if actual.has_xxx?(:arg)
```

### Ranges (Ruby >= 1.9 only)

```ruby
(1..10).should cover(3)
```

### Collection membership

```ruby
actual.should include(expected)
actual.should start_with(expected)
actual.should end_with(expected)
```

#### Examples

```ruby
[1,2,3].should       include(1)
[1,2,3].should       include(1, 2)
[1,2,3].should       start_with(1)
[1,2,3].should       start_with(1,2)
[1,2,3].should       end_with(3)
[1,2,3].should       end_with(2,3)
{:a => 'b'}.should   include(:a => 'b')
"this string".should include("is str")
"this string".should start_with("this")
"this string".should end_with("ring")
```
