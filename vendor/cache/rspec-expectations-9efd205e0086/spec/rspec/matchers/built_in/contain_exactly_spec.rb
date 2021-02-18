class UnsortableObject
  def initialize(id)
    @id = id
  end

  def inspect
    @id.to_s
  end

  def ==(_other)
    false
  end
end

# AR::Relation is meant to act like a collection, but does
# not include `Enumerable`. It does implement `to_ary`.
class FakeActiveRecordRelation
  def initialize(records)
    @records = records
  end

  def to_ary
    @records
  end
end

RSpec.describe "should =~ array", :uses_should do
  it "passes a valid positive expectation" do
    [1, 2].should =~ [2, 1]
  end

  it "fails an invalid positive expectation" do
    expect {
      [1, 2, 3].should =~ [2, 1]
    }.to fail_with(/expected collection contained/)
  end

  context "when the array defines a `=~` method" do
    it 'delegates to that method rather than using the contain_exactly matcher' do
      array = []
      def array.=~(other)
        other == :foo
      end

      array.should =~ :foo
      expect {
        array.should =~ :bar
      }.to fail_with(/expected: :bar/)
    end
  end

  context 'when the array defines a `send` method' do
    it 'still works' do
      array = [1, 2]
      def array.send; :sent; end

      array.should =~ array
    end
  end

  context "when the array undefines `=~`" do
    it 'still works' do
      array_klass = Class.new(Array) { undef =~ }
      array = array_klass.new([1, 2])

      array.should =~ [1, 2]

      expect {
        array.should =~ [0, 1, 2]
      }.to fail_with(/expected collection contained/)
    end
  end
end

RSpec.describe "should_not =~ [:with, :multiple, :args]", :uses_should do
  it "fails when the arrays match" do
    expect {
      [1, 2, 3].should_not =~ [1, 2, 3]
    }.to fail_with "expected [1, 2, 3] not to contain exactly 1, 2, and 3"
  end

  it "fails when the arrays match in a different order" do
    expect {
      [1, 3, 2].should_not =~ [1, 2, 3]
    }.to fail_with "expected [1, 3, 2] not to contain exactly 1, 2, and 3"
  end

  it "passes when there are extra elements in the array" do
    [1, 3].should_not =~ [1, 2, 3]
  end

  it "passes when there are elements missing from the array" do
    [1, 2, 3, 4].should_not =~ [1, 2, 3]
  end
end

RSpec.describe "using contain_exactly with expect" do
  it "passes a valid positive expectation" do
    expect([1, 2]).to contain_exactly(2, 1)
  end

  it "fails an invalid positive expectation" do
    expect {
      expect([1, 2, 3]).to contain_exactly(2, 1)
    }.to fail_with(/expected collection contained/)
  end

  it "passes for an out of order valid positive expectation with hashes" do
    expect([
      { :a => 10 },
      { :a => -10 }
    ]).to contain_exactly(
      { :a => (a_value < 0) },
      { :a => (a_value > 0) }
    )
  end

  it "passes for an in order valid positive expectation with hashes" do
    expect([
      { :a => 10 },
      { :a => -10 }
    ]).to contain_exactly(
      { :a => (a_value > 0) },
      { :a => (a_value < 0) }
    )
  end

  it 'works with strict test doubles (which have not defined `<=>`)' do
    dbl_1 = double("1")
    dbl_2 = double("2")

    expect([dbl_1, dbl_2]).to contain_exactly(dbl_2, dbl_1)

    expect {
      expect([dbl_1, dbl_2]).to contain_exactly(dbl_1)
    }.to fail
  end

  it "does not support strings (which have no standard way to be enumerated: bytes, chars or lines)" do
    expect {
      expect("abcd").to contain_exactly("d", "c", "a", "b")
    }.to fail_with('expected a collection that can be converted to an array with `#to_ary` or `#to_a`, but got "abcd"')
  end

  it "supports ranges" do
    expect(1..3).to contain_exactly(1, 2, 3)
  end
end

RSpec.describe "expect(array).to contain_exactly(*other_array)" do
  it_behaves_like "an RSpec value matcher", :valid_value => [1, 2], :invalid_value => [1] do
    let(:matcher) { contain_exactly(2, 1) }
  end

  it 'is also exposed as `match_array` (with unsplatted args)' do
    expect([1, 2, 3]).to match_array([3, 2, 1])
  end

  it "passes if target contains all items" do
    expect([1, 2, 3]).to contain_exactly(1, 2, 3)
  end

  it "passes if target contains all items out of order" do
    expect([1, 3, 2]).to contain_exactly(1, 2, 3)
  end

  it 'fails if the expected array is empty and the actual array is non-empty' do
    expect {
      expect([1]).to contain_exactly # no arguments passed to the matcher
    }.to fail_with(<<-MESSAGE)
expected collection contained:  []
actual collection contained:    [1]
the extra elements were:        [1]
MESSAGE
  end

  it 'fails if the actual array is empty and the expected array is non-empty' do
    expect {
      expect([]).to contain_exactly(1)
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [1]
actual collection contained:    []
the missing elements were:      [1]
MESSAGE
  end

  def timeout_if_not_debugging(time)
    in_sub_process_if_possible do
      require 'timeout'
      return yield if defined?(::Debugger)
      Timeout.timeout(time) { yield }
    end
  end

  it 'fails a match of 11 items with duplicates in a reasonable amount of time' do
    timeout_if_not_debugging(0.1) do
      expected = [0, 1, 1,    3, 3, 3,    4, 4,    8, 8, 9   ]
      actual   = [   1,    2, 3, 3, 3, 3,       7, 8, 8, 9, 9]

      expect {
        expect(actual).to contain_exactly(*expected)
      }.to fail_including("the missing elements were:      [0, 1, 4, 4]")
    end
  end

  it "fails if target includes extra items" do
    expect {
      expect([1, 2, 3, 4]).to contain_exactly(1, 2, 3)
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [1, 2, 3]
actual collection contained:    [1, 2, 3, 4]
the extra elements were:        [4]
MESSAGE
  end

  it "fails if target is missing items" do
    expect {
      expect([1, 2]).to contain_exactly(1, 2, 3)
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [1, 2, 3]
actual collection contained:    [1, 2]
the missing elements were:      [3]
MESSAGE
  end

  it "fails if target is missing items and has extra items" do
    expect {
      expect([1, 2, 4]).to contain_exactly(1, 2, 3)
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [1, 2, 3]
actual collection contained:    [1, 2, 4]
the missing elements were:      [3]
the extra elements were:        [4]
MESSAGE
  end

  it "sorts items in the error message if they all respond to <=>" do
    expect {
      expect([6, 2, 1, 5]).to contain_exactly(4, 1, 2, 3)
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [1, 2, 3, 4]
actual collection contained:    [1, 2, 5, 6]
the missing elements were:      [3, 4]
the extra elements were:        [5, 6]
MESSAGE
  end

  it "does not sort items in the error message if they don't all respond to <=>" do
    expect {
      expect([UnsortableObject.new(2), UnsortableObject.new(1)]).to contain_exactly(UnsortableObject.new(4), UnsortableObject.new(3))
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [4, 3]
actual collection contained:    [2, 1]
the missing elements were:      [4, 3]
the extra elements were:        [2, 1]
MESSAGE
  end

  it "accurately reports extra elements when there are duplicates" do
    expect {
      expect([1, 1, 1, 5]).to contain_exactly(1, 5)
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [1, 5]
actual collection contained:    [1, 1, 1, 5]
the extra elements were:        [1, 1]
MESSAGE
  end

  it "accurately reports missing elements when there are duplicates" do
    expect {
      expect([1, 5]).to contain_exactly(1, 1, 5)
    }.to fail_with(<<-MESSAGE)
expected collection contained:  [1, 1, 5]
actual collection contained:    [1, 5]
the missing elements were:      [1]
MESSAGE
  end
end

RSpec.describe "expect(...).not_to contain_exactly(:with, :multiple, :args)" do
  it "fails when the arrays match" do
    expect {
      expect([1, 2, 3]).not_to contain_exactly(1, 2, 3)
    }.to fail_with "expected [1, 2, 3] not to contain exactly 1, 2, and 3"
  end

  it "fails when the arrays match in a different order" do
    expect {
      expect([1, 3, 2]).not_to contain_exactly(1, 2, 3)
    }.to fail_with "expected [1, 3, 2] not to contain exactly 1, 2, and 3"
  end

  it "passes when there are extra elements in the array" do
    expect([1, 3]).not_to contain_exactly(1, 2, 3)
  end

  it "passes when there are elements missing from the array" do
    expect([1, 2, 3, 4]).not_to contain_exactly(1, 2, 3)
  end
end

RSpec.describe "matching against things that aren't arrays" do
  it "fails with nil and the expected error message is given" do
    expect {
      expect(nil).to contain_exactly(1, 2, 3)
    }.to fail_with(/expected a collection/)
  end

  it "fails with a float and the expected error message is given" do
    expect {
      expect(3.7).to contain_exactly(1, 2, 3)
    }.to fail_with(/expected a collection/)
  end

  it "fails with a string and the expected error message is given" do
    expect {
      expect("I like turtles").to contain_exactly(1, 2, 3)
    }.to fail_with(/expected a collection/)
  end

  it 'works with other collection objects' do
    in_sub_process_if_possible do
      require 'set'
      expect(Set.new([3, 2, 1])).to contain_exactly(1, 2, 3)
      expect {
        expect(Set.new([3, 2, 1])).to contain_exactly(1, 2)
      }.to fail_including("expected collection contained:  [1, 2]")
    end
  end

  it 'works with non-enumerables that implement `to_ary`' do
    relation = FakeActiveRecordRelation.new([1, 2, 3])
    expect(relation).to contain_exactly(2, 1, 3)
    expect {
      expect(relation).to contain_exactly(1, 2)
    }.to fail_including("expected collection contained:  [1, 2]")
  end
end

RSpec.describe "Composing `contain_exactly` with other matchers" do
  context "when it is compared to multiple possible matches" do
    it 'works properly when passed as an argument in its aliased form' do
      expect([[1, 3], ["food", "barn"]]).to include(
        a_collection_containing_exactly(/foo/, /bar/)
      )
    end
  end

  describe "expect(...).to contain_exactly(matcher, matcher)" do
    it 'passes when the array matches the matchers in the same order' do
      expect(["food", "barn"]).to contain_exactly(
        a_string_matching(/foo/),
        a_string_matching(/bar/)
      )
    end

    it 'passes when the array matches the matchers in a different order' do
      expect(["food", "barn"]).to contain_exactly(
        a_string_matching(/bar/),
        a_string_matching(/foo/)
      )
    end

    it 'fails with a useful message when there is an extra element' do
      expect {
        expect(["food", "barn", "goo"]).to contain_exactly(
          a_string_matching(/bar/),
          a_string_matching(/foo/)
        )
      }.to fail_with(dedent <<-EOS)
        |expected collection contained:  [(a string matching /bar/), (a string matching /foo/)]
        |actual collection contained:    ["barn", "food", "goo"]
        |the extra elements were:        ["goo"]
        |
      EOS
    end

    it 'fails with a useful message when there is a missing element' do
      expect {
        expect(["food", "barn"]).to contain_exactly(
          a_string_matching(/bar/),
          a_string_matching(/foo/),
          a_string_matching(/goo/)
        )
      }.to fail_with(dedent <<-EOS)
        |expected collection contained:  [(a string matching /bar/), (a string matching /foo/), (a string matching /goo/)]
        |actual collection contained:    ["barn", "food"]
        |the missing elements were:      [(a string matching /goo/)]
        |
      EOS
    end

    it 'pairs up the items in order to minimize the number of unpaired items' do
      expect {
        expect(["fool", "food", "good"]).to contain_exactly(/foo/, /fool/, /poo/)
      }.to fail_with(dedent <<-EOS)
        |expected collection contained:  [/foo/, /fool/, /poo/]
        |actual collection contained:    ["food", "fool", "good"]
        |the missing elements were:      [/poo/]
        |the extra elements were:        ["good"]
        |
      EOS
    end

    it 'provides a description' do
      description = contain_exactly(a_string_matching(/bar/), a_string_matching(/foo/)).description
      expect(description).to eq("contain exactly (a string matching /bar/) and (a string matching /foo/)")
    end

    context 'when an earlier matcher matches more strictly than a later matcher' do
      it 'works when the actual items match in the same order' do
        expect(["food", "fool"]).to contain_exactly(a_string_matching(/foo/), a_string_matching(/fool/))
      end

      it 'works when the actual items match in reverse order' do
        expect(["fool", "food"]).to contain_exactly(a_string_matching(/foo/), a_string_matching(/fool/))
      end

      it 'can handle multiple sets of overlapping matches' do
        expect(["fool", "barn", "bare", "food"]).to contain_exactly(
          a_string_matching(/bar/),
          a_string_matching(/barn/),
          a_string_matching(/foo/),
          a_string_matching(/fool/)
        )
      end
    end

    it "can use `a_value_within` and `a_string_starting_with` against multiple types of values" do
      expect(["barn", 2.45]).to contain_exactly(
        a_value_within(0.1).of(2.5),
        a_string_starting_with("bar")
      )
    end

    context 'when a later matcher matches more strictly than an earlier matcher' do
      it 'works when the actual items match in the same order' do
        expect(["fool", "food"]).to contain_exactly(a_string_matching(/fool/), a_string_matching(/foo/))
      end

      it 'works when the actual items match in reverse order' do
        expect(["food", "fool"]).to contain_exactly(a_string_matching(/fool/), a_string_matching(/foo/))
      end
    end
  end

  describe "expect(...).to_not contain_exactly(matcher, matcher)" do
    it 'fails when the array matches the matchers' do
      expect {
        expect(["food", "barn"]).to_not contain_exactly(
          a_string_matching(/bar/),
          a_string_matching(/foo/)
        )
      }.to fail_with 'expected ["food", "barn"] not to contain exactly '\
                     "(a string matching /bar/) and (a string matching /foo/)"
    end

    it 'passes when there is an extra element' do
      expect(["food", "barn", "goo"]).to_not contain_exactly(
        a_string_matching(/bar/),
        a_string_matching(/foo/)
      )
    end

    it 'passes when there is a missing element' do
      expect(["food", "barn"]).to_not contain_exactly(
        a_string_matching(/bar/),
        a_string_matching(/foo/),
        a_string_matching(/goo/)
      )
    end

  end
end

module RSpec
  module Matchers
    module BuiltIn
      class ContainExactly
        RSpec.describe PairingsMaximizer do
          it 'finds unmatched expected indexes' do
            maximizer = PairingsMaximizer.new({ 0 => [], 1 => [0] }, { 0 => [1] })
            expect(maximizer.solution.unmatched_expected_indexes).to eq([0])
          end

          it 'finds unmatched actual indexes' do
            maximizer = PairingsMaximizer.new({ 0 => [0] }, { 0 => [0], 1 => [] })
            expect(maximizer.solution.unmatched_actual_indexes).to eq([1])
          end

          describe "finding indeterminate indexes" do
            it 'does not include unmatched indexes' do
              maximizer = PairingsMaximizer.new({ 0 => [], 1 => [0] }, { 0 => [1], 1 => [] })

              expect(maximizer.solution.indeterminate_expected_indexes).not_to include(0)
              expect(maximizer.solution.indeterminate_actual_indexes).not_to include(1)
            end

            it 'does not include indexes that are reciprocally to exactly one index' do
              maximizer = PairingsMaximizer.new({ 0 => [], 1 => [0] }, { 0 => [1], 1 => [0] })

              expect(maximizer.solution.indeterminate_expected_indexes).not_to include(1)
              expect(maximizer.solution.indeterminate_actual_indexes).not_to include(0)
            end

            it 'includes indexes that have multiple matches' do
              maximizer = PairingsMaximizer.new({ 0 => [0, 2], 1 => [0, 2], 2 => [] },
                                                { 0 => [0, 1], 1 => [], 2 => [0, 1] })

              expect(maximizer.solution.indeterminate_expected_indexes).to include(0, 1)
              expect(maximizer.solution.indeterminate_actual_indexes).to include(0, 2)
            end

            it 'includes indexes that have one match which has multiple matches' do
              maximizer = PairingsMaximizer.new({ 0 => [0], 1 => [0], 2 => [1, 2] },
                                                { 0 => [0, 1], 1 => [2], 2 => [2] })

              expect(maximizer.solution.indeterminate_expected_indexes).to include(0, 1)
              expect(maximizer.solution.indeterminate_actual_indexes).to include(1, 2)
            end
          end

          describe "#unmatched_item_count" do
            it 'returns the count of unmatched items' do
              maximizer = PairingsMaximizer.new({ 0 => [1], 1 => [0] },
                                                { 0 => [1], 1 => [0] })
              expect(maximizer.solution.unmatched_item_count).to eq(0)

              maximizer = PairingsMaximizer.new({ 0 => [1], 1 => [0] },
                                                { 0 => [1], 1 => [0], 2 => [] })
              expect(maximizer.solution.unmatched_item_count).to eq(1)
            end
          end

          describe "#find_best_solution" do
            matcher :produce_result do |unmatched_expected, unmatched_actual|
              match do |result|
                result.candidate? &&
                result.unmatched_expected_indexes == unmatched_expected &&
                result.unmatched_actual_indexes   == unmatched_actual
              end

              failure_message do |result|
                if result.candidate_result?
                  "expected a complete solution, but still had indeterminate indexes: " \
                  "expected: #{result.indeterminate_expected_indexes.inspect}; " \
                  "actual: #{result.indeterminate_actual_indexes.inspect}"
                elsif result.unmatched_expected_indexes != unmatched_expected
                  "expected unmatched_expected_indexes: #{unmatched_expected.inspect} " \
                  "but got: #{result.unmatched_expected_indexes.inspect}"
                elsif result.unmatched_actual_indexes != unmatched_actual
                  "expected unmatched_actual_indexes: #{unmatched_actual.inspect} " \
                  "but got: #{result.unmatched_actual_indexes.inspect}"
                end
              end
            end

            it 'returns no unmatched indexes when everything reciprocally matches one item' do
              maximizer = PairingsMaximizer.new({ 0 => [1], 1 => [0] },
                                                { 0 => [1], 1 => [0] })
              expect(maximizer.find_best_solution).to produce_result([], [])
            end

            it 'returns unmatched indexes for everything that has no matches' do
              maximizer = PairingsMaximizer.new({ 0 => [], 1 => [0] },
                                                { 0 => [1], 1 => [] })
              expect(maximizer.find_best_solution).to produce_result([0], [1])
            end

            it 'searches the solution space for a perfectly matching solution' do
              maximizer = PairingsMaximizer.new({ 0 => [0, 1], 1 => [0] },
                                                { 0 => [0, 1], 1 => [0] })
              expect(maximizer.find_best_solution).to produce_result([], [])
            end
          end
        end
      end
    end
  end
end
