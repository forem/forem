RSpec.describe "an example" do
  context "declared pending with metadata" do
    it "uses the value assigned to :pending as the message" do
      group = RSpec.describe('group') do
        example "example", :pending => 'just because' do
          fail
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with('just because')
    end

    it "sets the message to 'No reason given' if :pending => true" do
      group = RSpec.describe('group') do
        example "example", :pending => true do
          fail
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with('No reason given')
    end

    it "passes if a mock expectation is not satisifed" do
      group = RSpec.describe('group') do
        example "example", :pending => "because" do
          expect(RSpec).to receive(:a_message_in_a_bottle)
        end
      end

      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with('because')
      expect(example.execution_result.status).to eq(:pending)
    end

    it "does not mutate the :pending attribute of the user metadata when handling mock expectation errors" do
      group = RSpec.describe('group') do
        example "example", :pending => "because" do
          expect(RSpec).to receive(:a_message_in_a_bottle)
        end
      end

      group.run
      example = group.examples.first
      expect(example.metadata[:pending]).to be(true)
    end
  end

  context "made pending with `define_derived_metadata`" do
    before do
      RSpec.configure do |config|
        config.define_derived_metadata(:not_ready) do |meta|
          meta[:pending] ||= "Not ready"
        end
      end
    end

    it 'has a pending result if there is an error' do
      group = RSpec.describe "group" do
        example "something", :not_ready do
          boom
        end
      end

      group.run
      example = group.examples.first
      expect(example).to be_pending_with("Not ready")
    end

    it 'fails if there is no error' do
      group = RSpec.describe "group" do
        example "something", :not_ready do
        end
      end

      group.run
      example = group.examples.first
      expect(example.execution_result.status).to be(:failed)
      expect(example.execution_result.exception.message).to include("Expected example to fail")
    end
  end

  context "with no block" do
    it "is listed as pending with 'Not yet implemented'" do
      group = RSpec.describe('group') do
        it "has no block"
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_skipped_with('Not yet implemented')
    end
  end

  context "with no args" do
    it "is listed as pending with the default message" do
      group = RSpec.describe('group') do
        it "does something" do
          pending
          fail
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with(RSpec::Core::Pending::NO_REASON_GIVEN)
    end

    it "fails when the rest of the example passes" do
      called = false
      group = RSpec.describe('group') do
        it "does something" do
          pending
          called = true
        end
      end

      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(called).to eq(true)
      result = example.execution_result
      expect(result.pending_fixed).to eq(true)
      expect(result.status).to eq(:failed)
    end

    it "does not mutate the :pending attribute of the user metadata when the rest of the example passes" do
      group = RSpec.describe('group') do
        it "does something" do
          pending
        end
      end

      group.run
      example = group.examples.first
      expect(example.metadata).to include(:pending => true)
    end
  end

  context "with no docstring" do
    context "declared with the pending method" do
      it "has an auto-generated description if it has an expectation" do
        ex = nil

        RSpec.describe('group') do
          it "checks something" do
            expect((3+4)).to eq(7)
          end
          ex = pending do
            expect("string".reverse).to eq("gnirts")
          end
        end.run

        expect(ex.description).to eq('is expected to eq "gnirts"')
      end
    end

    context "after another example with some assertion" do
      it "does not show any message" do
        ex = nil

        RSpec.describe('group') do
          it "checks something" do
            expect((3+4)).to eq(7)
          end
          ex = specify do
            pending
          end
        end.run

        expect(ex.description).to match(/example at/)
      end
    end
  end

  context "with a message" do
    it "is listed as pending with the supplied message" do
      group = RSpec.describe('group') do
        it "does something" do
          pending("just because")
          fail
        end
      end
      example = group.examples.first
      example.run(group.new, double.as_null_object)
      expect(example).to be_pending_with('just because')
    end
  end

  context "with a block" do
    it "fails with an ArgumentError stating the syntax is deprecated" do
      group = RSpec.describe('group') do
        it "calls pending with a block" do
          pending("with invalid syntax") do
            :no_op
          end
          fail
        end
      end
      example = group.examples.first
      group.run
      expect(example).to fail_with ArgumentError
      expect(example.exception.message).to match(
        /Passing a block within an example is now deprecated./
      )
    end

    it "does not yield to the block" do
      example_to_have_yielded = :did_not_yield
      group = RSpec.describe('group') do
        it "calls pending with a block" do
          pending("just because") do
            example_to_have_yielded = :pending_block
          end
          fail
        end
      end
      group.run
      expect(example_to_have_yielded).to eq :did_not_yield
    end
  end
end
