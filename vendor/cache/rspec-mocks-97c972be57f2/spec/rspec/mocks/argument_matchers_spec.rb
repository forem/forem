module RSpec
  module Mocks
    RSpec.describe "argument matchers matching" do
      let(:a_double) { double }

      after(:each, :reset => true) do
        reset a_double
      end

      describe "boolean" do
        it "accepts true as boolean" do
          expect(a_double).to receive(:random_call).with(boolean)
          a_double.random_call(true)
        end

        it "accepts false as boolean" do
          expect(a_double).to receive(:random_call).with(boolean)
          a_double.random_call(false)
        end

        it "rejects non boolean", :reset => true do
          expect(a_double).to receive(:random_call).with(boolean)
          expect {
            a_double.random_call("false")
          }.to fail_including "expected: (boolean)"
        end
      end

      describe "kind_of" do
        it "accepts fixnum as kind_of(Numeric)" do
          expect(a_double).to receive(:random_call).with(kind_of(Numeric))
          a_double.random_call(1)
        end

        it "accepts float as kind_of(Numeric)" do
          expect(a_double).to receive(:random_call).with(kind_of(Numeric))
          a_double.random_call(1.5)
        end

        it "handles non matching kinds nicely", :reset => true do
          expect(a_double).to receive(:random_call).with(kind_of(Numeric))
          expect {
            a_double.random_call(true)
          }.to fail_including "expected: (kind of Numeric)"
        end

        it "matches arguments that have defined `kind_of?` to return true" do
          fix_num = double(:kind_of? => true)
          expect(a_double).to receive(:random_call).with(kind_of(Numeric))
          a_double.random_call(fix_num)
        end

        it "handles a class thats overridden ===" do
          allow(Numeric).to receive(:===) { false }
          fix_num = double(:kind_of? => true)
          expect(a_double).to receive(:random_call).with(kind_of(Numeric))
          a_double.random_call(fix_num)
        end
      end

      describe "instance_of" do
        it "accepts float as instance_of(Float)" do
          expect(a_double).to receive(:random_call).with(instance_of(Float))
          a_double.random_call(1.1)
        end

        it "does NOT accept float as instance_of(Numeric)" do
          expect(a_double).not_to receive(:random_call).with(instance_of(Numeric))
          a_double.random_call(1.1)
        end

        it "does NOT accept integer as instance_of(Numeric)" do
          expect(a_double).not_to receive(:random_call).with(instance_of(Numeric))
          a_double.random_call(1)
        end

        it "rejects non numeric", :reset => true do
          expect(a_double).to receive(:random_call).with(an_instance_of(Numeric))
          expect { a_double.random_call("1") }.to fail
        end

        it "rejects non string", :reset => true do
          expect(a_double).to receive(:random_call).with(an_instance_of(String))
          expect { a_double.random_call(123) }.to fail
        end

        it "handles non matching instances nicely", :reset => true do
          expect(a_double).to receive(:random_call).with(instance_of(Numeric))
          expect {
            a_double.random_call(1.5)
          }.to fail_including "expected: (an_instance_of(Numeric))"
        end
      end

      describe "anything" do
        it "accepts string as anything" do
          expect(a_double).to receive(:random_call).with("a", anything, "c")
          a_double.random_call("a", "whatever", "c")
        end

        it "doesn't accept no arguments" do
          expect(a_double).to_not receive(:random_call).with(anything)
          a_double.random_call
        end

        it "handles non matching instances nicely", :reset => true do
          expect(a_double).to receive(:random_call).with(anything)
          expect { a_double.random_call }.to fail_including "expected: (anything)"
        end
      end

      describe "duck_type" do
        it "matches duck type with one method" do
          expect(a_double).to receive(:random_call).with(duck_type(:length))
          a_double.random_call([])
        end

        it "matches duck type with two methods" do
          expect(a_double).to receive(:random_call).with(duck_type(:abs, :div))
          a_double.random_call(1)
        end

        it "rejects goose when expecting a duck", :reset => true do
          expect(a_double).to receive(:random_call).with(duck_type(:abs, :div))
          expect {
            a_double.random_call("I don't respond to :abs or :div")
          }.to fail_including "expected: (duck_type(:abs, :div))"
        end
      end

      describe "any_args" do
        context "as the only arg passed to `with`" do
          before { expect(a_double).to receive(:random_call).with(any_args) }

          it "matches no args" do
            a_double.random_call
          end

          it "matches one arg" do
            a_double.random_call("a string")
          end

          it "matches many args" do
            a_double.random_call("a string", :other, 3)
          end
        end

        context "as the last of three args" do
          before { expect(a_double).to receive(:random_call).with(1, /foo/, any_args) }

          it "matches a call of two args when it matches the first two explicit args" do
            a_double.random_call(1, "food")
          end

          it "matches a call of three args when it matches the first two explicit args" do
            a_double.random_call(1, "food", :more)
          end

          it "matches a call of four args when it matches the first two explicit args" do
            a_double.random_call(1, "food", :more, :args)
          end

          it "does not match a call where the first two args do not match", :reset => true do
            expect { a_double.random_call(1, "bar", 2, 3) }.to fail_including "expected: (1, /foo/, *(any args))"
          end

          it "does not match a call of no args", :reset => true do
            expect { a_double.random_call }.to fail_including "expected: (1, /foo/, *(any args))"
          end
        end

        context "as the first of three args" do
          before { expect(a_double).to receive(:random_call).with(any_args, 1, /foo/) }

          it "matches a call of two args when it matches the last two explicit args" do
            a_double.random_call(1, "food")
          end

          it "matches a call of three args when it matches the last two explicit args" do
            a_double.random_call(nil, 1, "food")
          end

          it "matches a call of four args when it matches the last two explicit args" do
            a_double.random_call(:some, :args, 1, "food")
          end

          it "does not match a call where the last two args do not match", :reset => true do
            expect { a_double.random_call(1, "bar", 2, 3) }.to fail_including "expected: (*(any args), 1, /foo/)"
          end

          it "does not match a call of no args", :reset => true do
            expect { a_double.random_call }.to fail_including "expected: (*(any args), 1, /foo/)"
          end
        end

        context "as the middle of three args" do
          before { expect(a_double).to receive(:random_call).with(1, any_args, /foo/) }

          it "matches a call of two args when it matches the first and last args" do
            a_double.random_call(1, "food")
          end

          it "matches a call of three args when it matches the first and last args" do
            a_double.random_call(1, nil, "food")
          end

          it "matches a call of four args when it matches the first and last args" do
            a_double.random_call(1, :some, :args, "food")
          end

          it "does not match a call where the first and last args do not match", :reset => true do
            expect { a_double.random_call(nil, "bar", 2, 3) }.to fail_including "expected: (1, *(any args), /foo/)"
          end

          it "does not match a call of no args", :reset => true do
            expect { a_double.random_call }.to fail_including "expected: (1, *(any args), /foo/)"
          end
        end

        context "when passed twice" do
          it 'immediately signals that this is invalid', :reset => true do
            expect {
              expect(a_double).to receive(:random_call).with(any_args, 1, any_args)
            }.to raise_error(ArgumentError, /any_args/)
          end
        end
      end

      describe "no_args" do
        it "matches no args against no_args" do
          expect(a_double).to receive(:random_call).with(no_args)
          a_double.random_call
        end

        it "fails no_args with one arg", :reset => true do
          expect(a_double).to receive(:msg).with(no_args)
          expect { a_double.msg(37) }.to fail_including "expected: (no args)"
        end

        context "when passed with other arguments" do
          it 'immediately signals that this is invalid', :reset => true do
            expect {
              expect(a_double).to receive(:random_call).with(no_args, 3)
            }.to raise_error(ArgumentError, /no_args/)
          end
        end
      end

      describe "hash_including" do
        it "matches hash with hash_including same hash" do
          expect(a_double).to receive(:random_call).with(hash_including(:a => 1))
          a_double.random_call(:a => 1)
        end

        it "fails hash_including with missing key", :reset => true do
          expect(a_double).to receive(:random_call).with(hash_including(:a => 1))
          expect {
            a_double.random_call(:a => 2)
          }.to fail_including "expected: (hash_including(:a=>1))"
        end
      end

      describe "hash_excluding" do
        it "matches hash with hash_excluding same hash" do
          expect(a_double).to receive(:random_call).with(hash_excluding(:a => 1))
          a_double.random_call(:a => 2)
        end

        it "handles non matching instances nicely", :reset => true do
          expect(a_double).to receive(:random_call).with(hash_excluding(:a => 1))
          expect {
            a_double.random_call(:a => 1)
          }.to fail_including "expected: (hash_not_including(:a=>1))"
        end
      end

      describe "array_including" do
        it "matches array with array_including same array" do
          expect(a_double).to receive(:random_call).with(array_including(1, 2))
          a_double.random_call([1, 2])
        end

        it "fails array_including when args aren't array", :reset => true do
          expect(a_double).to receive(:msg).with(array_including(1, 2, 3))
          expect {
            a_double.msg(1, 2, 3)
          }.to fail_including "expected: (array_including(1, 2, 3))"
        end

        it "fails array_including when arg doesn't contain all elements", :reset => true do
          expect(a_double).to receive(:msg).with(array_including(1, 2, 3))
          expect {
            a_double.msg([1, 2])
          }.to fail_including "expected: (array_including(1, 2, 3))"
        end
      end

      context "handling arbitary matchers" do
        it "matches any arbitrary object using #===" do
          matcher = double
          expect(matcher).to receive(:===).with(4).and_return(true)

          expect(a_double).to receive(:foo).with(matcher)
          a_double.foo(4)
        end

        it "matches against a Matcher", :reset => true do
          expect(a_double).to receive(:msg).with(equal(3))
          # This spec is generating warnings on 1.8.7, not sure why so
          # this does with_isolated_stderr to kill them. @samphippen 3rd Jan 2013.
          expect { with_isolated_stderr { a_double.msg(37) } }.to fail_including "expected: (equal 3)"
        end

        it "fails when given an arbitrary object that returns false from #===", :reset => true do
          matcher = double
          expect(matcher).to receive(:===).with(4).at_least(:once).and_return(false)

          expect(a_double).to receive(:foo).with(matcher)

          expect { a_double.foo(4) }.to fail
        end
      end

      context "handling objects with a wrong definition of `==` that raises errors for other types" do
        Color = Struct.new(:r, :g, :b) do
          def ==(other)
            other.r == r && other.g == g && other.b == b
          end
        end

        before(:context) do
          expect { Color.new(0, 0, 0) == Object.new }.to raise_error(NoMethodError)
        end

        it 'matches against an equal instance of the same type' do
          expect(a_double).to receive(:random_call).with(Color.new(0, 0, 0))
          a_double.random_call(Color.new(0, 0, 0))
        end

        it 'fails when matched against an unequal instance of the same class', :reset do
          expect(a_double).to receive(:random_call).with(Color.new(0, 0, 0))
          expect { a_double.random_call(Color.new(0, 1, 0)) }.to fail
        end

        it 'can match multiple instances of the type against multiple equal instances of the type' do
          expect(a_double).to receive(:random_call).with(
            Color.new(0, 0, 0),
            Color.new(0, 1, 0)
          )

          a_double.random_call(
            Color.new(0, 0, 0),
            Color.new(0, 1, 0)
          )
        end
      end

      context "handling non-matcher arguments" do
        it "matches string against regexp" do
          expect(a_double).to receive(:random_call).with(/bcd/)
          a_double.random_call("abcde")
        end

        it "matches regexp against regexp" do
          expect(a_double).to receive(:random_call).with(/bcd/)
          a_double.random_call(/bcd/)
        end

        it "fails if regexp does not match submitted string", :reset => true do
          expect(a_double).to receive(:random_call).with(/bcd/)
          expect { a_double.random_call("abc") }.to fail
        end

        it "fails if regexp does not match submitted regexp", :reset => true do
          expect(a_double).to receive(:random_call).with(/bcd/)
          expect { a_double.random_call(/bcde/) }.to fail
        end

        it "matches against a hash submitted and received by value" do
          expect(a_double).to receive(:random_call).with(:a => "a", :b => "b")
          a_double.random_call(:a => "a", :b => "b")
        end

        it "matches against a hash submitted as keyword arguments a and received as a positional argument (in both Ruby 2 and Ruby 3)" do
          opts = {:a => "a", :b => "b"}
          expect(a_double).to receive(:random_call).with(opts)
          a_double.random_call(:a => "a", :b => "b")
        end

        if RUBY_VERSION >= "3"
          it "fails to matches against a hash submitted as a positional argument and received as keyword arguments in Ruby 3.0 or later", :reset => true do
            opts = {:a => "a", :b => "b"}
            expect(a_double).to receive(:random_call).with(:a => "a", :b => "b")
            expect do
              a_double.random_call(opts)
            end.to fail_with(/expected: \(\{(:a=>\"a\", :b=>\"b\"|:b=>\"b\", :a=>\"a\")\}\)/)
          end
        else
          it "matches against a hash submitted as a positional argument and received as keyword arguments in Ruby 2.7 or before" do
            opts = {:a => "a", :b => "b"}
            expect(a_double).to receive(:random_call).with(:a => "a", :b => "b")
            a_double.random_call(opts)
          end
        end

        it "fails for a hash w/ wrong values", :reset => true do
          expect(a_double).to receive(:random_call).with(:a => "b", :c => "d")
          expect do
            a_double.random_call(:a => "b", :c => "e")
          end.to fail_with(/expected: \(\{(:a=>\"b\", :c=>\"d\"|:c=>\"d\", :a=>\"b\")\}\)/)
        end

        it "fails for a hash w/ wrong keys", :reset => true do
          expect(a_double).to receive(:random_call).with(:a => "b", :c => "d")
          expect do
            a_double.random_call("a" => "b", "c" => "d")
          end.to fail_with(/expected: \(\{(:a=>\"b\", :c=>\"d\"|:c=>\"d\", :a=>\"b\")\}\)/)
        end

        it "matches a class against itself" do
          expect(a_double).to receive(:foo).with(Float)
          a_double.foo(Float)
        end

        it "fails a class against an unrelated class", :reset => true do
          expect(a_double).to receive(:foo).with(Float)
          expect { a_double.foo(Hash) }.to fail
        end

        it "matches a class against an instance of itself" do
          expect(a_double).to receive(:foo).with(Float)
          a_double.foo(3.3)
        end

        it "fails a class against an object of a different type", :reset => true do
          expect(a_double).to receive(:foo).with(Float)
          expect { a_double.foo(3) }.to fail
        end

        it "fails with zero arguments", :reset => true do
          expect do
            expect(a_double).to receive(:msg).with { |arg| expect(arg).to eq :received }
          end.to raise_error(ArgumentError, /must have at least one argument/)
        end

        it "fails with sensible message when args respond to #description", :reset => true do
          arg = double(:description => nil, :inspect => "my_thing")

          expect(a_double).to receive(:msg).with(3)
          expect { a_double.msg arg }.to fail_including "got: (my_thing)"
        end

        it "fails with sensible message when arg#description is nil", :reset => true do
          arg = double(:description => nil, :inspect => "my_thing")

          expect(a_double).to receive(:msg).with(arg)
          expect { a_double.msg 3 }.to fail_including "expected: (my_thing)"
        end

        it "fails with sensible message when arg#description is blank", :reset => true do
          arg = double(:description => "", :inspect => "my_thing")

          expect(a_double).to receive(:msg).with(arg)
          expect { a_double.msg 3 }.to fail_including "expected: (my_thing)"
        end
      end
    end
  end
end
