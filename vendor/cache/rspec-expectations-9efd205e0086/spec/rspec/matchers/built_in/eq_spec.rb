module RSpec
  module Matchers
    RSpec.describe "eq" do
      it_behaves_like "an RSpec value matcher", :valid_value => 1, :invalid_value => 2 do
        let(:matcher) { eq(1) }
      end

      it "is diffable" do
        expect(eq(1)).to be_diffable
      end

      it "matches when actual == expected" do
        expect(1).to eq(1)
      end

      it "does not match when actual != expected" do
        expect(1).not_to eq(2)
      end

      it "compares by sending == to actual (not expected)" do
        called = false
        actual = Class.new do
          define_method :== do |_other|
            called = true
          end
        end.new

        expect(actual).to eq :anything # to trigger the matches? method
        expect(called).to be_truthy
      end

      it "describes itself" do
        matcher = eq(1)
        matcher.matches?(1)
        expect(matcher.description).to eq "eq 1"
      end

      it "provides message, expected and actual on #failure_message" do
        matcher = eq("1")
        matcher.matches?(1)
        expect(matcher.failure_message).to eq "\nexpected: \"1\"\n     got: 1\n\n(compared using ==)\n"
      end

      it "provides message, expected and actual on #negative_failure_message" do
        matcher = eq(1)
        matcher.matches?(1)
        expect(matcher.failure_message_when_negated).to eq "\nexpected: value != 1\n     got: 1\n\n(compared using ==)\n"
      end

      context "with Time objects" do
        RSpec::Matchers.define :a_string_with_differing_output do
          match do |string|
            time_strings = /expected: (.+)\n.*got: (.+)$/.match(string).captures
            time_strings.uniq.count == 2
          end
        end

        let(:time1) { Time.utc(1969, 12, 31, 19, 10, 40, 101) }
        let(:time2) { Time.utc(1969, 12, 31, 19, 10, 40, 102) }

        it "provides additional precision on #failure_message" do
          expect {
            expect(time1).to eq(time2)
          }.to fail_with(a_string_with_differing_output)
        end

        it "provides additional precision on #negative_failure_message" do
          expect {
            expect(time1).to_not eq(time1)
          }.to fail_with(a_string_with_differing_output)
        end
      end

      it 'fails properly when the actual is an array of multiline strings' do
        expect {
          expect(["a\nb", "c\nd"]).to eq([])
        }.to fail_including("expected: []")
      end

      describe '#description' do
        # Ruby 1.8.7 produces a less precise output
        expected_seconds = Time.method_defined?(:nsec) ? '000000000' : '000000'

        [
            [nil, 'eq nil'],
            [true, 'eq true'],
            [false, 'eq false'],
            [:symbol, 'eq :symbol'],
            [1, 'eq 1'],
            [1.2, 'eq 1.2'],
            ['foo', 'eq "foo"'],
            [/regex/, 'eq /regex/'],
            [['foo'], 'eq ["foo"]'],
            [{ :foo => :bar }, 'eq {:foo=>:bar}'],
            [Class, 'eq Class'],
            [RSpec, 'eq RSpec'],
            [Time.utc(2014, 1, 1), "eq 2014-01-01 00:00:00.#{expected_seconds} +0000"],
        ].each do |expected, expected_description|
          context "with #{expected.inspect}" do
            around { |ex| with_env_vars('TZ' => 'UTC', &ex) } if expected.is_a?(Time)

            it "is \"#{expected_description}\"" do
              expect(eq(expected).description).to eq expected_description
            end
          end
        end

        context "with Date.new(2014, 1, 1)" do
          it "is eq to Date.new(2014, 1, 1).inspect" do
            in_sub_process_if_possible do
              require 'date'
              date = Date.new(2014, 1, 1)
              expect(eq(date).description).to eq "eq #{date.inspect}"
            end
          end
        end

        context "with Complex(1, 2)" do
          it "is eq to Complex(1, 2).inspect" do
            in_sub_process_if_possible do
              # complex is available w/o requiring on ruby 1.9+.
              # Loading it on 1.9+ issues a warning, so we only load it on 1.8.7.
              require 'complex' if RUBY_VERSION == '1.8.7'

              complex = Complex(1, 2)
              expect(eq(complex).description).to eq "eq #{complex.inspect}"
            end
          end
        end

        context 'with object' do
          it 'matches with "^eq #<Object:0x[0-9a-f]*>$"' do
            expect(eq(Object.new).description).to match(/^eq #<Object:0x[0-9a-f]*>$/)
          end
        end
      end
    end
  end
end
