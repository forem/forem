RSpec.describe 'a matcher is expected to be able to have its description generated' do
  after(:example) do
    RSpec::Matchers.clear_generated_description
  end

  example "expect(...).to eq expected" do
    expect("this").to eq "this"
    expect(RSpec::Matchers.generated_description).to eq "is expected to eq \"this\""
  end

  example "expect(...).to not eq expected" do
    expect("this").not_to eq "that"
    expect(RSpec::Matchers.generated_description).to eq "is expected not to eq \"that\""
  end

  example "expect(...).to be empty (arbitrary predicate)" do
    expect([]).to be_empty
    expect(RSpec::Matchers.generated_description).to eq "is expected to be empty"
  end

  example "expect(...).to not be empty (arbitrary predicate)" do
    expect([1]).not_to be_empty
    expect(RSpec::Matchers.generated_description).to eq "is expected not to be empty"
  end

  example "expect(...).to be truthy" do
    expect(true).to be_truthy
    expect(RSpec::Matchers.generated_description).to eq "is expected to be truthy"
  end

  example "expect(...).to be falsey" do
    expect(false).to be_falsey
    expect(RSpec::Matchers.generated_description).to eq "is expected to be falsey"
  end

  example "expect(...).to be nil" do
    expect(nil).to be_nil
    expect(RSpec::Matchers.generated_description).to eq "is expected to be nil"
  end

  example "expect(...).to be > n" do
    expect(5).to be > 3
    expect(RSpec::Matchers.generated_description).to eq "is expected to be > 3"
  end

  example "expect(...).to be between min and max" do
    expect(10).to be_between(0, 10)
    expect(RSpec::Matchers.generated_description).to eq "is expected to be between 0 and 10 (inclusive)"
  end

  example "expect(...).to be exclusively between min and max" do
    expect(9).to be_between(0, 10).exclusive
    expect(RSpec::Matchers.generated_description).to eq "is expected to be between 0 and 10 (exclusive)"
  end

  example "expect(...).to be predicate arg1, arg2 and arg3" do
    class Parent; end
    class Child < Parent
      def child_of?(*parents)
        parents.all? { |parent| is_a?(parent) }
      end
    end
    expect(Child.new).to be_a_child_of(Parent, Object)
    expect(RSpec::Matchers.generated_description).to eq "is expected to be a child of Parent and Object"
  end

  example "expect(...).to equal" do
    expected = "expected"
    expect(expected).to equal(expected)
    expect(RSpec::Matchers.generated_description).to eq "is expected to equal \"expected\""
  end

  example "expect(...).not_to equal" do
    expect(5).not_to equal(37)
    expect(RSpec::Matchers.generated_description).to eq "is expected not to equal 37"
  end

  example "expect(...).to eql" do
    expect("string").to eql("string")
    expect(RSpec::Matchers.generated_description).to eq "is expected to eql \"string\""
  end

  example "expect(...).not_to eql" do
    expect("a").not_to eql(:a)
    expect(RSpec::Matchers.generated_description).to eq "is expected not to eql :a"
  end

  example "expect(...).to have_key" do
    expect({ :a => "a" }).to have_key(:a)
    expect(RSpec::Matchers.generated_description).to eq "is expected to have key :a"
  end

  example "expect(...).to have_some_method" do
    object = Object.new
    def object.has_eyes_closed?; true; end

    expect(object).to have_eyes_closed
    expect(RSpec::Matchers.generated_description).to eq 'is expected to have eyes closed'
  end

  example "expect(...).to have_some_method(args*)" do
    object = Object.new
    def object.has_taste_for?(*_args); true; end

    expect(object).to have_taste_for("wine", "cheese")
    expect(RSpec::Matchers.generated_description).to eq 'is expected to have taste for "wine" and "cheese"'
  end

  example "expect(...).to include(x)" do
    expect([1, 2, 3]).to include(3)
    expect(RSpec::Matchers.generated_description).to eq "is expected to include 3"
  end

  example "expect(...).to include(x) when x responds to description but is not a matcher" do
    obj = double(:description => "description", :inspect => "inspect")
    expect([obj]).to include(obj)
    expect(RSpec::Matchers.generated_description).to eq "is expected to include inspect"
  end

  example "expect(...).to include(x) when x responds to description and is a matcher" do
    matcher = double(:description                => "description",
                     :matches?                   => true,
                     :failure_message => "")
    expect([matcher]).to include(matcher)
    expect(RSpec::Matchers.generated_description).to eq "is expected to include (description)"
  end

  example "expect(array).to contain_exactly(1, 2, 3)" do
    expect([1, 2, 3]).to contain_exactly(1, 2, 3)
    expect(RSpec::Matchers.generated_description).to eq "is expected to contain exactly 1, 2, and 3"
  end

  example "expect(...).to match" do
    expect("this string").to match(/this string/)
    expect(RSpec::Matchers.generated_description).to eq "is expected to match /this string/"
  end

  example "expect(...).to raise_error" do
    expect { raise 'foo' }.to raise_error Exception
    expect(RSpec::Matchers.generated_description).to eq "is expected to raise Exception"
  end

  example "expect(...).to raise_error with class" do
    expect { raise }.to raise_error(RuntimeError)
    expect(RSpec::Matchers.generated_description).to eq "is expected to raise RuntimeError"
  end

  example "expect(...).to raise_error with class and message" do
    expect { raise "there was an error" }.to raise_error(RuntimeError, "there was an error")
    expect(RSpec::Matchers.generated_description).to eq "is expected to raise RuntimeError with \"there was an error\""
  end

  example "expect(...).to respond_to" do
    expect([]).to respond_to(:insert)
    expect(RSpec::Matchers.generated_description).to eq "is expected to respond to #insert"
  end

  example "expect(...).to throw symbol" do
    expect { throw :what_a_mess }.to throw_symbol
    expect(RSpec::Matchers.generated_description).to eq "is expected to throw a Symbol"
  end

  example "expect(...).to throw symbol (with named symbol)" do
    expect { throw :what_a_mess }.to throw_symbol(:what_a_mess)
    expect(RSpec::Matchers.generated_description).to eq "is expected to throw :what_a_mess"
  end

  example "expect(...).to matcher_that_delegates_to_an_internal_expectation" do
    expect(1).to matcher_that_delegates_to_an_internal_expectation
    expect(RSpec::Matchers.generated_description).to eq "is expected to matcher that delegates to an internal expectation"
  end

  example "expect(...).not_to matcher_that_delegates_to_an_internal_expectation" do
    expect(1).not_to matcher_that_delegates_to_an_internal_expectation
    expect(RSpec::Matchers.generated_description).to eq "is expected not to matcher that delegates to an internal expectation"
  end

  RSpec::Matchers.define :matcher_that_delegates_to_an_internal_expectation do
    match { expect(1).to eq(1) }
    match_when_negated { expect(1).to eq(1) }
  end
end

RSpec.describe "a Matcher with no description" do
  it "provides a helpful message when used in a string-less example block" do
    matcher = Class.new do
      def matches?(_ignore); true; end
      def failure_message; ""; end
    end.new

    expect(5).to matcher
    expect(RSpec::Matchers.generated_description).to match(/When you call.*description method/m)
  end
end
