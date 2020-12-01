RSpec.describe RSpec::Mocks::Double do

  let(:obj) { double }

  describe "#and_yield" do
    context 'when the method double has been constrained by `with`' do
      it 'uses the default stub if the provided args do not match' do
        allow(obj).to receive(:foo) { 15 }
        allow(obj).to receive(:foo).with(:yield).and_yield

        # should_receive is required to trigger the bug:
        # https://github.com/rspec/rspec-mocks/issues/127
        expect(obj).to receive(:foo)

        expect(obj.foo(:dont_yield)).to eq(15)
      end
    end

    context "with eval context as block argument" do

      it "evaluates the supplied block as it is read" do
        evaluated = false
        allow(obj).to receive(:method_that_accepts_a_block).and_yield do |_eval_context|
          evaluated = true
        end
        expect(evaluated).to be_truthy
      end

      it "passes an eval context object to the supplied block" do
        allow(obj).to receive(:method_that_accepts_a_block).and_yield do |eval_context|
          expect(eval_context).not_to be_nil
        end
      end

      it "evaluates the block passed to the stubbed method in the context of the supplied eval context" do
        expected_eval_context = nil
        actual_eval_context = nil

        allow(obj).to receive(:method_that_accepts_a_block).and_yield do |eval_context|
          expected_eval_context = eval_context
        end

        obj.method_that_accepts_a_block do
          actual_eval_context = self
        end

        expect(actual_eval_context).to equal(expected_eval_context)
      end

      context "and no yielded arguments" do

        it "passes when expectations set on the eval context are met" do
          configured_eval_context = nil
          allow(obj).to receive(:method_that_accepts_a_block).and_yield do |eval_context|
            configured_eval_context = eval_context
            expect(configured_eval_context).to receive(:foo)
          end

          obj.method_that_accepts_a_block do
            foo
          end

          verify configured_eval_context
        end

        it "fails when expectations set on the eval context are not met" do
          configured_eval_context = nil
          allow(obj).to receive(:method_that_accepts_a_block).and_yield do |eval_context|
            configured_eval_context = eval_context
            expect(configured_eval_context).to receive(:foo)
          end

          obj.method_that_accepts_a_block do
            # foo is not called here
          end

          expect { verify configured_eval_context }.to fail
        end

      end

      context "and yielded arguments" do

        it "passes when expectations set on the eval context and yielded arguments are met" do
          configured_eval_context = nil
          yielded_arg = Object.new
          allow(obj).to receive(:method_that_accepts_a_block).and_yield(yielded_arg) do |eval_context|
            configured_eval_context = eval_context
            expect(configured_eval_context).to receive(:foo)
            expect(yielded_arg).to receive(:bar)
          end

          obj.method_that_accepts_a_block do |object|
            object.bar
            foo
          end

          verify configured_eval_context
          verify yielded_arg
        end

        context "that are optional", :if => RSpec::Support::RubyFeatures.optional_and_splat_args_supported? do
          it "yields the default argument when the argument is not given" do
            pending "Not sure how to achieve this yet. See rspec/rspec-mocks#714 and rspec/rspec-support#85."
            default_arg = Object.new
            object = Object.new

            allow(object).to receive(:a_message).and_yield
            expect(default_arg).to receive(:bar)

            eval("object.a_message { |receiver=default_arg| receiver.bar }")
          end

          it "yields given argument when the argument is given" do
            default_arg = Object.new
            allow(default_arg).to receive(:bar)

            given_arg = Object.new
            object = Object.new

            allow(object).to receive(:a_message).and_yield(given_arg)
            expect(given_arg).to receive(:bar)

            eval("object.a_message { |receiver=default_arg| receiver.bar }")
          end
        end

        it 'can yield to a block that uses `super`' do
          klass    = Class.new { def foo; 13; end }
          subklass = Class.new(klass) { def foo(arg); arg.bar { super() }; end }

          arg = double
          expect(arg).to receive(:bar).and_yield

          instance = subklass.new
          instance.foo(arg)
        end

        it "fails when expectations set on the eval context and yielded arguments are not met" do
          configured_eval_context = nil
          yielded_arg = Object.new
          allow(obj).to receive(:method_that_accepts_a_block).and_yield(yielded_arg) do |eval_context|
            configured_eval_context = eval_context
            expect(configured_eval_context).to receive(:foo)
            expect(yielded_arg).to receive(:bar)
          end

          obj.method_that_accepts_a_block do |_obj|
            # _obj.bar is not called here
            # foo is not called here
          end

          expect { verify configured_eval_context }.to fail
          expect { verify yielded_arg }.to fail
        end
      end
    end
  end
end
