require 'spec_helper'
require 'rspec/support/fuzzy_matcher'

module RSpec
  module Support
    RSpec.describe FuzzyMatcher, ".values_match?" do
      matcher :match_against do |actual|
        match { |expected| FuzzyMatcher.values_match?(expected, actual) }
      end

      it 'returns true when given equal values' do
        expect(1).to match_against(1.0)
      end

      it 'returns false when given unequal values that do not provide match logic' do
        expect(1).not_to match_against(1.1)
      end

      it 'can match a regex against a string' do
        expect(/foo/).to match_against("foobar")
        expect(/foo/).not_to match_against("fobar")
      end

      it 'can match a regex against itself' do
        expect(/foo/).to match_against(/foo/)
        expect(/foo/).not_to match_against(/bar/)
      end

      it 'can match a class against an instance' do
        expect(String).to match_against("foo")
        expect(String).not_to match_against(123)
      end

      it 'can match a class against itself' do
        expect(String).to match_against(String)
        expect(String).not_to match_against(Regexp)
      end

      it 'can match against a matcher' do
        expect(be_within(0.1).of(2)).to match_against(2.05)
        expect(be_within(0.1).of(2)).not_to match_against(2.15)
      end

      it 'does not ask the second argument if it fuzzy matches (===)' do
        expect("foo").not_to match_against(String)
      end

      context "when given two 0-arg lambdas" do
        it 'returns true when given the same lambda' do
          k = lambda { 3 }
          expect(k).to match_against(k)
        end

        it 'returns false when given different lambdas' do
          expect(lambda { 3 }).not_to match_against(lambda { 4 })
        end
      end

      context "when given an object whose implementation of `==` wrongly assumes it will only be called with objects of the same type" do
        Color = Struct.new(:r, :g, :b) do
          def ==(other)
            other.r == r && other.g == g && other.b == b
          end
        end

        before(:context) do
          expect { Color.new(0, 0, 0) == Object.new }.to raise_error(NoMethodError, /undefined method `r'/)
        end

        it 'can match against an expected value that matches anything' do
          anything = Object.new.tap do |o|
            def o.===(*); true; end
          end

          expect(anything).to match_against(Color.new(0, 0, 0))
        end

        it 'surfaces the `NoMethodError` when used as the expected value' do
          expect {
            FuzzyMatcher.values_match?(Color.new(0, 0, 0), Object.new)
          }.to raise_error(NoMethodError, /undefined method `r'/)
        end

        it 'can match against objects of the same type' do
          expect(Color.new(0, 0, 0)).to match_against(Color.new(0, 0, 0))
          expect(Color.new(0, 0, 0)).not_to match_against(Color.new(0, 1, 0))
        end
      end

      context "when given an object whose implementation of `==` raises an ArgumentError" do
        it 'surfaces the error' do
          klass = Class.new do
            attr_accessor :foo
            def ==(other)
              other.foo == foo
            end
          end
          instance = klass.new

          other = Object.new
          def other.foo(arg); end

          expect { instance == other }.to raise_error(ArgumentError)
          expect { FuzzyMatcher.values_match?(instance, other) }.to raise_error(ArgumentError)
        end
      end

      it "does not match a struct against an array" do
        struct = Struct.new(:foo, :bar).new("first", 2)
        expect(["first", 2]).not_to match_against(struct)
      end

      context "when given two arrays" do
        it 'returns true if they have equal values' do
          expect([1, 2.0]).to match_against([1.0, 2])
        end

        it 'returns false when given unequal values that do not provide match logic' do
          expect([1, 2.0]).not_to match_against([1.1, 2])
        end

        it 'does the fuzzy matching on the individual elements' do
          expect([String, Integer]).to match_against(["a", 2])
          expect([String, Integer]).not_to match_against([2, "a"])
        end

        it 'returns false if they have a different number of elements' do
          expect([String, Integer]).not_to match_against(['a', 2, nil])
        end

        it 'supports arbitrary nested arrays' do
          a1 = [
            [String, Integer, [be_within(0.1).of(2)]],
            3, [[[ /foo/ ]]]
          ]

          a2 = [
            ["a", 1, [2.05]],
            3, [[[ "foobar" ]]]
          ]

          expect(a1).to match_against(a2)
          a2[0][2][0] += 1
          expect(a1).not_to match_against(a2)
        end
      end

      it 'can match an array an arbitrary enumerable' do
        my_enum = Class.new do
          include Enumerable

          def each
            yield 1; yield "foo"
          end
        end.new

        expect([Integer, String]).to match_against(my_enum)
        expect([String, Integer]).not_to match_against(my_enum)
      end

      it 'does not match an empty hash against an empty array or vice-versa' do
        expect({}).not_to match_against([])
        expect([]).not_to match_against({})
      end

      context 'when given two hashes' do
        it 'returns true when their keys and values are equal' do
          expect(:a => 5, :b => 2.0).to match_against(:a => 5.0, :b => 2)
        end

        it 'returns false when given unequal values that do not provide match logic' do
          expect(:a => 5).not_to match_against(:a => 5.1)
        end

        it 'does the fuzzy matching on the individual values' do
          expect(:a => String, :b => /bar/).to match_against(:a => "foo", :b => "barn")
          expect(:a => String, :b => /bar/).not_to match_against(:a => "foo", :b => "brn")
        end

        it 'returns false if the expected hash has nil values that are not in the actual hash' do
          expect(:a => 'b', :b => nil).not_to match_against(:a => "b")
        end

        it 'returns false if actual hash has extra entries' do
          expect(:a => 'b').not_to match_against(:a => "b", :b => nil)
        end

        it 'does not fuzzy match on keys' do
          expect(/foo/ => 1).not_to match_against("foo" => 1)
        end

        it 'supports arbitrary nested hashes' do
          h1 = {
            :a => {
              :b => [String, Integer],
              :c => { :d => be_within(0.1).of(2) }
            }
          }

          h2 = {
            :a => {
              :b => ["foo", 5],
              :c => { :d => 2.05 }
            }
          }

          expect(h1).to match_against(h2)
          h2[:a][:c][:d] += 1
          expect(h1).not_to match_against(h2)
        end
      end
    end
  end
end

