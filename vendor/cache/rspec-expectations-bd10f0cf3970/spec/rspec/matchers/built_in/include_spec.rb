# This class fakes some behavior of
# ActiveSupport::HashWithIndifferentAccess.
# It dosen't convert recursively.
class FakeHashWithIndifferentAccess < Hash
  class << self
    def from_hash(hsh)
      new_hsh = new
      hsh.each do |key, value|
        new_hsh[key] = value
      end
      new_hsh
    end
  end

  def [](key)
    super(key.to_s)
  end

  def []=(key, value)
    super(key.to_s, value)
  end

  def key?(key)
    super(key.to_s)
  end

  def to_hash
    new_hsh = ::Hash.new
    each do |key, value|
      new_hsh[key] = value
    end
    new_hsh
  end
end

RSpec.describe "#include matcher" do
  include RSpec::Support::Spec::DiffHelpers

  it "is diffable" do
    expect(include("a")).to be_diffable
  end

  shared_examples_for "a Hash target" do
    def build_target(hsh)
      hsh
    end

    def use_string_keys_in_failure_message?
      false
    end

    def convert_key(key)
      use_string_keys_in_failure_message? ? "\"#{key}\"" : ":#{key}"
    end

    it 'passes if target has the expected as a key' do
      expect(build_target(:key => 'value')).to include(:key)
    end

    it "fails if target does not include expected" do
      failure_string = %(expected {#{convert_key(:key)} => "value"} to include :other)
      expect {
        expect(build_target(:key => 'value')).to include(:other)
      }.to fail_matching(failure_string)
    end

    it "fails if target doesn't have a key and we expect nil" do
      expect {
        expect(build_target({})).to include(:something => nil)
      }.to fail_matching("expected {} to include {:something => nil}")
    end

    it 'works even when an entry in the hash overrides #send' do
      hash = build_target(:key => 'value')
      def hash.send; :sent; end
      expect(hash).to include(hash)
    end

    it 'provides a valid diff' do
      allow(RSpec::Matchers.configuration).to receive(:color?).and_return(false)

      failure_string = if use_string_keys_in_failure_message?
                         dedent(<<-END)
                           |Diff:
                           |@@ -1,3 +1,3 @@
                           |-:bar => 3,
                           |-:foo => 1,
                           |+"bar" => 2,
                           |+"foo" => 1,
                         END
                       else
                         diff = dedent(<<-END)
                           |Diff:
                           |@@ #{one_line_header(3)} @@
                           |-:bar => 3,
                           |+:bar => 2,
                         END
                         diff << "\n :foo => 1,\n" if Diff::LCS::VERSION.to_f < 1.4
                         diff
                       end

      expect {
        expect(build_target(:foo => 1, :bar => 2)).to include(:foo => 1, :bar => 3)
      }.to fail_including(failure_string)
    end

    it 'does not support count constraint' do
      expect {
        expect(build_target(:key => 'value')).to include(:other).once
      }.to raise_error(NotImplementedError)
    end
  end

  describe "expect(...).to include(with_one_arg)" do
    it_behaves_like "an RSpec matcher", :valid_value => [1, 2], :invalid_value => [1] do
      let(:matcher) { include(2) }
    end

    context "for an object that does not respond to `include?`" do
      it 'fails gracefully' do
        expect {
          expect(5).to include(1)
        }.to fail_matching("expected 5 to include 1, but it does not respond to `include?`")
        expect {
          expect(5).to include(1).once
        }.to fail_matching("expected 5 to include 1 once, but it does not respond to `include?`")
      end
    end

    context "for an arbitrary object that responds to `include?`" do
      it 'delegates to `include?`' do
        container = double("Container")
        allow(container).to receive(:include?) { |arg| arg == :stuff }

        expect(container).to include(:stuff)

        expect {
          expect(container).to include(:space)
        }.to fail_matching("to include :space")
      end
    end

    context "for an arbitrary object that responds to `include?` and `to_hash`" do
      it "delegates to `include?`" do
        container = double("Container", :include? => true, :to_hash => { "foo" => "bar" })
        expect(container).to receive(:include?).with("foo").and_return(true)
        expect(container).to include("foo")
      end
    end

    context "for a string target" do
      it "passes if target includes expected" do
        expect("abc").to include("a")
      end

      it "fails if target does not include expected" do
        expect {
          expect("abc").to include("d")
        }.to fail_matching("expected \"abc\" to include \"d\"")
      end

      it "includes a diff when actual is multiline" do
        expect {
          expect("abc\ndef").to include("g")
        }.to fail_matching("expected \"abc\\ndef\" to include \"g\"\nDiff")
      end

      it "includes a diff when actual is multiline and there are multiple expecteds" do
        expect {
          expect("abc\ndef").to include("g", "h")
        }.to fail_matching("expected \"abc\\ndef\" to include \"g\" and \"h\"\nDiff")
      end

      it "does not diff when lines match but are not an exact match" do
        expect {
          expect(" foo\nbar\nbazz").to include("foo", "bar", "gaz")
        }.to fail_with(a_string_not_matching(/Diff/i))
      end

      context "with exact count" do
        it 'fails if the block yields wrong number of times' do
          expect {
            expect('foo bar foo').to include('foo').once
          }.to fail_with(/expected "foo bar foo" to include "foo" once but it is included twice/)
        end

        it 'passes if the block yields the specified number of times' do
          expect('fooo bar').to include('oo').once
          expect('fooo bar').to include('o').thrice
          expect('fooo ooo oo bar foo').to include('oo').exactly(4).times
        end
      end

      context "with at_least count" do
        it 'passes if the search term is included at least the number of times' do
          expect('foo bar foo').to include('foo').at_least(2).times
          expect('foo bar foo foo').to include('foo').at_least(:twice)
        end

        it 'fails if the search term is included too few times' do
          expect {
            expect('foo bar foo').to include('foo').at_least(:thrice)
          }.to fail_with(/expected "foo bar foo" to include "foo" at least 3 times but it is included twice/)
        end
      end

      context "with at_most count" do
        it 'passes if the search term is included at most the number of times' do
          expect('foo bar foo').to include('foo').at_most(2).times
          expect('foo bar').to include('foo').at_most(:twice)
        end

        it 'fails if the search term is included too many times' do
          expect {
            expect('foo bar foo foo').to include('foo').at_most(:twice)
          }.to fail_with(/expected "foo bar foo foo" to include "foo" at most twice but it is included 3 times/)
        end
      end
    end

    context "for an array target" do
      it "passes if target includes expected" do
        expect([1, 2, 3]).to include(3)
      end

      it "fails if target does not include expected" do
        expect {
          expect([1, 2, 3]).to include(4)
        }.to fail_matching("expected [1, 2, 3] to include 4")
      end

      it 'fails when given differing null doubles' do
        dbl_1 = double.as_null_object
        dbl_2 = double.as_null_object

        expect {
          expect([dbl_1]).to include(dbl_2)
        }.to fail_matching("expected [#{dbl_1.inspect}] to include")
      end

      it 'passes when given the same null double' do
        dbl = double.as_null_object
        expect([dbl]).to include(dbl)
      end

      context "with exact count" do
        it 'fails if the block yields wrong number of times' do
          expect {
            expect([1, 2, 1]).to include(1).once
          }.to fail_with('expected [1, 2, 1] to include 1 once but it is included twice')
          expect {
            expect([10, 20, 30]).to include(a_value_within(2).of(17)).twice
          }.to fail_with('expected [10, 20, 30] to include (a value within 2 of 17) twice but it is included 0 times')
        end

        it 'passes if the block yields the specified number of times' do
          expect([1, 2, 1]).to include(1).twice
          expect([10, 20, 30]).to include(a_value_within(5).of(17)).once
        end
      end

      context "with at_least count" do
        it 'passes if the search term is included at least the number of times' do
          expect([1, 2, 1]).to include(1).at_least(2).times
          expect([1, 2, 1, 1]).to include(1).at_least(:twice)
        end

        it 'fails if the search term is included too few times' do
          expect {
            expect([1, 2, 1]).to include(1).at_least(:thrice)
          }.to fail_with('expected [1, 2, 1] to include 1 at least 3 times but it is included twice')
        end
      end

      context "with at_most count" do
        it 'passes if the search term is included at most the number of times' do
          expect([1, 2, 1]).to include(1).at_most(2).times
          expect([1, 2]).to include(1).at_most(:twice)
        end

        it 'fails if the search term is included too many times' do
          expect {
            expect([1, 2, 1, 1]).to include(1).at_most(:twice)
          }.to fail_with('expected [1, 2, 1, 1] to include 1 at most twice but it is included 3 times')
        end
      end
    end

    context "for a hash target" do
      it_behaves_like "a Hash target"
    end

    context "for a target that subclasses Hash to treat string/symbol keys interchangeably, but returns a raw hash from #to_hash" do
      it_behaves_like "a Hash target" do
        undef :build_target # to prevent "method redefined" warning
        def build_target(hsh)
          FakeHashWithIndifferentAccess.from_hash(hsh)
        end

        undef :use_string_keys_in_failure_message? # to prevent "method redefined" warning
        def use_string_keys_in_failure_message?
          true
        end
      end
    end

    context "for a target that can pass for a hash" do
      def build_target(hsh)
        PseudoHash.new(hsh)
      end

      around do |example|
        in_sub_process_if_possible do
          require 'delegate'

          class PseudoHash < SimpleDelegator
          end

          example.run
        end
      end

      it_behaves_like "a Hash target"
    end
  end

  describe "expect(...).to include(with, multiple, args)" do
    it "has a description" do
      matcher = include("a")
      expect(matcher.description).to eq("include \"a\"")
    end
    context "for a string target" do
      it "passes if target includes all items" do
        expect("a string").to include("str", "a")
      end

      it "fails if target does not include one of the items" do
        expect {
          expect("a string").to include("str", "a", "foo")
        }.to fail_matching('expected "a string" to include "foo"')
      end

      it "fails if target does not include two of the items" do
        expect {
          expect("a string").to include("nope", "a", "nada", "str")
        }.to fail_matching('expected "a string" to include "nope" and "nada"')
      end

      it "fails if target does not include many of the items" do
        expect {
          expect("a string").to include("nope", "a", "nada", "nein", "ing", "str")
        }.to fail_matching('expected "a string" to include "nope", "nada", and "nein"')
      end
    end

    context "for an array target" do
      it "passes if target includes all items" do
        expect([1, 2, 3]).to include(1, 2, 3)
      end

      it "fails if target does not include one of the items" do
        expect {
          expect([1, 2, 3]).to include(1, 2, 4)
        }.to fail_matching("expected [1, 2, 3] to include 4")
      end

      it "fails if target does not include two of the items" do
        expect {
          expect([1, 2, 3]).to include(5, 1, 2, 4)
        }.to fail_matching("expected [1, 2, 3] to include 5 and 4")
      end

      it "fails if target does not include many of the items" do
        expect {
          expect([1, 2, 3]).to include(5, 1, 6, 2, 4)
        }.to fail_matching("expected [1, 2, 3] to include 5, 6, and 4")
      end

      it 'correctly diffs lists of hashes' do
        allow(RSpec::Matchers.configuration).to receive(:color?).and_return(false)

        expect {
          expect([
            { :number => 1 },
            { :number => 2 },
            { :number => 3 }
          ]).to include(
            { :number => 1 },
            { :number => 0 },
            { :number => 3 }
          )
        }.to fail_including(dedent(<<-END))
          |Diff:
          |@@ #{one_line_header} @@
          |-[{:number=>1}, {:number=>0}, {:number=>3}]
          |+[{:number=>1}, {:number=>2}, {:number=>3}]
        END
      end
    end

    context "for a hash target" do
      it 'passes if target includes all items as keys' do
        expect({ :key => 'value', :other => 'value' }).to include(:key, :other)
      end

      it 'fails if target does not include one of the items as a key' do
        expect {
          expect({ :key => 'value', :this => 'that' }).to include(:key, :nope, :this)
        }.to fail_with(%r|expected #{hash_inspect :key => "value", :this => "that"} to include :nope|)
      end

      it "fails if target does not include two of the items as keys" do
        expect {
          expect({ :key => 'value', :this => 'that' }).to include(:nada, :key, :nope, :this)
        }.to fail_with(%r|expected #{hash_inspect :key => "value", :this => "that"} to include :nada and :nope|)
      end

      it "fails if target does not include many of the items as keys" do
        expect {
          expect({ :key => 'value', :this => 'that' }).to include(:nada, :key, :nope, :negative, :this)
        }.to fail_with(%r|expected #{hash_inspect :key => "value", :this => "that"} to include :nada, :nope, and :negative|)
      end
    end

    it 'does not implement count constraints' do
      expect {
        expect('').to include('foo', 'bar').once
      }.to raise_error(NotImplementedError)
      expect {
        expect('').to include('foo', 'bar').at_least(:twice)
      }.to raise_error(NotImplementedError)
      expect {
        expect('').to include('foo', 'bar').at_most(:twice)
      }.to raise_error(NotImplementedError)
    end
  end

  describe "expect(...).not_to include(expected)" do
    context "for an object that does not respond to `include?`" do
      it 'fails gracefully' do
        expect {
          expect(5).not_to include(1)
        }.to fail_matching("expected 5 not to include 1, but it does not respond to `include?`")
      end
    end

    context "for an arbitrary object that responds to `include?`" do
      it 'delegates to `include?`' do
        container = double("Container")
        allow(container).to receive(:include?) { |arg| arg == :stuff }

        expect(container).not_to include(:space)

        expect {
          expect(container).not_to include(:stuff)
        }.to fail_matching("not to include :stuff")
      end
    end

    context "for a string target" do
      it "passes if target does not include expected" do
        expect("abc").not_to include("d")
      end

      it "fails if target includes expected" do
        expect {
          expect("abc").not_to include("c")
        }.to fail_with("expected \"abc\" not to include \"c\"")
      end

      context "with exact count" do
        it 'passes if the block yields wrong number of times' do
          expect('foo bar foo').not_to include('foo').once
        end

        it 'fails if the block yields the specified number of times' do
          expect {
            expect('fooo bar').not_to include('oo').once
          }.to fail_with(/expected "fooo bar" not to include "oo" once but it is included once/)
        end
      end

      context "with at_least count" do
        it 'fails if the search term is included at least the number of times' do
          expect {
            expect('foo bar foo foo').not_to include('foo').at_least(:twice)
          }.to fail_with(/expected "foo bar foo foo" not to include "foo" at least twice but it is included 3 times/)
        end

        it 'passes if the search term is included too few times' do
          expect('foo bar foo').not_to include('foo').at_least(:thrice)
        end
      end

      context "with at_most count" do
        it 'fails if the search term is included at most the number of times' do
          expect {
            expect('foo bar').not_to include('foo').at_most(:twice)
          }.to fail_with(/expected "foo bar" not to include "foo" at most twice but it is included once/)
        end

        it 'passes if the search term is included too many times' do
          expect('foo bar foo foo').not_to include('foo').at_most(:twice)
        end
      end
    end

    context "for an array target" do
      it "passes if target does not include expected" do
        expect([1, 2, 3]).not_to include(4)
      end

      it "fails if target includes expected" do
        expect {
          expect([1, 2, 3]).not_to include(3)
        }.to fail_with("expected [1, 2, 3] not to include 3")
      end

      it 'passes when given differing null doubles' do
        expect([double.as_null_object]).not_to include(double.as_null_object)
      end

      it 'fails when given the same null double' do
        dbl = double.as_null_object

        expect {
          expect([dbl]).not_to include(dbl)
        }.to fail_matching("expected [#{dbl.inspect}] not to include")
      end
    end

    context "for a hash target" do
      it 'passes if target does not have the expected as a key' do
        expect({ :other => 'value' }).not_to include(:key)
      end

      it "fails if target includes expected key" do
        expect {
          expect({ :key => 'value' }).not_to include(:key)
        }.to fail_matching('expected {:key => "value"} not to include :key')
      end
    end

  end

  describe "expect(...).not_to include(with, multiple, args)" do
    context "for a string target" do
      it "passes if the target does not include any of the expected" do
        expect("abc").not_to include("d", "e", "f")
      end

      it "fails if the target includes all of the expected" do
        expect {
          expect("abc").not_to include("c", "a")
        }.to fail_with('expected "abc" not to include "c" and "a"')
      end

      it "fails if the target includes one (but not all) of the expected" do
        expect {
          expect("abc").not_to include("d", "a")
        }.to fail_with('expected "abc" not to include "a"')
      end

      it "fails if the target includes two (but not all) of the expected" do
        expect {
          expect("abc").not_to include("d", "a", "b")
        }.to fail_with('expected "abc" not to include "a" and "b"')
      end

      it "fails if the target includes many (but not all) of the expected" do
        expect {
          expect("abcd").not_to include("b", "d", "a", "f")
        }.to fail_with('expected "abcd" not to include "b", "d", and "a"')
      end
    end

    context "for a hash target" do
      it "passes if it does not include any of the expected keys" do
        expect({ :a => 1, :b => 2 }).not_to include(:c, :d)
      end

      it "fails if the target includes all of the expected keys" do
        expect {
          expect({ :a => 1, :b => 2 }).not_to include(:a, :b)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2} not to include :a and :b|)
      end

      it "fails if the target includes one (but not all) of the expected keys" do
        expect {
          expect({ :a => 1, :b => 2 }).not_to include(:d, :b)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2} not to include :b|)
      end

      it "fails if the target includes two (but not all) of the expected keys" do
        expect {
          expect({ :a => 1, :b => 2 }).not_to include(:a, :b, :c)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2} not to include :a and :b|)
      end

      it "fails if the target includes many (but not all) of the expected keys" do
        expect {
          expect({ :a => 1, :b => 2, :c => 3 }).not_to include(:b, :a, :c, :f)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2, :c => 3} not to include :b, :a, and :c|)
      end
    end

    context "for an array target" do
      it "passes if the target does not include any of the expected" do
        expect([1, 2, 3]).not_to include(4, 5, 6)
      end

      it "fails if the target includes all of the expected" do
        expect {
          expect([1, 2, 3]).not_to include(3, 1)
        }.to fail_with('expected [1, 2, 3] not to include 3 and 1')
      end

      it "fails if the target includes one (but not all) of the expected" do
        expect {
          expect([1, 2, 3]).not_to include(4, 1)
        }.to fail_with('expected [1, 2, 3] not to include 1')
      end

      it "fails if the target includes two (but not all) of the expected" do
        expect {
          expect([1, 2, 3]).not_to include(4, 1, 2)
        }.to fail_with('expected [1, 2, 3] not to include 1 and 2')
      end

      it "fails if the target includes many (but not all) of the expected" do
        expect {
          expect([1, 2, 3]).not_to include(5, 4, 2, 1, 3)
        }.to fail_with('expected [1, 2, 3] not to include 2, 1, and 3')
      end
    end
  end

  describe "expect(...).to include(:key => value)" do
    context 'for a hash target' do
      it "passes if target includes the key/value pair" do
        expect({ :key => 'value' }).to include(:key => 'value')
      end

      it "passes if target includes the key/value pair among others" do
        expect({ :key => 'value', :other => 'different' }).to include(:key => 'value')
      end

      it "fails if target has a different value for key" do
        expect {
          expect({ :key => 'different' }).to include(:key => 'value')
        }.to fail_matching('expected {:key => "different"} to include {:key => "value"}')
      end

      it "fails if target has a different key" do
        expect {
          expect({ :other => 'value' }).to include(:key => 'value')
        }.to fail_matching('expected {:other => "value"} to include {:key => "value"}')
      end
    end

    context 'for a non-hash target' do
      it "fails if the target does not contain the given hash" do
        expect {
          expect(['a', 'b']).to include(:key => 'value')
        }.to fail_matching('expected ["a", "b"] to include {:key => "value"}')
      end

      it "passes if the target contains the given hash" do
        expect(['a', { :key => 'value' }]).to include(:key => 'value')
      end
    end
  end

  describe "expect(...).not_to include(:key => value)" do
    context 'for a hash target' do
      it "fails if target includes the key/value pair" do
        expect {
          expect({ :key => 'value' }).not_to include(:key => 'value')
        }.to fail_matching('expected {:key => "value"} not to include {:key => "value"}')
      end

      it "fails if target includes the key/value pair among others" do
        expect {
          expect({ :key => 'value', :other => 'different' }).not_to include(:key => 'value')
        }.to fail_with(%r|expected #{hash_inspect :key => "value", :other => "different"} not to include \{:key => "value"\}|)
      end

      it "passes if target has a different value for key" do
        expect({ :key => 'different' }).not_to include(:key => 'value')
      end

      it "passes if target has a different key" do
        expect({ :other => 'value' }).not_to include(:key => 'value')
      end
    end

    context "for a non-hash target" do
      it "passes if the target does not contain the given hash" do
        expect(['a', 'b']).not_to include(:key => 'value')
      end

      it "fails if the target contains the given hash" do
        expect {
          expect(['a', { :key => 'value' }]).not_to include(:key => 'value')
        }.to fail_matching('expected ["a", {:key => "value"}] not to include {:key => "value"}')
      end
    end
  end

  describe "expect(...).to include(:key1 => value1, :key2 => value2)" do
    context 'for a hash target' do
      it "passes if target includes the key/value pairs" do
        expect({ :a => 1, :b => 2 }).to include(:b => 2, :a => 1)
      end

      it "passes if target includes the key/value pairs among others" do
        expect({ :a => 1, :c => 3, :b => 2 }).to include(:b => 2, :a => 1)
      end

      it "fails if target has a different value for one of the keys" do
        expect {
          expect({ :a => 1, :b => 2 }).to include(:a => 2, :b => 2)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2} to include #{hash_inspect :a => 2}|)
      end

      it "fails if target has a different value for both of the keys" do
        expect {
          expect({ :a => 1, :b => 1 }).to include(:a => 2, :b => 2)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 1} to include #{hash_inspect :a => 2, :b => 2}|)
      end

      it "fails if target lacks one of the keys" do
        expect {
          expect({ :a => 1, :b => 1 }).to include(:a => 1, :c => 1)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 1} to include #{hash_inspect :c => 1}|)
      end

      it "fails if target lacks both of the keys" do
        expect {
          expect({ :a => 1, :b => 1 }).to include(:c => 1, :d => 1)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 1} to include #{hash_inspect :c => 1, :d => 1}|)
      end

      it "fails if target lacks one of the keys and has a different value for another" do
        expect {
          expect({ :a => 1, :b => 2 }).to include(:c => 1, :b => 3)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2} to include #{hash_inspect :c => 1, :b => 3}|)
      end
    end

    context 'for a non-hash target' do
      it "fails if the target does not contain the given hash" do
        expect {
          expect(['a', 'b']).to include(:a => 1, :b => 1)
        }.to fail_with(%r|expected \["a", "b"\] to include #{hash_inspect :a => 1, :b => 1}|)
      end

      it "passes if the target contains the given hash" do
        expect(['a', { :a => 1, :b => 2 }]).to include(:a => 1, :b => 2)
      end
    end
  end

  describe "expect(...).not_to include(:key1 => value1, :key2 => value2)" do
    context 'for a hash target' do
      it "fails if target includes the key/value pairs" do
        expect {
          expect({ :a => 1, :b => 2 }).not_to include(:a => 1, :b => 2)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2} not to include #{hash_inspect :a => 1, :b => 2}|)
      end

      it "fails if target includes the key/value pairs among others" do
        hash = { :a => 1, :b => 2, :c => 3 }
        expect {
          expect(hash).not_to include(:a => 1, :b => 2)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2, :c => 3} not to include #{hash_inspect :a => 1, :b => 2}|)
      end

      it "fails if target has a different value for one of the keys" do
        expect {
          expect({ :a => 1, :b => 2 }).not_to include(:a => 2, :b => 2)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 2} not to include #{hash_inspect :b => 2}|)
      end

      it "passes if target has a different value for both of the keys" do
        expect({ :a => 1, :b => 1 }).not_to include(:a => 2, :b => 2)
      end

      it "fails if target lacks one of the keys" do
        expect {
          expect({ :a => 1, :b => 1 }).not_to include(:a => 1, :c => 1)
        }.to fail_with(%r|expected #{hash_inspect :a => 1, :b => 1} not to include #{hash_inspect :a => 1}|)
      end

      it "passes if target lacks both of the keys" do
        expect({ :a => 1, :b => 1 }).not_to include(:c => 1, :d => 1)
      end
    end

    context 'for a non-hash target' do
      it "passes if the target does not contain the given hash" do
        expect(['a', 'b']).not_to include(:a => 1, :b => 1)
      end

      it "fails if the target contains the given hash" do
        expect {
          expect(['a', { :a => 1, :b => 2 }]).not_to include(:a => 1, :b => 2)
        }.to fail_with(%r|expected \["a", #{hash_inspect :a => 1, :b => 2}\] not to include #{hash_inspect :a => 1, :b => 2}|)
      end
    end
  end

  describe "Composing matchers with `include`" do
    RSpec::Matchers.define :a_string_containing do |expected|
      match do |actual|
        actual.include?(expected)
      end

      description do
        "a string containing '#{expected}'"
      end
    end

    describe "expect(array).to include(matcher)" do
      it "passes when the matcher matches one of the values" do
        expect([10, 20, 30]).to include( a_value_within(5).of(24) )
      end

      it 'provides a description' do
        description = include( a_value_within(5).of(24) ).description
        expect(description).to eq("include (a value within 5 of 24)")
      end

      it 'fails with a clear message when the matcher matches none of the values' do
        expect {
          expect([10, 30]).to include( a_value_within(5).of(24) )
        }.to fail_with("expected [10, 30] to include (a value within 5 of 24)")
      end

      it 'works with comparison matchers' do
        expect {
          expect([100, 200]).to include(a_value < 90)
        }.to fail_with("expected [100, 200] to include (a value < 90)")

        expect([100, 200]).to include(a_value > 150)
      end

      it 'does not treat an object that only implements #matches? as a matcher' do
        not_a_matcher = Struct.new(:value) do
          def matches?(_)
            fail "`matches?` should never be called"
          end
        end

        expect([not_a_matcher.new("rspec.info")]).to include(not_a_matcher.new("rspec.info"))

        expect {
          expect([not_a_matcher.new("rspec.info")]).to include(not_a_matcher.new("foo.com"))
        }.to fail_matching("expected [#{not_a_matcher.new("rspec.info").inspect}] to include")
      end
    end

    describe "expect(array).to include(multiple, matcher, arguments)" do
      it "passes if target includes items satisfying all matchers" do
        expect(['foo', 'bar', 'baz']).to include(a_string_containing("ar"), a_string_containing('oo'))
      end

      it "fails if target does not include an item satisfying any one of the items" do
        expect {
          expect(['foo', 'bar', 'baz']).to include(a_string_containing("ar"), a_string_containing("abc"))
        }.to fail_matching("expected #{['foo', 'bar', 'baz'].inspect} to include (a string containing 'abc')")
      end
    end

    describe "expect(hash).to include(key => matcher)" do
      it "passes when the matcher matches" do
        expect(:a => 12).to include(:a => a_value_within(3).of(10))
      end

      it 'provides a description' do
        description = include(:a => a_value_within(3).of(10)).description
        expect(description).to eq("include {:a => (a value within 3 of 10)}")
      end

      it "fails with a clear message when the matcher does not match" do
        expect {
          expect(:a => 15).to include(:a => a_value_within(3).of(10))
        }.to fail_matching("expected {:a => 15} to include {:a => (a value within 3 of 10)}")
      end
    end

    describe "expect(hash).to include(key_matcher)" do
      it "passes when the matcher matches a key", :if => (RUBY_VERSION.to_f > 1.8) do
        expect(:drink => "water", :food => "bread").to include(match(/foo/))
      end

      it 'provides a description' do
        description = include(match(/foo/)).description
        expect(description).to eq("include (match /foo/)")
      end

      it 'fails with a clear message when the matcher does not match', :if => (RUBY_VERSION.to_f > 1.8) do
        expect {
          expect(:drink => "water", :food => "bread").to include(match(/bar/))
        }.to fail_matching('expected {:drink => "water", :food => "bread"} to include (match /bar/)')
      end
    end

    describe "expect(hash).to include(key_matcher => value)" do
      it "passes when the matcher matches a pair", :if => (RUBY_VERSION.to_f > 1.8) do
        expect(:drink => "water", :food => "bread").to include(match(/foo/) => "bread")
      end

      it "passes when the matcher matches all pairs", :if => (RUBY_VERSION.to_f > 1.8) do
        expect(:drink => "water", :food => "bread").to include(match(/foo/) => "bread", match(/ink/) => "water")
      end

      it "passes with a natural matcher", :if => (RUBY_VERSION.to_f > 1.8) do
        expect(:drink => "water", :food => "bread").to include(/foo/ => "bread")
      end

      it "passes with a natural matcher", :if => (RUBY_VERSION.to_f > 1.8) do
        expect(:drink => "water", :food => "bread").to include(/foo/ => /read/)
      end

      it 'provides a description' do
        description = include(match(/foo/) => "bread").description
        expect(description).to eq('include {(match /foo/) => "bread"}')
      end

      it 'fails with a clear message when the value does not match', :if => (RUBY_VERSION.to_f > 1.8) do
        expect {
          expect(:drink => "water", :food => "bread").to include(match(/foo/) => "meat")
        }.to fail_matching('expected {:drink => "water", :food => "bread"} to include {(match /foo/) => "meat"}')
      end

      it 'fails with a clear message when the matcher does not match', :if => (RUBY_VERSION.to_f > 1.8) do
        expect {
          expect(:drink => "water", :food => "bread").to include(match(/bar/) => "bread")
        }.to fail_matching('expected {:drink => "water", :food => "bread"} to include {(match /bar/) => "bread"}')
      end

      it 'fails with a clear message when several matchers do not match', :if => (RUBY_VERSION.to_f > 1.8) do
        expect {
          expect(:drink => "water", :food => "bread").to include(match(/bar/) => "bread", match(/baz/) => "water")
        }.to fail_matching('expected {:drink => "water", :food => "bread"} to include {(match /bar/) => "bread", (match /baz/) => "water"}')
      end
    end

    describe "expect(array).not_to include(multiple, matcher, arguments)" do
      it "passes if none of the target values satisfies any of the matchers" do
        expect(['foo', 'bar', 'baz']).not_to include(a_string_containing("gh"), a_string_containing('de'))
      end

      it 'fails if all of the matchers are satisfied by one of the target values' do
        expect {
          expect(['foo', 'bar', 'baz']).not_to include(a_string_containing("ar"), a_string_containing('az'))
        }.to fail_matching("expected #{['foo', 'bar', 'baz'].inspect} not to include (a string containing 'ar') and (a string containing 'az')")
      end

      it 'fails if the some (but not all) of the matchers are satisifed' do
        expect {
          expect(['foo', 'bar', 'baz']).not_to include(a_string_containing("ar"), a_string_containing('bz'))
        }.to fail_matching("expected #{['foo', 'bar', 'baz'].inspect} not to include (a string containing 'ar')")
      end
    end
  end

  # `fail_including` uses the `include` matcher internally, and using a matcher
  # to test itself is potentially problematic, so just for this spec file we
  # use `fail_matching` instead, which converts to a regex instead.
  def fail_matching(message)
    raise_error(RSpec::Expectations::ExpectationNotMetError, /#{Regexp.escape(message)}/)
  end
end
