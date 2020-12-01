module RSpec
  RSpec.describe Matchers, "aliases", :order => :defined do
    matcher :be_aliased_to do |old_matcher|
      chain :with_description do |desc|
        @expected_desc = desc
      end

      match do |aliased_matcher|
        @actual_desc = aliased_matcher.description

        @actual_desc == @expected_desc &&
        aliased_matcher.base_matcher.class == old_matcher.class
      end

      failure_message do |aliased_matcher|
        "expected #{aliased_matcher} to be aliased to #{old_matcher} with " \
        "description: #{@expected_desc.inspect}, but got #{@actual_desc.inspect}"
      end

      description do |_aliased_matcher|
        "have an alias for #{old_matcher.description.inspect} with description: #{@expected_desc.inspect}"
      end
    end

    specify do
      expect(a_truthy_value).to be_aliased_to(be_truthy).with_description("a truthy value")
    end

    specify do
      expect(a_falsey_value).to be_aliased_to(be_falsey).with_description("a falsey value")
    end

    specify do
      expect(be_falsy).to be_aliased_to(be_falsey).with_description("be falsy")
    end

    specify do
      expect(a_falsy_value).to be_aliased_to(be_falsey).with_description("a falsy value")
    end

    specify do
      expect(a_nil_value).to be_aliased_to(be_nil).with_description("a nil value")
    end

    specify do
      expect(a_value > 3).to be_aliased_to(be > 3).with_description("a value > 3")
    end

    specify do
      expect(a_value < 3).to be_aliased_to(be < 3).with_description("a value < 3")
    end

    specify do
      expect(a_value <= 3).to be_aliased_to(be <= 3).with_description("a value <= 3")
    end

    specify do
      expect(a_value == 3).to be_aliased_to(be == 3).with_description("a value == 3")
    end

    specify do
      expect(a_value === 3).to be_aliased_to(be === 3).with_description("a value === 3")
    end

    specify do
      expect(
        an_instance_of(Integer)
      ).to be_aliased_to(
        be_an_instance_of(Integer)
      ).with_description("an instance of Integer")
    end

    specify do
      expect(
        a_kind_of(Integer)
      ).to be_aliased_to(
        be_a_kind_of(Integer)
      ).with_description("a kind of Integer")
    end

    specify do
      expect(
        a_value_between(1, 10)
      ).to be_aliased_to(
        be_between(1, 10)
      ).with_description("a value between 1 and 10 (inclusive)")
    end

    specify do
      expect(
        a_value_within(0.1).of(3)
      ).to be_aliased_to(
        be_within(0.1).of(3)
      ).with_description("a value within 0.1 of 3")
    end

    specify do
      expect(
        within(0.1).of(3)
      ).to be_aliased_to(
        be_within(0.1).of(3)
      ).with_description("within 0.1 of 3")
    end

    specify do
      expect(a_block_changing).to be_aliased_to(change).with_description("a block changing result")
    end

    specify do
      expect(changing).to be_aliased_to(change).with_description("changing result")
    end

    specify do
      expect(
        a_collection_containing_exactly(1, 2)
      ).to be_aliased_to(
        contain_exactly(1, 2)
      ).with_description("a collection containing exactly 1 and 2")
    end

    specify do
      expect(
        containing_exactly(1, 2)
      ).to be_aliased_to(
        contain_exactly(1, 2)
      ).with_description("containing exactly 1 and 2")
    end

    specify do
      expect(
        a_range_covering(1, 2)
      ).to be_aliased_to(
        cover(1, 2)
      ).with_description("a range covering 1 and 2")
    end

    specify do
      expect(
        covering(1, 2)
      ).to be_aliased_to(
        cover(1, 2)
      ).with_description("covering 1 and 2")
    end

    specify do
      expect(
        ending_with(23)
      ).to be_aliased_to(
        end_with(23)
      ).with_description("ending with 23")
    end

    specify do
      expect(
        a_collection_ending_with(23)
      ).to be_aliased_to(
        end_with(23)
      ).with_description("a collection ending with 23")
    end

    specify do
      expect(
        a_string_ending_with("z")
      ).to be_aliased_to(
        end_with("z")
      ).with_description('a string ending with "z"')
    end

    specify do
      expect(
        an_object_eq_to(3)
      ).to be_aliased_to(eq 3).with_description("an object eq to 3")
    end

    specify do
      expect(
        eq_to(3)
      ).to be_aliased_to(eq 3).with_description("eq to 3")
    end

    specify do
      expect(
        an_object_eql_to(3)
      ).to be_aliased_to(eql 3).with_description("an object eql to 3")
    end

    specify do
      expect(
        eql_to(3)
      ).to be_aliased_to(eql 3).with_description("eql to 3")
    end

    specify do
      expect(
        an_object_equal_to(3)
      ).to be_aliased_to(equal 3).with_description("an object equal to 3")
    end

    specify do
      expect(
        equal_to(3)
      ).to be_aliased_to(equal 3).with_description("equal to 3")
    end

    specify do
      expect(
        an_object_existing
      ).to be_aliased_to(exist).with_description("an object existing")
    end

    specify do
      expect(existing).to be_aliased_to(exist).with_description("existing")
    end

    specify do
      expect(
          an_object_having_attributes(:age => 32)
      ).to be_aliased_to(
          have_attributes(:age => 32)
      ).with_description("an object having attributes {:age => 32}")
    end

    specify do
      expect(
        having_attributes(:age => 32)
      ).to be_aliased_to(
        have_attributes(:age => 32)
      ).with_description("having attributes {:age => 32}")
    end

    specify do
      expect(
        a_string_including("a")
      ).to be_aliased_to(
        include("a")
      ).with_description('a string including "a"')
    end

    specify do
      expect(
        a_collection_including("a")
      ).to be_aliased_to(
        include("a")
      ).with_description('a collection including "a"')
    end

    specify do
      expect(
        a_hash_including(:a => 5)
      ).to be_aliased_to(
        include(:a => 5)
      ).with_description('a hash including {:a => 5}')
    end

    specify do
      expect(
        including(3)
      ).to be_aliased_to(
        include(3)
      ).with_description('including 3')
    end

    specify do
      expect(
        a_string_matching(/foo/)
      ).to be_aliased_to(
        match(/foo/)
      ).with_description('a string matching /foo/')
    end

    specify do
      expect(
        an_object_matching(/foo/)
      ).to be_aliased_to(
        match(/foo/)
      ).with_description('an object matching /foo/')
    end

    specify do
      expect(
        match_regex(/foo/)
      ).to be_aliased_to(
        match(/foo/)
      ).with_description('match regex /foo/')
    end

    specify do
      expect(
        matching(/foo/)
      ).to be_aliased_to(
        match(/foo/)
      ).with_description('matching /foo/')
    end

    specify do
      expect(
        a_block_outputting('foo').to_stdout
      ).to be_aliased_to(
        output('foo').to_stdout
      ).with_description('a block outputting "foo" to stdout')
    end

    specify do
      expect(
        a_block_outputting('foo').to_stderr
      ).to be_aliased_to(
        output('foo').to_stderr
      ).with_description('a block outputting "foo" to stderr')
    end

    specify do
      expect(
        a_block_raising(ArgumentError)
      ).to be_aliased_to(
        raise_error(ArgumentError)
      ).with_description('a block raising ArgumentError')
    end

    specify do
      expect(
        raising(ArgumentError)
      ).to be_aliased_to(
        raise_error(ArgumentError)
      ).with_description("raising ArgumentError")
    end

    specify do
      expect(
        an_object_responding_to(:foo)
      ).to be_aliased_to(
        respond_to(:foo)
      ).with_description("an object responding to #foo")
    end

    specify do
      expect(
        responding_to(:foo)
      ).to be_aliased_to(
        respond_to(:foo)
      ).with_description("responding to #foo")
    end

    specify do
      expect(
        an_object_satisfying {}
      ).to be_aliased_to(
        satisfy {}
      ).with_description("an object satisfying block")
    end

    specify do
      expect(
        satisfying {}
      ).to be_aliased_to(
        satisfy {}
      ).with_description("satisfying block")
    end

    specify do
      expect(
        a_collection_starting_with(23)
      ).to be_aliased_to(
        start_with(23)
      ).with_description("a collection starting with 23")
    end

    specify do
      expect(
        a_string_starting_with("z")
      ).to be_aliased_to(
        start_with("z")
      ).with_description('a string starting with "z"')
    end

    specify do
      expect(
        starting_with("d")
      ).to be_aliased_to(
        start_with("d")
      ).with_description('starting with "d"')
    end

    specify do
      expect(
        a_block_throwing(:foo)
      ).to be_aliased_to(
        throw_symbol(:foo)
      ).with_description("a block throwing :foo")
    end

    specify do
      expect(
        throwing(:foo)
      ).to be_aliased_to(
        throw_symbol(:foo)
      ).with_description("throwing :foo")
    end

    specify do
      expect(
        a_block_yielding_control
      ).to be_aliased_to(
        yield_control
      ).with_description("a block yielding control")
    end

    specify do
      expect(
        yielding_control
      ).to be_aliased_to(
        yield_control
      ).with_description("yielding control")
    end

    specify do
      expect(
        a_block_yielding_with_no_args
      ).to be_aliased_to(
        yield_with_no_args
      ).with_description("a block yielding with no args")
    end

    specify do
      expect(
        yielding_with_no_args
      ).to be_aliased_to(
        yield_with_no_args
      ).with_description("yielding with no args")
    end

    specify do
      expect(
        a_block_yielding_with_args
      ).to be_aliased_to(
        yield_with_args
      ).with_description("a block yielding with args")
    end

    specify do
      expect(
        yielding_with_args
      ).to be_aliased_to(
        yield_with_args
      ).with_description("yielding with args")
    end

    specify do
      expect(
        a_block_yielding_successive_args
      ).to be_aliased_to(
        yield_successive_args
      ).with_description("a block yielding successive args()")
    end

    specify do
      expect(
        yielding_successive_args
      ).to be_aliased_to(
        yield_successive_args
      ).with_description("yielding successive args()")
    end
  end
end
