# fake class to make tests pass and to avoid require 'test/unit/testcase' to not break RSpec
# https://www.rubydoc.info/gems/test-unit/3.4.1/Test/Unit/TestSuite
module Test
  module Unit
    class TestSuite
    end
  end
end

describe KnapsackPro::Adapters::TestUnitAdapter do
  it do
    expect(described_class::TEST_DIR_PATTERN).to eq 'test/**{,/*/**}/*_test.rb'
  end

  describe '.test_path' do
    subject { described_class.test_path(obj) }

    before do
      parent_of_test_dir = File.expand_path('../../../', File.dirname(__FILE__))
      described_class.class_variable_set(:@@parent_of_test_dir, parent_of_test_dir)
    end

    context 'when regular test' do
      class FakeTestUnitTest
        def method_name
          "test_something"
        end

        def test_something
        end
      end

      class FakeTestUnitTestSuite
        def tests
          [FakeTestUnitTest.new]
        end
      end

      let(:obj) { FakeTestUnitTestSuite.new }

      it { should eq './spec/knapsack_pro/adapters/test_unit_adapter_spec.rb' }
    end
  end

  describe 'bind methods' do
    describe '#bind_time_tracker' do
      let(:logger) { instance_double(Logger) }
      let(:global_time) { 'Global time: 01m 05s' }

      it do
        expect(Test::Unit::TestSuite).to receive(:send).with(:prepend, KnapsackPro::Adapters::TestUnitAdapter::BindTimeTrackerTestUnitPlugin)

        expect(subject).to receive(:add_post_run_callback).and_yield

        expect(KnapsackPro::Presenter).to receive(:global_time).and_return(global_time)
        expect(KnapsackPro).to receive(:logger).and_return(logger)
        expect(logger).to receive(:debug).with(global_time)

        subject.bind_time_tracker
      end
    end

    describe '#bind_save_report' do
      it do
        expect(subject).to receive(:add_post_run_callback).and_yield

        expect(KnapsackPro::Report).to receive(:save)

        subject.bind_save_report
      end
    end
  end

  describe '#set_test_helper_path' do
    let(:adapter) { described_class.new }
    let(:test_helper_path) { '/code/project/test/test_helper.rb' }

    subject { adapter.set_test_helper_path(test_helper_path) }

    after do
      expect(described_class.class_variable_get(:@@parent_of_test_dir)).to eq '/code/project'
    end

    it { should eql '/code/project' }
  end
end
