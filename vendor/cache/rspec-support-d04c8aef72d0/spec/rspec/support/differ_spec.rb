# encoding: utf-8
require 'spec_helper'
require 'ostruct'
require 'timeout'
require 'rspec/support/spec/string_matcher'

module RSpec
  module Support
    RSpec.describe Differ do
      include Spec::DiffHelpers

      describe '#diff' do
        let(:differ) { RSpec::Support::Differ.new }

        it "outputs unified diff of two strings" do
          expected = "foo\nzap\nbar\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nanother\nline\n"
          actual   = "foo\nbar\nzap\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nline\n"

          if Diff::LCS::VERSION.to_f < 1.4 || Diff::LCS::VERSION >= "1.4.4"
            expected_diff = dedent(<<-'EOD')
              |
              |
              |@@ -1,6 +1,6 @@
              | foo
              |-zap
              | bar
              |+zap
              | this
              | is
              | soo
              |@@ -9,6 +9,5 @@
              | equal
              | insert
              | a
              |-another
              | line
              |
            EOD
          else
            expected_diff = dedent(<<-'EOD')
              |
              |
              |@@ -1,4 +1,6 @@
              | foo
              |-zap
              | bar
              |+zap
              | this
              |@@ -9,6 +11,7 @@
              | equal
              | insert
              | a
              |-another
              | line
              |
            EOD
          end


          diff = differ.diff(actual, expected)
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "outputs unified diff of two strings when used multiple times" do
          expected = "foo\nzap\nbar\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nanother\nline\n"
          actual   = "foo\nbar\nzap\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nline\n"

          if Diff::LCS::VERSION.to_f < 1.4 || Diff::LCS::VERSION >= "1.4.4"
            expected_diff = dedent(<<-'EOS')
              |
              |
              |@@ -1,6 +1,6 @@
              | foo
              |-zap
              | bar
              |+zap
              | this
              | is
              | soo
              |@@ -9,6 +9,5 @@
              | equal
              | insert
              | a
              |-another
              | line
              |
            EOS
          else
            expected_diff = dedent(<<-'EOS')
              |
              |
              |@@ -1,4 +1,6 @@
              | foo
              |-zap
              | bar
              |+zap
              | this
              |@@ -9,6 +11,7 @@
              | equal
              | insert
              | a
              |-another
              | line
              |
            EOS
          end

          diff = differ.diff(actual, expected)
          expect(diff).to be_diffed_as(expected_diff)
        end

        it 'does not mutate any instance variables when diffing, so we can reason about it being reused' do
          expected = "foo\nzap\nbar\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nanother\nline\n"
          actual   = "foo\nbar\nzap\nthis\nis\nsoo\nvery\nvery\nequal\ninsert\na\nline\n"

          expect { differ.diff(actual, expected) }.not_to change { differ_ivars }
        end

        def differ_ivars
          Hash[ differ.instance_variables.map do |ivar|
            [ivar, differ.instance_variable_get(ivar)]
          end ]
        end

        if String.method_defined?(:encoding)
          it "returns an empty string if strings are not multiline" do
            expected = "Tu avec carte {count} item has".encode('UTF-16LE')
            actual   = "Tu avec carté {count} itém has".encode('UTF-16LE')


            diff = differ.diff(actual, expected)
            expect(diff).to be_empty
          end

          it 'copes with encoded strings', :skip => RSpec::Support::OS.windows? do
            expected = "Tu avec carte {count} item has\n".encode('UTF-16LE')
            actual   = "Tu avec carté {count} itém has\n".encode('UTF-16LE')
            expected_diff = dedent(<<-EOD).encode('UTF-16LE')
              |
              |@@ #{one_line_header} @@
              |-Tu avec carte {count} item has
              |+Tu avec carté {count} itém has
              |
            EOD

            diff = differ.diff(actual, expected)
            expect(diff).to be_diffed_as(expected_diff)
          end

          it 'handles differently encoded strings that are compatible' do
            expected = "abc\n".encode('us-ascii')
            actual   = "강인철\n".encode('UTF-8')
            expected_diff = "\n@@ #{one_line_header} @@\n-abc\n+강인철\n"
            diff = differ.diff(actual, expected)
            expect(diff).to be_diffed_as(expected_diff)
          end

          it 'uses the default external encoding when the two strings have incompatible encodings' do
            expected = "Tu avec carte {count} item has\n"
            actual   = "Tu avec carté {count} itém has\n".encode('UTF-16LE')
            expected_diff = "\n@@ #{one_line_header} @@\n-Tu avec carte {count} item has\n+Tu avec carté {count} itém has\n"

            diff = differ.diff(actual, expected)
            expect(diff).to be_diffed_as(expected_diff)
            expect(diff.encoding).to eq(Encoding.default_external)
          end

          it 'handles any encoding error that occurs with a helpful error message' do
            expect(RSpec::Support::HunkGenerator).to receive(:new).
              and_raise(Encoding::CompatibilityError)
            expected = "Tu avec carte {count} item has\n".encode('us-ascii')
            actual   = "Tu avec carté {count} itém has\n"
            diff = differ.diff(actual, expected)
            expect(diff).to match(/Could not produce a diff/)
            expect(diff).to match(/actual string \(UTF-8\)/)
            expect(diff).to match(/expected string \(US-ASCII\)/)
          end
        end

        it "outputs unified diff message of two objects" do
          animal_class = Class.new do
            include RSpec::Support::FormattingSupport

            def initialize(name, species)
              @name, @species = name, species
            end

            def inspect
              dedent(<<-EOA)
                |<Animal
                |  name=#{@name},
                |  species=#{@species}
                |>
              EOA
            end
          end

          expected = animal_class.new "bob", "giraffe"
          actual   = animal_class.new "bob", "tortoise"

          expected_diff = dedent(<<-'EOD')
            |
            |@@ -1,5 +1,5 @@
            | <Animal
            |   name=bob,
            |-  species=tortoise
            |+  species=giraffe
            | >
            |
          EOD

          diff = differ.diff(expected,actual)
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "outputs unified diff message of two arrays" do
          expected = [ :foo, 'bar', :baz, 'quux', :metasyntactic, 'variable', :delta, 'charlie', :width, 'quite wide' ]
          actual   = [ :foo, 'bar', :baz, 'quux', :metasyntactic, 'variable', :delta, 'tango'  , :width, 'very wide'  ]

          expected_diff = dedent(<<-'EOD')
            |
            |
            |@@ -5,7 +5,7 @@
            |  :metasyntactic,
            |  "variable",
            |  :delta,
            |- "tango",
            |+ "charlie",
            |  :width,
            |- "very wide"]
            |+ "quite wide"]
            |
          EOD

          diff = differ.diff(expected,actual)
          expect(diff).to be_diffed_as(expected_diff)
        end

        it 'outputs a unified diff message for an array which flatten recurses' do
          klass = Class.new do
            def to_ary; [self]; end
            def inspect; "<BrokenObject>"; end
          end
          obj = klass.new

          diff = ''
          Timeout::timeout(1) do
            diff = differ.diff [obj], []
          end

          expected_diff = dedent(<<-EOD)
            |
            |@@ #{one_line_header} @@
            |-[]
            |+[<BrokenObject>]
            |
          EOD
          expect(diff).to be_diffed_as(expected_diff)
        end

        it 'outputs unified diff message of strings in arrays' do
          diff = differ.diff(["a\r\nb"], ["a\r\nc"])
          expected_diff = dedent(<<-EOD)
            |
            |@@ #{one_line_header} @@
            |-a\\r\\nc
            |+a\\r\\nb
            |
          EOD
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "outputs unified diff message of two hashes" do
          expected = { :foo => 'bar', :baz => 'quux', :metasyntactic => 'variable', :delta => 'charlie', :width =>'quite wide' }
          actual   = { :foo => 'bar', :metasyntactic => 'variable', :delta => 'charlotte', :width =>'quite wide' }

          expected_diff = dedent(<<-'EOD')
            |
            |@@ -1,4 +1,5 @@
            |-:delta => "charlotte",
            |+:baz => "quux",
            |+:delta => "charlie",
            | :foo => "bar",
            | :metasyntactic => "variable",
            | :width => "quite wide",
            |
          EOD

          diff = differ.diff(expected,actual)
          expect(diff).to be_diffed_as(expected_diff)
        end

        unless RUBY_VERSION == '1.8.7' # We can't count on the ordering of the hash on 1.8.7...
          it "outputs unified diff message for hashes inside arrays with differing key orders" do
            expected = [{ :foo => 'bar', :baz => 'quux', :metasyntactic => 'variable', :delta => 'charlie', :width =>'quite wide' }]
            actual   = [{ :metasyntactic => 'variable', :delta => 'charlotte', :width =>'quite wide', :foo => 'bar' }]

            expected_diff = dedent(<<-'EOD')
              |
              |@@ -1,4 +1,5 @@
              |-[{:delta=>"charlotte",
              |+[{:baz=>"quux",
              |+  :delta=>"charlie",
              |   :foo=>"bar",
              |   :metasyntactic=>"variable",
              |   :width=>"quite wide"}]
              |
            EOD

            diff = differ.diff(expected,actual)
            expect(diff).to be_diffed_as(expected_diff)
          end
        end

        it 'outputs unified diff message of two hashes with differing encoding' do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{one_line_header} @@
            |-"a" => "a",
            |#{ (RUBY_VERSION.to_f > 1.8) ?  %Q{+"ö" => "ö"} : '+"\303\266" => "\303\266"' },
            |
          EOD

          diff = differ.diff({'ö' => 'ö'}, {'a' => 'a'})
          expect(diff).to be_diffed_as(expected_diff)
        end

        it 'outputs unified diff message of two hashes with encoding different to key encoding' do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{one_line_header} @@
            |-:a => "a",
            |#{ (RUBY_VERSION.to_f > 1.8) ?  %Q{+\"한글\" => \"한글2\"} : '+"\355\225\234\352\270\200" => "\355\225\234\352\270\2002"' },
            |
          EOD

          diff = differ.diff({ "한글" => "한글2"}, { :a => "a"})
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "outputs unified diff message of two hashes with object keys" do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{one_line_header} @@
            |-["a", "c"] => "b",
            |+["d", "c"] => "b",
            |
          EOD

          diff = differ.diff({ ['d','c'] => 'b'}, { ['a','c'] => 'b' })
          expect(diff).to be_diffed_as(expected_diff)
        end

      context 'when special-case objects are inside hashes' do
        let(:time) { Time.utc(1969, 12, 31, 19, 01, 40, 101) }
        let(:formatted_time) { ObjectFormatter.format(time) }

        it "outputs unified diff message of two hashes with Time object keys" do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{one_line_header} @@
            |-#{formatted_time} => "b",
            |+#{formatted_time} => "c",
            |
          EOD

          diff = differ.diff({ time => 'c'}, { time => 'b' })
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "outputs unified diff message of two hashes with hashes inside them" do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{one_line_header} @@
            |-"b" => {"key_1"=>#{formatted_time}},
            |+"c" => {"key_1"=>#{formatted_time}},
            |
          EOD

          left_side_hash = {'c' => {'key_1' => time}}
          right_side_hash = {'b' => {'key_1' => time}}
          diff = differ.diff(left_side_hash, right_side_hash)
          expect(diff).to be_diffed_as(expected_diff)
        end
      end

      context 'when special-case objects are inside arrays' do
        let(:time) { Time.utc(1969, 12, 31, 19, 01, 40, 101) }
        let(:formatted_time) { ObjectFormatter.format(time) }

        it "outputs unified diff message of two arrays with Time object keys" do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{one_line_header} @@
            |-[#{formatted_time}, "b"]
            |+[#{formatted_time}, "c"]
            |
          EOD

          diff = differ.diff([time, 'c'], [time, 'b'])
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "outputs unified diff message of two arrays with hashes inside them" do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{one_line_header} @@
            |-[{"b"=>#{formatted_time}}, "c"]
            |+[{"a"=>#{formatted_time}}, "c"]
            |
          EOD

          left_side_array = [{'a' => time}, 'c']
          right_side_array = [{'b' => time}, 'c']
          diff = differ.diff(left_side_array, right_side_array)
          expect(diff).to be_diffed_as(expected_diff)
        end
      end

        it "outputs unified diff of multi line strings" do
          expected = "this is:\n  one string"
          actual   = "this is:\n  another string"

          expected_diff = dedent(<<-'EOD')
            |
            |@@ -1,3 +1,3 @@
            | this is:
            |-  another string
            |+  one string
            |
          EOD

          diff = differ.diff(expected,actual)
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "splits items with newlines" do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{removing_two_line_header} @@
            |-a\\nb
            |-c\\nd
            |
          EOD

          diff = differ.diff [], ["a\nb", "c\nd"]
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "shows inner arrays on a single line" do
          expected_diff = dedent(<<-"EOD")
            |
            |@@ #{removing_two_line_header} @@
            |-a\\nb
            |-["c\\nd"]
            |
          EOD

          diff = differ.diff [], ["a\nb", ["c\nd"]]
          expect(diff).to be_diffed_as(expected_diff)
        end

        it "returns an empty string if no expected or actual" do
          diff = differ.diff nil, nil

          expect(diff).to be_empty
        end

        it "returns an empty string if expected is Numeric" do
          diff = differ.diff 1, "2"

          expect(diff).to be_empty
        end

        it "returns an empty string if actual is Numeric" do
          diff = differ.diff "1", 2

          expect(diff).to be_empty
        end

        it "returns an empty string if expected or actual are procs" do
          diff = differ.diff lambda {}, lambda {}

          expect(diff).to be_empty
        end

        it "returns a String if no diff is returned" do
          diff = differ.diff 1, 2
          expect(diff).to be_a(String)
        end

        it "returns a String if a diff is performed" do
          diff = differ.diff "a\n", "b\n"
          expect(diff).to be_a(String)
        end

        it "includes object delegation information in the diff output" do
          in_sub_process_if_possible do
            require "delegate"

            object = Object.new
            delegator = SimpleDelegator.new(object)

            expected_diff = dedent(<<-EOS)
              |
              |@@ #{one_line_header} @@
              |-[#<SimpleDelegator(#{object.inspect})>]
              |+[#{object.inspect}]
              |
            EOS

            diff = differ.diff [object], [delegator]
            expect(diff).to eq(expected_diff)
          end
        end

        context "with :object_preparer option set" do
          let(:differ) do
            RSpec::Support::Differ.new(:object_preparer => lambda { |s| s.to_s.reverse })
          end

          it "uses the output of object_preparer for diffing" do
            expected = :foo
            actual = :poo

            expected_diff = dedent(<<-EOS)
              |
              |@@ #{one_line_header} @@
              |-"oop"
              |+"oof"
              |
            EOS

            diff = differ.diff(expected, actual)
            expect(diff).to be_diffed_as(expected_diff)
          end
        end

        context "with :color option set" do
          let(:differ) { RSpec::Support::Differ.new(:color => true) }

          it "outputs colored diffs" do
            expected = "foo bar baz\n"
            actual = "foo bang baz\n"
            expected_diff = "\e[0m\n\e[0m\e[34m@@ #{one_line_header} @@\n\e[0m\e[31m-foo bang baz\n\e[0m\e[32m+foo bar baz\n\e[0m"

            diff = differ.diff(expected,actual)
            expect(diff).to be_diffed_as(expected_diff)
          end
        end

        context 'when expected or actual is false' do
          it 'generates a diff' do
            expect(differ.diff(true, false)).to_not be_empty
            expect(differ.diff(false, true)).to_not be_empty
          end
        end
      end
    end
  end
end
