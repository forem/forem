require "rails_helper"
require Rails.root.join("app/models/data_update_script.rb")

RSpec.describe DataUpdateWorker, type: :worker do
  let(:test_directory) { Rails.root.join("spec/support/fixtures/data_update_scripts") }
  let(:worker) { described_class.new }
  let(:statuses) { %w[working succeeded] }

  before do
    stub_const "DataUpdateScript::DIRECTORY", test_directory
  end

  context "when an id is passed" do
    it "it updates the appropriate script" do
      script = create(
        :data_update_script,
        file_name: "20200214151804_data_update_test_script",
        status: "failed"
      )

      expect do
        worker.perform(script.id)
      end.to change(DataUpdateScript, :count).by(0)

      updated_script = DataUpdateScript.find(script.id)
      expect(updated_script.status).to eq("succeeded")
    end
  end


  context "when an id is not passed" do
    it "runs scripts that need running" do
      expect do
        worker.perform
      end.to change(DataUpdateScript, :count).by(2)
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
      end.to change(DataUpdateScript, :count).by(2)

      successsful_dus = DataUpdateScript.find_by(status: :succeeded)
      expect(successsful_dus.finished_at).not_to be_nil
      expect(successsful_dus.run_at).not_to be_nil
      expect(successsful_dus.error).to be_nil

      failed_dus = DataUpdateScript.find_by(status: :failed)
      expect(failed_dus.finished_at).not_to be_nil
      expect(failed_dus.run_at).not_to be_nil
      expect(failed_dus.run_at).not_to be_nil
      expect(failed_dus.error).not_to be_nil
    end
  end

  it "logs data to stdout", :aggregate_failures do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    worker.perform

    expect(Rails.logger).to have_received(:info).twice.with(/working/)
    expect(Rails.logger).to have_received(:info).once.with(/succeeded/)
    expect(Rails.logger).to have_received(:error).once.with(/failed/)
  end

  it "logs data to Datadog", :aggregate_failures do
    allow(ForemStatsClient).to receive(:increment)
    worker.perform

    statuses.each do |status|
      expected_args = [
        "data_update_scripts.status",
        { tags: ["status:#{status}", "script_name:20200214151804_data_update_test_script"] },
      ]
      expect(ForemStatsClient).to have_received(:increment).once.with(*expected_args)
    end
  end
end
