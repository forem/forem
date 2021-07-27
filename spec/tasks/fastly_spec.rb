require "task_helper"

RSpec.describe "Fastly tasks", type: :task do
  describe "#update_configs" do
    it "doesn't run if Fastly isn't configured" do
      %w[FASTLY_API_KEY FASTLY_SERVICE_ID].each do |var|
        allow(ApplicationConfig).to receive(:[]).with(var).and_return(nil)
      end
      allow(FastlyConfig::Update).to receive(:call)

      Rake::Task["fastly:update_configs"].invoke

      expect(FastlyConfig::Update).not_to have_received(:call)
    end
  end
end
