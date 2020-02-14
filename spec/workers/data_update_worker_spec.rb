require "rails_helper"
require Rails.root.join("app/models/data_update_script.rb")

RSpec.describe DataUpdateWorker, type: :worker do
  let(:test_directory) { Rails.root.join("spec/support/fixtures/data_update_scripts") }
  let(:worker) { described_class.new }

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
    dus = DataUpdateScript.find_by(file_name: "20200214151804_data_update_test_script")
    expect(dus.finished_at).not_to be_nil
    expect(dus).to be_succeeded
    expect(dus.run_at).not_to be_nil
  end
end
