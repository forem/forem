module RSpec
  module Matchers
    RSpec.describe "equal" do
      it_behaves_like "an RSpec value matcher", :valid_value => :a, :invalid_value => :b do
        let(:matcher) { equal(:a) }
      end

      def inspect_object(o)
        "#<#{o.class}:#{o.object_id}> => #{o.inspect}"
      end

      it "matches when actual.equal?(expected)" do
        expect(1).to equal(1)
      end

      it "does not match when !actual.equal?(expected)" do
        expect("1").not_to equal("1".dup)
      end

      it "describes itself" do
        matcher = equal(1)
        matcher.matches?(1)
        expect(matcher.description).to eq "equal 1"
      end

      context "when the expected object is falsey in conditinal semantics" do
        it "describes itself with the expected object" do
          matcher = equal(nil)
          matcher.matches?(nil)
          expect(matcher.description).to eq "equal nil"
        end
      end

      context "when the expected object's #equal? always returns true" do
        let(:strange_string) do
          string = "foo".dup

          def string.equal?(_other)
            true
          end

          string
        end

        it "describes itself with the expected object" do
          matcher = equal(strange_string)
          matcher.matches?(strange_string)
          expect(matcher.description).to eq 'equal "foo"'
        end
      end

      context "the output for expected" do
        it "doesn't include extra object detail for `true`" do
          expected, actual = true, "1"
          expect {
            expect(actual).to equal(expected)
          }.to fail_with "\nexpected true\n     got #{inspect_object(actual)}\n"
        end

        it "doesn't include extra object detail for `false`" do
          expected, actual = false, "1"
          expect {
            expect(actual).to equal(expected)
          }.to fail_with "\nexpected false\n     got #{inspect_object(actual)}\n"
        end

        it "doesn't include extra object detail for `nil`" do
          expected, actual = nil, "1"
          expect {
            expect(actual).to equal(expected)
          }.to fail_with "\nexpected nil\n     got #{inspect_object(actual)}\n"
        end
      end

      context "the output for actual" do
        it "doesn't include extra object detail for `true`" do
          expected, actual = true, false
          expect {
            expect(actual).to equal(expected)
          }.to fail_with "\nexpected true\n     got false\n"
        end

        it "doesn't include extra object detail for `false`" do
          expected, actual = false, nil
          expect {
            expect(actual).to equal(expected)
          }.to fail_with "\nexpected false\n     got nil\n"
        end

        it "doesn't include extra object detail for `nil`" do
          expected, actual = nil, false
          expect {
            expect(actual).to equal(expected)
          }.to fail_with "\nexpected nil\n     got false\n"
        end
      end

      it "suggests the `eq` matcher on failure" do
        expected, actual = "1", "1".dup
        expect {
          expect(actual).to equal(expected)
        }.to fail_with <<-MESSAGE

expected #{inspect_object(expected)}
     got #{inspect_object(actual)}

Compared using equal?, which compares object identity,
but expected and actual are not the same object. Use
`expect(actual).to eq(expected)` if you don't care about
object identity in this example.

MESSAGE
      end

      it "provides message on #negative_failure_message" do
        expected = actual = "1"
        matcher = equal(expected)
        matcher.matches?(actual)
        expect(matcher.failure_message_when_negated).to eq <<-MESSAGE

expected not #{inspect_object(expected)}
         got #{inspect_object(actual)}

Compared using equal?, which compares object identity.

MESSAGE
      end
    end
  end
end
