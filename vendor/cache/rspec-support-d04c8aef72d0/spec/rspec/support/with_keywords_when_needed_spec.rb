require 'rspec/support/with_keywords_when_needed'

module RSpec::Support
  RSpec.describe "WithKeywordsWhenNeeded" do

    describe ".class_exec" do
      extend RubyFeatures

      let(:klass) do
        Class.new do
          def self.check_argument(argument)
            raise ArgumentError unless argument == 42
          end
        end
      end

      def run(klass, *args, &block)
        WithKeywordsWhenNeeded.class_exec(klass, *args, &block)
      end

      it "will run a block without keyword arguments" do
        run(klass, 42) { |arg| check_argument(arg) }
      end

      it "will run a block with a hash without keyword arguments" do
        run(klass, "value" => 42) { |arg| check_argument(arg["value"]) }
      end

      it "will run a block with optional keyword arguments when none are provided", :if => kw_args_supported? do
        binding.eval(<<-CODE, __FILE__, __LINE__)
        run(klass, 42) { |arg, val: nil| check_argument(arg) }
        CODE
      end

      it "will run a block with optional keyword arguments when they are provided", :if => required_kw_args_supported? do
        binding.eval(<<-CODE, __FILE__, __LINE__)
        run(klass, val: 42) { |val: nil| check_argument(val) }
        CODE
      end

      it "will run a block with required keyword arguments", :if => required_kw_args_supported? do
        binding.eval(<<-CODE, __FILE__, __LINE__)
        run(klass, val: 42) { |val:| check_argument(val) }
        CODE
      end
    end
  end
end
