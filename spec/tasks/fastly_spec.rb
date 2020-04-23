require "rails_helper"

RSpec.describe "Fastly tasks", type: :task do
  before do
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  # TODO: [SRE] Using exit (called in the rake task) breaks RSpec in Travis by
  # passing a build even when specs fail. We need to find something to replace
  # the use of exit or change this spec.
  xdescribe "#update_safe_params" do
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
