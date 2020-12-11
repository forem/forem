module YieldHelpers
  # these helpers are prefixed with an underscore to prevent
  # collisions with the matchers (some of which have the same names)
  def _dont_yield
  end

  def _yield_with_no_args
    yield
  end

  def _yield_with_args(*args)
    yield(*args)
  end
end

class InstanceEvaler
  def yield_with_no_args(&block)
    instance_exec(&block)
  end

  def yield_with_args(*args, &block)
    instance_exec(*args, &block)
  end

  def each_arg(*args, &block)
    args.each do |arg|
      instance_exec(arg, &block)
    end
  end
end

RSpec.describe "yield_control matcher" do
  include YieldHelpers
  extend  YieldHelpers

  it_behaves_like "an RSpec matcher",
      :valid_value => lambda { |b| _yield_with_no_args(&b) },
      :invalid_value => lambda { |b| _dont_yield(&b) },
      :failure_message_uses_no_inspect => true do
    let(:matcher) { yield_control }
  end

  it 'has a description' do
    expect(yield_control.description).to eq("yield control")
  end

  describe "expect {...}.to yield_control" do
    it 'passes if the block yields, regardless of the number of yielded arguments or the number of yields' do
      expect { |b| _yield_with_no_args(&b) }.to yield_control
      expect { |b| _yield_with_args(1, 2, &b) }.to yield_control
      expect { |b| 1.upto(10, &b) }.to yield_control
    end

    it 'passes if the block yields using instance_exec' do
      expect { |b| InstanceEvaler.new.yield_with_no_args(&b) }.to yield_control
    end

    it 'fails if the block does not yield' do
      expect {
        expect { |b| _dont_yield(&b) }.to yield_control
      }.to fail_with(/expected given block to yield control but/)
    end

    it 'fails if the block does not yield the correct number of times' do
      expect {
        expect { |b| 0.times.each(&b) }.to yield_control.at_least(:once)
      }.to fail_with(/expected given block to yield control at least once but did not yield/)

      expect {
        expect { |b| 2.times.each(&b) }.to yield_control.at_most(:once)
      }.to fail_with(/expected given block to yield control at most once but yielded twice/)

      expect {
        expect { |b| 1.times.each(&b) }.to yield_control.at_least(:twice)
      }.to fail_with(/expected given block to yield control at least twice but yielded once/)

      expect {
        expect { |b| 3.times.each(&b) }.to yield_control.at_least(:once).at_most(2)
      }.to fail_with(/expected given block to yield control between 1 and 2 times but yielded 3 times/)

      expect {
        expect { |b| 0.times.each(&b) }.to yield_control
      }.to fail_with(/expected given block to yield control but did not yield/)
    end

    it 'does not return a meaningful value from the block' do
      val = nil
      expect { |b| val = _yield_with_args(&b) }.to yield_control
      expect(val).to be_nil
    end

    it 'raises an error if given an invalid count argument' do
      expect { yield_control.exactly('2') }.to raise_error(ArgumentError)
      expect { yield_control.at_least(:trice_with_typo) }.to raise_error(ArgumentError)
      expect { yield_control.at_most(nil) }.to raise_error(ArgumentError)
      expect { yield_control.at_least(2).at_least(1) }.to raise_error(ArgumentError)
      expect { yield_control.at_most(2).at_most(1) }.to raise_error(ArgumentError)
      expect { yield_control.at_most(2).at_least(1).at_most(1) }.to raise_error(ArgumentError)
      expect { yield_control.at_most(1).at_least(2) }.to raise_error(ArgumentError)
      expect { yield_control.at_least(2).at_most(1) }.to raise_error(ArgumentError)
    end

    it 'is supports multiple calls to compatible count constraints' do
      expect { |b| 1.upto(4, &b) }.to yield_control.at_least(3).at_most(4).times
      expect { |b| 1.upto(2, &b) }.not_to yield_control.at_least(3).at_most(4).times
    end

    it 'raises an error on multiple incompatible calls to count constraints' do
      expect { yield_control.once.twice }.to raise_error(/multiple/i)
    end

    context "with exact count" do
      it 'fails if the block yields wrong number of times' do
        expect {
          expect { |b| [1, 2].each(&b) }.to yield_control.once
        }.to fail_with(/expected given block to yield control once but yielded twice/)

        expect {
          expect { |b| [1, 2, 3].each(&b) }.to yield_control.twice
        }.to fail_with(/expected given block to yield control twice but yielded 3 times/)

        expect {
          expect { |b| [1, 2].each(&b) }.to yield_control.thrice
        }.to fail_with(/expected given block to yield control 3 times/)
      end

      it 'passes if the block yields the specified number of times' do
        expect { |b| [1].each(&b) }.to yield_control.once
        expect { |b| [1, 2].each(&b) }.to yield_control.twice
        expect { |b| [1, 2, 3].each(&b) }.to yield_control.thrice
        expect { |b| [1, 2, 3, 4].each(&b) }.to yield_control.exactly(4).times
      end
    end

    context "with at_least count" do
      it 'passes if the block yields the given number of times' do
        expect { |b| [1, 2].each(&b) }.to yield_control.at_least(2).times
        expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_least(3).times
      end

      it 'passes if the block yields more times' do
        expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_least(2).times
        expect { |b| [1, 2, 3, 4].each(&b) }.to yield_control.at_least(3).times
      end

      it 'allows :once, :twice, and :thrice to be passed as counts' do
        expect { |b| [1].each(&b) }.to yield_control.at_least(:once)
        expect { |b| [1, 2].each(&b) }.to yield_control.at_least(:once)

        expect {
          expect { |b| [].each(&b) }.to yield_control.at_least(:once)
        }.to fail_with(/at least once/)

        expect { |b| [1, 2].each(&b) }.to yield_control.at_least(:twice)
        expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_least(:twice)

        expect {
          expect { |b| [1].each(&b) }.to yield_control.at_least(:twice)
        }.to fail_with(/at least twice/)

        expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_least(:thrice)
        expect { |b| [1, 2, 3, 4].each(&b) }.to yield_control.at_least(:thrice)

        expect {
          expect { |b| [1, 2].each(&b) }.to yield_control.at_least(:thrice)
        }.to fail_with(/at least 3 times/)
      end

      it 'fails if the block yields too few times' do
        expect {
          expect { |b| _yield_with_no_args(&b) }.to yield_control.at_least(2).times
        }.to fail_with(/expected given block to yield control at least twice/)
      end
    end

    context "with at_most count" do
      it 'passes if the block yields the given number of times' do
        expect { |b| [1, 2].each(&b) }.to yield_control.at_most(2).times
        expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_most(3).times
      end

      it 'passes if the block yields fewer times' do
        expect { |b| [1, 2].each(&b) }.to yield_control.at_most(3).times
      end

      it 'allows :once, :twice, and :thrice to be passed as counts' do
        expect { |b| [1].each(&b) }.to yield_control.at_most(:once)

        expect {
          expect { |b| [1, 2].each(&b) }.to yield_control.at_most(:once)
        }.to fail_with(/expected given block to yield control at most once/)

        expect { |b| [1, 2].each(&b) }.to yield_control.at_most(:twice)

        expect {
          expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_most(:twice)
        }.to fail_with(/expected given block to yield control at most twice/)

        expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_most(:thrice)

        expect {
          expect { |b| [1, 2, 3, 4].each(&b) }.to yield_control.at_most(:thrice)
        }.to fail_with(/expected given block to yield control at most 3 times/)
      end

      it 'fails if the block yields too many times' do
        expect {
          expect { |b| [1, 2, 3].each(&b) }.to yield_control.at_most(2).times
        }.to fail_with(/expected given block to yield control at most twice/)
      end
    end
  end

  describe "expect {...}.not_to yield_control" do
    it 'passes if the block does not yield' do
      expect { |b| _dont_yield(&b) }.not_to yield_control
    end

    it 'fails if the block does yield' do
      expect {
        expect { |b| _yield_with_no_args(&b) }.not_to yield_control
      }.to fail_with(/expected given block not to yield control/)
    end

    it 'fails if the expect block does not accept an argument', :if => (RUBY_VERSION.to_f > 1.8) do
      expect {
        expect {}.not_to yield_control
      }.to raise_error(/expect block must accept an argument/)
    end

    it 'still works when the block uses an arg splat' do
      expect { |*args| _dont_yield(&args.first) }.not_to yield_control
    end

    it 'raises an error if the expect block arg is not passed to a method as a block' do
      expect {
        expect { |b| }.not_to yield_control
      }.to raise_error(/must pass the argument.*as a block/)
    end
  end
end

RSpec.describe "yield_with_no_args matcher" do
  include YieldHelpers
  extend  YieldHelpers

  it_behaves_like "an RSpec matcher",
      :valid_value => lambda { |b| _yield_with_no_args(&b) },
      :invalid_value => lambda { |b| _yield_with_args(1, &b) } do
    let(:matcher) { yield_with_no_args }
  end

  it 'has a description' do
    expect(yield_with_no_args.description).to eq("yield with no args")
  end

  it 'does not return a meaningful value from the block' do
    val = nil
    expect { |b| val = _yield_with_no_args(&b) }.to yield_with_no_args
    expect(val).to be_nil
  end

  describe "expect {...}.to yield_with_no_args" do
    it 'passes if the block yields with no args' do
      expect { |b| _yield_with_no_args(&b) }.to yield_with_no_args
    end

    it 'passes if the block yields with no args using instance_exec' do
      expect { |b| InstanceEvaler.new.yield_with_no_args(&b) }.to yield_with_no_args
    end

    it 'fails if the block does not yield' do
      expect {
        expect { |b| _dont_yield(&b) }.to yield_with_no_args
      }.to fail_with(/expected given block to yield with no arguments, but did not yield/)
    end

    it 'fails if the block yields with args' do
      expect {
        expect { |b| _yield_with_args(1, &b) }.to yield_with_no_args
      }.to fail_with(/expected given block to yield with no arguments, but yielded with arguments/)
    end

    it 'fails if the block yields with arg false' do
      expect {
        expect { |b| _yield_with_args(false, &b) }.to yield_with_no_args
      }.to fail_with(/expected given block to yield with no arguments, but yielded with arguments/)
    end

    it 'raises an error if it yields multiple times' do
      expect {
        expect { |b| [1, 2].each(&b) }.to yield_with_no_args
      }.to raise_error(/not designed.*yields multiple times/)
    end
  end

  describe "expect {...}.not_to yield_with_no_args" do
    it "passes if the block does not yield" do
      expect { |b| _dont_yield(&b) }.not_to yield_with_no_args
    end

    it "passes if the block yields with args" do
      expect { |b| _yield_with_args(1, &b) }.not_to yield_with_no_args
    end

    it "fails if the block yields with no args" do
      expect {
        expect { |b| _yield_with_no_args(&b) }.not_to yield_with_no_args
      }.to fail_with(/expected given block not to yield with no arguments, but did/)
    end

    it 'fails if the expect block does not accept an argument', :if => (RUBY_VERSION.to_f > 1.8) do
      expect {
        expect {}.not_to yield_with_no_args
      }.to raise_error(/expect block must accept an argument/)
    end

    it 'raises an error if the expect block arg is not passed to a method as a block' do
      expect {
        expect { |b| }.not_to yield_with_no_args
      }.to raise_error(/must pass the argument.*as a block/)
    end
  end
end

RSpec.describe "yield_with_args matcher" do
  include YieldHelpers
  extend  YieldHelpers

  it_behaves_like "an RSpec matcher",
      :valid_value => lambda { |b| _yield_with_args(1, &b) },
      :invalid_value => lambda { |b| _yield_with_args(2, &b) } do
    let(:matcher) { yield_with_args(1) }
  end

  it 'has a description' do
    expect(yield_with_args.description).to eq("yield with args")
    expect(yield_with_args(1, 3).description).to eq("yield with args(1, 3)")
    expect(yield_with_args(false).description).to eq("yield with args(false)")
  end

  it 'does not return a meaningful value from the block' do
    val = nil
    expect { |b| val = _yield_with_args(1, &b) }.to yield_with_args(1)
    expect(val).to be_nil
  end

  describe "expect {...}.to yield_with_args" do
    it 'passes if the block yields with arguments' do
      expect { |b| _yield_with_args(1, &b) }.to yield_with_args
    end

    it 'passes if the matchers match at yield time only' do
      expect { |b|
        val = []
        _yield_with_args(val, &b)
        val << 1
      }.to yield_with_args(be_empty)
    end

    it 'fails if the block does not yield' do
      expect {
        expect { |b| _dont_yield(&b) }.to yield_with_args
      }.to fail_with(/expected given block to yield with arguments, but did not yield/)
    end

    it 'fails if the block yields with no arguments' do
      expect {
        expect { |b| _yield_with_no_args(&b) }.to yield_with_args
      }.to fail_with(/expected given block to yield with arguments, but yielded with no arguments/)
    end

    it 'fails if the matchers match at return time only' do
      expect {
        expect { |b|
          val = [1]
          _yield_with_args(val, &b)
          val.clear
        }.to yield_with_args(be_empty)
      }.to fail_with(dedent <<-EOS)
        |expected given block to yield with arguments, but yielded with unexpected arguments
        |expected: [(be empty)]
        |     got: [[1]]
      EOS
    end

    it 'raises an error if it yields multiple times' do
      expect {
        expect { |b| [1, 2].each(&b) }.to yield_with_args
      }.to raise_error(/not designed.*yields multiple times/)
    end
  end

  describe "expect {...}.not_to yield_with_args" do
    it 'fails if the block yields with arguments' do
      expect {
        expect { |b| _yield_with_args(1, &b) }.not_to yield_with_args
      }.to fail_with(/expected given block not to yield with arguments, but did/)
    end

    it 'fails if the matchers match at yield time only' do
      expect {
        expect { |b|
          val = []
          _yield_with_args(val, &b)
          val << 1
        }.not_to yield_with_args(be_empty)
      }.to fail_with(dedent <<-EOS)
        |expected given block not to yield with arguments, but yielded with expected arguments
        |expected not: [(be empty)]
        |         got: [[]]
      EOS
    end

    it 'passes if the block does not yield' do
      expect { |b| _dont_yield(&b) }.not_to yield_with_args
    end

    it 'passes if the block yields with no arguments' do
      expect { |b| _yield_with_no_args(&b) }.not_to yield_with_args
    end

    it 'passes if the matchers match at return time only' do
      expect { |b|
        val = [1]
        _yield_with_args(val, &b)
        val.clear
      }.not_to yield_with_args(be_empty)
    end

    it 'fails if the expect block does not accept an argument', :if => (RUBY_VERSION.to_f > 1.8) do
      expect {
        expect {}.not_to yield_with_args
      }.to raise_error(/expect block must accept an argument/)
    end

    it 'raises an error if the expect block arg is not passed to a method as a block' do
      expect {
        expect { |b| }.not_to yield_with_args
      }.to raise_error(/must pass the argument.*as a block/)
    end
  end

  describe "expect {...}.to yield_with_args(3, 17)" do
    it 'passes if the block yields with the given arguments' do
      expect { |b| _yield_with_args(3, 17, &b) }.to yield_with_args(3, 17)
    end

    it 'passes if the block yields with the given arguments using instance_exec' do
      expect { |b| InstanceEvaler.new.yield_with_args(3, 17, &b) }.to yield_with_args(3, 17)
    end

    it 'fails if the block does not yield' do
      expect {
        expect { |b| _dont_yield(&b) }.to yield_with_args(3, 17)
      }.to fail_with(/expected given block to yield with arguments, but did not yield/)
    end

    it 'fails if the block yields with no arguments' do
      expect {
        expect { |b| _yield_with_no_args(&b) }.to yield_with_args(3, 17)
      }.to fail_with(/expected given block to yield with arguments, but yielded with unexpected arguments/)
    end

    it 'fails if the block yields with different arguments' do
      expect {
        expect { |b| _yield_with_args("a", "b", &b) }.to yield_with_args("a", "c")
      }.to fail_with(/expected given block to yield with arguments, but yielded with unexpected arguments/)
    end
  end

  describe "expect {...}.to yield_with_args(matcher, matcher)" do
    it 'passes when the matchers match the args' do
      expect { |b|
        _yield_with_args(1.1, "food", &b)
      }.to yield_with_args(a_value_within(0.2).of(1), a_string_matching(/foo/))
    end

    it 'provides a description' do
      description = yield_with_args(a_value_within(0.2).of(1), a_string_matching(/foo/)).description
      expect(description).to eq("yield with args(a value within 0.2 of 1, a string matching /foo/)")
    end

    it 'fails with a useful error message when the matchers do not match the args' do
      expect {
        expect { |b|
          _yield_with_args(2.1, "food", &b)
        }.to yield_with_args(a_value_within(0.2).of(1), a_string_matching(/foo/))
      }.to fail_with(dedent <<-EOS)
        |expected given block to yield with arguments, but yielded with unexpected arguments
        |expected: [(a value within 0.2 of 1), (a string matching /foo/)]
        |     got: [2.1, "food"]
      EOS
    end
  end

  describe "expect {...}.not_to yield_with_args(3, 17)" do
    it 'passes if the block yields with different arguments' do
      expect { |b| _yield_with_args("a", "b", &b) }.not_to yield_with_args("a", "c")
    end

    it 'fails if the block yields with the given arguments' do
      expect {
        expect { |b| _yield_with_args("a", "b", &b) }.not_to yield_with_args("a", "b")
      }.to fail_with(/expected given block not to yield with arguments, but yielded with expected arguments/)
    end
  end

  describe "expect {...}.not_to yield_with_args(matcher, matcher)" do
    it 'passes when the matchers do not match the args' do
      expect { |b|
        _yield_with_args(2.1, "food", &b)
      }.not_to yield_with_args(a_value_within(0.2).of(1), a_string_matching(/foo/))
    end

    it 'fails with a useful error message when the matchers do not match the args' do
      expect {
        expect { |b|
          _yield_with_args(1.1, "food", &b)
        }.not_to yield_with_args(a_value_within(0.2).of(1), a_string_matching(/foo/))
      }.to fail_with(dedent <<-EOS)
        |expected given block not to yield with arguments, but yielded with expected arguments
        |expected not: [(a value within 0.2 of 1), (a string matching /foo/)]
        |         got: [1.1, "food"]
      EOS
    end
  end

  describe "expect {...}.to yield_with_args( false )" do
    it 'passes if the block yields with the given arguments' do
      expect { |b| _yield_with_args(false, &b) }.to yield_with_args(false)
    end

    it 'passes if the block yields with the given arguments using instance_exec' do
      expect { |b| InstanceEvaler.new.yield_with_args(false, &b) }.to yield_with_args(false)
    end

    it 'fails if the block does not yield' do
      expect {
        expect { |b| _dont_yield(&b) }.to yield_with_args(false)
      }.to fail_with(/expected given block to yield with arguments, but did not yield/)
    end

    it 'fails if the block yields with no arguments' do
      expect {
        expect { |b| _yield_with_no_args(&b) }.to yield_with_args(false)
      }.to fail_with(/expected given block to yield with arguments, but yielded with unexpected arguments/)
    end

    it 'fails if the block yields with different arguments' do
      expect {
        expect { |b| _yield_with_args(false, &b) }.to yield_with_args(true)
      }.to fail_with(/expected given block to yield with arguments, but yielded with unexpected arguments/)
    end
  end

  describe "expect {...}.to yield_with_args(/reg/, /ex/)" do
    it "passes if the block yields strings matching the regexes" do
      expect { |b| _yield_with_args("regular", "expression", &b) }.to yield_with_args(/reg/, /ex/)
    end

    it "fails if the block yields strings that do not match the regexes" do
      expect {
        expect { |b| _yield_with_args("no", "match", &b) }.to yield_with_args(/reg/, /ex/)
      }.to fail_with(/expected given block to yield with arguments, but yielded with unexpected arguments/)
    end
  end

  describe "expect {...}.to yield_with_args(String, Integer)" do
    it "passes if the block yields objects of the given classes" do
      expect { |b| _yield_with_args("string", 15, &b) }.to yield_with_args(String, Integer)
    end

    it "passes if the block yields the given classes" do
      expect { |b| _yield_with_args(String, Integer, &b) }.to yield_with_args(String, Integer)
    end

    it "fails if the block yields objects of different classes" do
      expect {
        expect { |b| _yield_with_args(15, "string", &b) }.to yield_with_args(String, Integer)
      }.to fail_with(/expected given block to yield with arguments, but yielded with unexpected arguments/)
    end
  end
end

RSpec.describe "yield_successive_args matcher" do
  include YieldHelpers
  extend  YieldHelpers

  it_behaves_like "an RSpec matcher",
      :valid_value => lambda { |b| [1, 2].each(&b) },
      :invalid_value => lambda { |b| [3, 4].each(&b) } do
    let(:matcher) { yield_successive_args(1, 2) }
  end

  it 'has a description' do
    expect(yield_successive_args(1, 3).description).to eq("yield successive args(1, 3)")
    expect(yield_successive_args([:a, 1], [:b, 2]).description).to eq("yield successive args([:a, 1], [:b, 2])")
  end

  it 'does not return a meaningful value from the block' do
    val = nil
    expect { |b| val = _yield_with_args(1, &b) }.to yield_successive_args(1)
    expect(val).to be_nil
  end

  it "works correctly when the method yields multiple args each time (passing case)" do
    expect { |block|
      ['football', 'barstool'].each_with_index(&block)
    }.to yield_successive_args(
      [/foo/,                         0],
      [a_string_starting_with('bar'), 1]
    )
  end

  it "works correctly when the method yields multiple args each time (failing case)" do
    expect {
      expect { |block|
        ['football', 'barstool'].each_with_index(&block)
      }.to yield_successive_args(
        [/foo/,                         0],
        [a_string_starting_with('abr'), 1]
      )
    }.to fail_with(dedent <<-EOS)
      |expected given block to yield successively with arguments, but yielded with unexpected arguments
      |expected: [[/foo/, 0], [(a string starting with "abr"), 1]]
      |     got: [["football", 0], ["barstool", 1]]
    EOS
  end

  describe "expect {...}.to yield_successive_args([:a, 1], [:b, 2])" do
    it 'passes when the block successively yields the given args' do
      expect { |b| [[:a, 1], [:b, 2]].each(&b) }.to yield_successive_args([:a, 1], [:b, 2])
    end

    it 'passes if matched at yield time only' do
      expect { |b|
        [[:a, 1], [:b, 2]].each do |val|
          _yield_with_args(val, &b)
          val.clear
        end
      }.to yield_successive_args([:a, 1], [:b, 2])
    end

    it 'fails when the block does not yield that many times' do
      expect {
        expect { |b| [[:a, 1]].each(&b) }.to yield_successive_args([:a, 1], [:b, 2])
      }.to fail_with(/but yielded with unexpected arguments/)
    end

    it 'fails when the block yields the right number of times but with different arguments' do
      expect {
        expect { |b| [[:a, 1], [:b, 3]].each(&b) }.to yield_successive_args([:a, 1], [:b, 2])
      }.to fail_with(/but yielded with unexpected arguments/)
    end

    it 'fails if matched at return time only' do
      expect {
        expect { |b|
          [[:a, 1], [:b, 2]].each do |eventual|
            initial = []
            _yield_with_args(initial, &b)
            initial.concat(eventual)
          end
        }.to yield_successive_args([:a, 1], [:b, 2])
      }.to fail_with(dedent <<-EOS)
        |expected given block to yield successively with arguments, but yielded with unexpected arguments
        |expected: [[:a, 1], [:b, 2]]
        |     got: [[], []]
      EOS
    end
  end

  describe "expect {...}.to yield_successive_args(1, 2, 3)" do
    it 'passes when the block successively yields the given args' do
      expect { |b| [1, 2, 3].each(&b) }.to yield_successive_args(1, 2, 3)
    end

    it 'passes when the block successively yields the given args using instance_exec' do
      expect { |b| InstanceEvaler.new.each_arg(1, 2, 3, &b) }.to yield_successive_args(1, 2, 3)
    end

    it 'fails when the block does not yield the expected args' do
      expect {
        expect { |b| [1, 2, 4].each(&b) }.to yield_successive_args([:a, 1], [:b, 2])
      }.to fail_with(/but yielded with unexpected arguments/)
    end
  end

  describe "expect {...}.to yield_successive_args(matcher, matcher)" do
    it 'passes when the successively yielded args match the matchers' do
      expect { |b|
        %w[ food barn ].each(&b)
      }.to yield_successive_args(a_string_matching(/foo/), a_string_matching(/bar/))
    end

    it 'fails when the successively yielded args do not match the matchers' do
      expect {
        expect { |b|
          %w[ barn food ].each(&b)
        }.to yield_successive_args(a_string_matching(/foo/), a_string_matching(/bar/))
      }.to fail_with(dedent <<-EOS)
        |expected given block to yield successively with arguments, but yielded with unexpected arguments
        |expected: [(a string matching /foo/), (a string matching /bar/)]
        |     got: ["barn", "food"]
      EOS
    end

    it 'provides a description' do
      description = yield_successive_args(a_string_matching(/foo/), a_string_matching(/bar/)).description
      expect(description).to eq("yield successive args(a string matching /foo/, a string matching /bar/)")
    end
  end

  describe "expect {...}.not_to yield_successive_args(1, 2, 3)" do
    it 'passes when the block does not yield' do
      expect { |b| _dont_yield(&b) }.not_to yield_successive_args(1, 2, 3)
    end

    it 'passes when the block yields the wrong number of times' do
      expect { |b| [1, 2].each(&b) }.not_to yield_successive_args(1, 2, 3)
    end

    it 'passes when the block yields the wrong arguments' do
      expect { |b| [1, 2, 4].each(&b) }.not_to yield_successive_args(1, 2, 3)
    end

    it 'fails when the block yields the given arguments' do
      expect {
        expect { |b| [1, 2, 3].each(&b) }.not_to yield_successive_args(1, 2, 3)
      }.to fail_with(/expected given block not to yield successively/)
    end

    it 'fails if the expect block does not accept an argument', :if => (RUBY_VERSION.to_f > 1.8) do
      expect {
        expect {}.not_to yield_successive_args(1, 2, 3)
      }.to raise_error(/expect block must accept an argument/)
    end

    it 'raises an error if the expect block arg is not passed to a method as a block' do
      expect {
        expect { |b| }.not_to yield_successive_args(1, 2, 3)
      }.to raise_error(/must pass the argument.*as a block/)
    end
  end

  describe "expect {...}.not_to yield_successive_args(matcher, matcher)" do
    it 'passes when the successively yielded args do not match the matchers' do
      expect { |b|
        %w[ barn food ].each(&b)
      }.not_to yield_successive_args(a_string_matching(/foo/), a_string_matching(/bar/))
    end

    it 'passes when the successively yielded args do not match the matchers (at yield time only)' do
      expect { |b|
        %w[ food barn ].each do |eventual|
          initial = ''
          _yield_with_args(initial, &b)
          initial << eventual
        end
      }.not_to yield_successive_args(a_string_matching(/foo/), a_string_matching(/bar/))
    end

    it 'fails when the successively yielded args match the matchers' do
      expect {
        expect { |b|
          %w[ food barn ].each(&b)
        }.not_to yield_successive_args(a_string_matching(/foo/), a_string_matching(/bar/))
      }.to fail_with(dedent <<-EOS)
        |expected given block not to yield successively with arguments, but yielded with expected arguments
        |expected not: [(a string matching /foo/), (a string matching /bar/)]
        |         got: ["food", "barn"]
      EOS
    end

    it 'fails when the successively yielded args match the matchers (at yield time only)' do
      values = %w[ food barn ].collect { |value| value.dup }
      expect {
        expect { |b|
          values.each do |val|
            _yield_with_args(val, &b)
            val.sub!(/.+/, '')
          end
        }.not_to yield_successive_args(a_string_matching(/foo/), a_string_matching(/bar/))
      }.to fail_with(dedent <<-EOS)
        |expected given block not to yield successively with arguments, but yielded with expected arguments
        |expected not: [(a string matching /foo/), (a string matching /bar/)]
        |         got: ["food", "barn"]
      EOS
    end
  end

  describe "expect {...}.to yield_successive_args(String, Integer)" do
    it "passes if the block successively yields objects of the given classes" do
      expect { |b| ["string", 15].each(&b) }.to yield_successive_args(String, Integer)
    end

    it "passes if the block yields the given classes" do
      expect { |b| [String, Integer].each(&b) }.to yield_successive_args(String, Integer)
    end

    it "fails if the block yields objects of different classes" do
      expect {
        expect { |b| [15, "string"].each(&b) }.to yield_successive_args(String, Integer)
      }.to fail_with(/expected given block to yield successively with arguments/)
    end
  end
end
