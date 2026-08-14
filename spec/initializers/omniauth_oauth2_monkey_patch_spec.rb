require 'rails_helper'

RSpec.describe OmniAuth::Strategies::OAuth2 do
  let(:app) { ->(_env) { [200, {}, ["Hello."]] } }
  let(:strategy) { described_class.new(app) }
  
  describe "#callback_phase" do
    context "when original_callback_phase raises NoMethodError for expired? on nil" do
      before do
        allow(strategy).to receive(:original_callback_phase).and_raise(NoMethodError.new("undefined method `expired?' for nil:NilClass"))
        allow(strategy).to receive(:fail!)
      end

      it "rescues the error and calls fail! with :invalid_credentials" do
        strategy.callback_phase
        
        expect(strategy).to have_received(:fail!).with(:invalid_credentials, instance_of(StandardError))
      end
    end

    context "when original_callback_phase raises a different NoMethodError" do
      before do
        allow(strategy).to receive(:original_callback_phase).and_raise(NoMethodError.new("undefined method `foo' for nil:NilClass"))
        allow(strategy).to receive(:fail!)
      end

      it "re-raises the error" do
        expect { strategy.callback_phase }.to raise_error(NoMethodError, "undefined method `foo' for nil:NilClass")
        expect(strategy).not_to have_received(:fail!)
      end
    end

    context "when no error is raised" do
      before do
        allow(strategy).to receive(:original_callback_phase).and_return("success")
        allow(strategy).to receive(:fail!)
      end

      it "returns the result from original_callback_phase" do
        expect(strategy.callback_phase).to eq("success")
        expect(strategy).not_to have_received(:fail!)
      end
    end
  end
end
