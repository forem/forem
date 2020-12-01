rspec-expectations ships with a number of built-in matchers. Each matcher can be used
with `expect(..).to` or `expect(..).not_to` to define positive and negative expectations
respectively on an object. Most matchers can also be accessed using the `(...).should` and
`(...).should_not` syntax; see [using should syntax](https://github.com/rspec/rspec-expectations/blob/main/Should.md) for why we recommend using `expect`.

e.g.

    expect(result).to   eq(3)
    expect(list).not_to be_empty
    pi.should be > 3

## Object identity

    expect(actual).to be(expected) # passes if actual.equal?(expected)

## Object equivalence

    expect(actual).to eq(expected) # passes if actual == expected

## Optional APIs for identity/equivalence

    expect(actual).to eql(expected)   # passes if actual.eql?(expected)
    expect(actual).to equal(expected) # passes if actual.equal?(expected)

    # NOTE: `expect` does not support `==` matcher.

## Comparisons

    expect(actual).to be >  expected
    expect(actual).to be >= expected
    expect(actual).to be <= expected
    expect(actual).to be <  expected
    expect(actual).to be_between(minimum, maximum).inclusive
    expect(actual).to be_between(minimum, maximum).exclusive
    expect(actual).to match(/expression/)
    expect(actual).to be_within(delta).of(expected)
    expect(actual).to start_with expected
    expect(actual).to end_with expected

    # NOTE: `expect` does not support `=~` matcher.

## Types/classes/response

    expect(actual).to be_instance_of(expected)
    expect(actual).to be_kind_of(expected)
    expect(actual).to respond_to(expected)

## Truthiness and existentialism

    expect(actual).to be_truthy    # passes if actual is truthy (not nil or false)
    expect(actual).to be true      # passes if actual == true
    expect(actual).to be_falsey    # passes if actual is falsy (nil or false)
    expect(actual).to be false     # passes if actual == false
    expect(actual).to be_nil       # passes if actual is nil
    expect(actual).to exist        # passes if actual.exist? and/or actual.exists? are truthy
    expect(actual).to exist(*args) # passes if actual.exist?(*args) and/or actual.exists?(*args) are truthy

## Expecting errors

    expect { ... }.to raise_error
    expect { ... }.to raise_error(ErrorClass)
    expect { ... }.to raise_error("message")
    expect { ... }.to raise_error(ErrorClass, "message")

## Expecting throws

    expect { ... }.to throw_symbol
    expect { ... }.to throw_symbol(:symbol)
    expect { ... }.to throw_symbol(:symbol, 'value')

## Predicate matchers

    expect(actual).to be_xxx         # passes if actual.xxx?
    expect(actual).to have_xxx(:arg) # passes if actual.has_xxx?(:arg)

### Examples

    expect([]).to      be_empty
    expect(:a => 1).to have_key(:a)

## Collection membership

    expect(actual).to include(expected)
    expect(array).to match_array(expected_array)
    # ...which is the same as:
    expect(array).to contain_exactly(individual, elements)

### Examples

    expect([1, 2, 3]).to     include(1)
    expect([1, 2, 3]).to     include(1, 2)
    expect(:a => 'b').to     include(:a => 'b')
    expect("this string").to include("is str")
    expect([1, 2, 3]).to     contain_exactly(2, 1, 3)
    expect([1, 2, 3]).to     match_array([3, 2, 1])

## Ranges (1.9+ only)

    expect(1..10).to cover(3)

## Change observation

    expect { object.action }.to change(object, :value).from(old).to(new)
    expect { object.action }.to change(object, :value).by(delta)
    expect { object.action }.to change(object, :value).by_at_least(minimum_delta)
    expect { object.action }.to change(object, :value).by_at_most(maximum_delta)

### Examples

    expect { a += 1 }.to change { a }.by(1)
    expect { a += 3 }.to change { a }.from(2)
    expect { a += 3 }.to change { a }.by_at_least(2)

## Satisfy

    expect(actual).to satisfy { |value| value == expected }

## Output capture

    expect { actual }.to output("some output").to_stdout
    expect { actual }.to output("some error").to_stderr

## Block expectation

    expect { |b| object.action(&b) }.to yield_control
    expect { |b| object.action(&b) }.to yield_with_no_args           # only matches no args
    expect { |b| object.action(&b) }.to yield_with_args              # matches any args
    expect { |b| object.action(&b) }.to yield_successive_args(*args) # matches args against multiple yields

### Examples

    expect { |b| User.transaction(&b) }.to yield_control
    expect { |b| User.transaction(&b) }.to yield_with_no_args
    expect { |b| 5.tap(&b)            }.not_to yield_with_no_args         # because it yields with `5`
    expect { |b| 5.tap(&b)            }.to yield_with_args(5)             # because 5 == 5
    expect { |b| 5.tap(&b)            }.to yield_with_args(Integer)       # because Integer === 5
    expect { |b| [1, 2, 3].each(&b)   }.to yield_successive_args(1, 2, 3)
