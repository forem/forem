require "singleton"
require "spec_helper"

RSpec.describe Timber::Config, :rails_23 => true do
  let(:config) { Timber::Config.send(:new) }

  describe ".logrageify!" do
    it "should logrageify!" do
      expect(Timber::Integrations::ActionController.silence?).to eq(false)
      expect(Timber::Integrations::ActionView.silence?).to eq(false)
      expect(Timber::Integrations::ActiveRecord.silence?).to eq(false)
      expect(Timber::Integrations::Rack::HTTPEvents.collapse_into_single_event?).to eq(false)


      config.logrageify!

      expect(Timber::Integrations::ActionController.silence?).to eq(true)
      expect(Timber::Integrations::ActionView.silence?).to eq(true)
      expect(Timber::Integrations::ActiveRecord.silence?).to eq(true)
      expect(Timber::Integrations::Rack::HTTPEvents.collapse_into_single_event?).to eq(true)


      # Reset
      Timber::Integrations::ActionController.silence = false
      Timber::Integrations::ActionView.silence = false
      Timber::Integrations::ActiveRecord.silence = false
      Timber::Integrations::Rack::HTTPEvents.collapse_into_single_event = false
    end
  end
end
