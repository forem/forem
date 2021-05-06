require "rails_helper"

RSpec.describe "Metrics Overview task", type: :task do
  before do
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  describe "#overview" do
    let(:event_name) { "Admin Overview Link Clicked" }
    let(:click_target) { "https://forem.gitbook.io/forem-admin-guide/quick-start-guide" }
    let(:host) { ENV["APP_DOMAIN"] }

    it "returns the event count and target for admin overview events" do
      create(:ahoy_event, name: event_name, properties: {
               action: "click", target: click_target
             })

      expect { Rake::Task["metrics:overview"].invoke }.to output(
        "Admin Overview Link Tracking for #{host}:\n#{click_target}: 1\n",
      ).to_stdout
    end
  end
end
