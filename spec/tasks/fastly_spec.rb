require "rails_helper"

RSpec.describe "Fastly tasks", type: :task do
  before do
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  describe "#update_whitelisted_params" do
    it "doesn't run if Fastly isn't configured" do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_WHITELIST_PARAMS_SNIPPET_NAME").and_return(nil)
      allow(FastlyVCL::WhitelistedParams).to receive(:update)
      Rake::Task["fastly:update_whitelisted_params"].invoke
      expect(FastlyVCL::WhitelistedParams).not_to have_received(:update)
    end
  end
end
