require "rails_helper"

RSpec.describe DataUpdateScript do
  let(:test_directory) { Rails.root.join("spec/support/fixtures/data_update_scripts") }

  it { is_expected.to validate_uniqueness_of(:file_name) }

  it "can constantize all script names" do
    described_class.load_script_ids # Create DataUpdateScripts in db
    described_class.filenames.each do |filename|
      script = described_class.find_by(file_name: filename)
      expect { script.file_class }.not_to raise_error
    end
  end

  it "default orders scripts by name" do
    script1 = create(:data_update_script, file_name: "456_test_script")
    script2 = create(:data_update_script, file_name: "123_test_script")
    expect(described_class.pluck(:id)).to eq([script2.id, script1.id])
  end

  describe ".load_script_ids" do
    before { stub_const "#{described_class}::DIRECTORY", test_directory }

    it "creates new DataUpdateScripts from files" do
      expect do
        described_class.load_script_ids
      end.to change(described_class, :count).by(1)
    end

    it "returns script ids that need to be run" do
      script = create(:data_update_script)
      need_running_ids = described_class.load_script_ids
      expect(need_running_ids).to include(script.id)
    end

    it "does not return script ids that are running" do
      script = create(:data_update_script, run_at: Time.current, status: :working)
      need_running_ids = described_class.load_script_ids
      expect(need_running_ids).not_to include(script.id)
    end
  end

  describe ".scripts_to_run" do
    before { stub_const "#{described_class}::DIRECTORY", test_directory }

    it "creates new DataUpdateScripts from files" do
      expect do
        described_class.scripts_to_run
      end.to change(described_class, :count).by(1)
    end

    it "returns scripts that need to be run" do
      script = create(:data_update_script)
      expect(described_class.scripts_to_run).to include(script)
    end

    it "does not return script ids that are running" do
      script = create(:data_update_script, run_at: Time.current, status: :working)
      expect(described_class.scripts_to_run).not_to include(script)
    end
  end

  describe ".scripts_to_run?" do
    before { stub_const "#{described_class}::DIRECTORY", test_directory }

    it "returns true for a new set of files" do
      expect(described_class.scripts_to_run?).to be(true)
    end

    it "returns true if there is an enqueued script" do
      create(:data_update_script, status: :enqueued)
      expect(described_class.scripts_to_run?).to be(true)
    end

    it "returns false if there are only working scripts" do
      create(:data_update_script, status: :working)
      expect(described_class.scripts_to_run?).to be(false)
    end

    it "returns false if there are only succeeded scripts" do
      create(:data_update_script, status: :succeeded)
      expect(described_class.scripts_to_run?).to be(false)
    end

    it "returns false if there are only failed scripts" do
      create(:data_update_script, status: :failed)
      expect(described_class.scripts_to_run?).to be(false)
    end
  end

  describe "#mark_as_finished!" do
    it "marks data update script as finished" do
      test_script = create(:data_update_script)
      expect(test_script.finished_at).to be_nil
      expect(test_script).to be_enqueued
      test_script.mark_as_finished!
      expect(test_script).to be_succeeded
      expect(test_script.finished_at).not_to be_nil
    end
  end

  describe "#mark_as_run!" do
    it "marks data update script as working" do
      test_script = create(:data_update_script)
      expect(test_script.run_at).to be_nil
      expect(test_script).to be_enqueued
      test_script.mark_as_run!
      expect(test_script).to be_working
      expect(test_script.run_at).not_to be_nil
    end
  end

  describe "#mark_as_failed!" do
    it "marks data update script as failed" do
      test_script = create(:data_update_script)
      expect(test_script.finished_at).to be_nil
      expect(test_script).to be_enqueued
      test_script.mark_as_failed!
      expect(test_script).to be_failed
      expect(test_script.finished_at).not_to be_nil
    end
  end

  describe "#file_path" do
    it "returns correct loadable file_path" do
      described_class.load_script_ids
      described_class.filenames.each do |filename|
        expect do
          script = described_class.find_by(file_name: filename)
          require script.file_path
        end.not_to raise_error
      end
    end
  end
end
