require "rails_helper"

RSpec.describe DataUpdateScript do
  let(:test_directory) { Rails.root.join("spec/support/fixtures/data_update_scripts") }

  describe "validations" do
    describe "builtin validations" do
      subject { create(:data_update_script) }

      it { is_expected.to validate_presence_of(:file_name) }
      it { is_expected.to validate_presence_of(:status) }

      it { is_expected.to validate_uniqueness_of(:file_name) }
    end
  end

  describe ".scripts_to_run" do
    before { stub_const "#{described_class}::DIRECTORY", test_directory }

    it "creates new DataUpdateScripts from files" do
      expect do
        described_class.scripts_to_run
      end.to change(described_class, :count).by(2)
    end

    it "returns scripts that need to be run" do
      script = create(:data_update_script)
      expect(described_class.scripts_to_run).to include(script)
    end

    it "does not return script ids that are running" do
      script = create(:data_update_script, run_at: Time.current, status: :working)
      expect(described_class.scripts_to_run).not_to include(script)
    end

    it "orders scripts by name" do
      create(:data_update_script, file_name: "456_test_script")
      create(:data_update_script, file_name: "123_test_script")
      expect(described_class.scripts_to_run.ids).to eq(described_class.scripts_to_run.order(file_name: :asc).ids)
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

    it "returns true if there are multiple files on disk" do
      create(:data_update_script, status: :working)
      expect(described_class.scripts_to_run?).to be(true)
    end

    it "returns false if there are only working scripts" do
      create_list(:data_update_script, 2, status: :working)
      expect(described_class.scripts_to_run?).to be(false)
    end

    it "returns false if there are only succeeded scripts" do
      create_list(:data_update_script, 2, status: :succeeded)

      expect(described_class.scripts_to_run?).to be(false)
    end

    it "returns false if there are only failed scripts" do
      create_list(:data_update_script, 2, status: :failed)
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
      test_script.mark_as_failed!(StandardError.new("error"))
      expect(test_script).to be_failed
      expect(test_script.error).to eq("StandardError: error")
      expect(test_script.finished_at).not_to be_nil
    end
  end

  describe "#file_path" do
    it "returns correct loadable file_path" do
      described_class.scripts_to_run.each do |script|
        expect do
          require script.file_path
        end.not_to raise_error
      end
    end
  end
end
