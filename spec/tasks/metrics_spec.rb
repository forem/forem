require "rails_helper"

RSpec.describe "Metrics Overview task", type: :task do
  before { Rake.application["fastly:update_configs"].reenable }

  describe "#overview" do
    let(:event_name) { "Admin Overview Link Clicked" }
    let(:click_target) { "https://admin.forem.com/docs/quick-start-guide" }
    let(:host) { ENV.fetch("APP_DOMAIN", nil) }

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
