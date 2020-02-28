require "rails_helper"
require Rails.root.join("app/models/data_update_script.rb")

RSpec.describe DataUpdateWorker, type: :worker do
  let_it_be(:test_directory) { Rails.root.join("spec/support/fixtures/data_update_scripts") }
  let_it_be(:worker) { described_class.new }
  let_it_be(:statuses) { %w[working succeeded] }

  before do
    stub_const "DataUpdateScript::DIRECTORY", test_directory
  end

  it "runs scripts that need running" do
    expect do
      worker.perform
    end.to change(DataUpdateScript, :count).by(1)
  end

  it "will not run a script that has already been run" do
    worker.perform
    expect do
      worker.perform
    end.to change(DataUpdateScript, :count).by(0)
  end

  it "updates DataUpdateScript model" do
    expect do
      worker.perform
    end.to change(DataUpdateScript, :count).by(1)

    dus = DataUpdateScript.last
    expect(dus.finished_at).not_to be_nil
    expect(dus).to be_succeeded
    expect(dus.run_at).not_to be_nil
  end

  it "logs data to stdout", :aggregate_failures do
    allow(Rails.logger).to receive(:info)
    worker.perform

    statuses.each do |status|
      expect(Rails.logger).to have_received(:info).once.with(/#{status}/)
    end
  end

  it "logs data to Datadog", :aggregate_failures do
    allow(DatadogStatsClient).to receive(:increment)
    worker.perform

    statuses.each do |status|
      expected_args = [
        "data_update_scripts.status",
        { tags: ["status:#{status}", "script_name:20200214151804_data_update_test_script"] },
      ]
      expect(DatadogStatsClient).to have_received(:increment).once.with(*expected_args)
    end
  end
end
