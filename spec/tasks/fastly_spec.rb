require "rails_helper"

RSpec.describe "Fastly tasks", type: :task do
  before do
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  describe "#update_safe_params" do
    it "doesn't run if Fastly isn't configured" do
      %w[FASTLY_API_KEY FASTLY_SERVICE_ID FASTLY_SAFE_PARAMS_SNIPPET_NAME].each do |var|
        allow(ApplicationConfig).to receive(:[]).with(var).and_return(nil)
      end
      allow(FastlyVCL::SafeParams).to receive(:update)

      Rake::Task["fastly:update_safe_params"].invoke

      expect(FastlyVCL::SafeParams).not_to have_received(:update)
    end
  end
end
