require "rails_helper"
require "sidekiq/boot_memory_trimmer"

RSpec.describe Sidekiq::BootMemoryTrimmer do
  describe ".skip_eager_loading_web_only_code!" do
    it "excludes every web-only directory from eager loading" do
      autoloader = instance_double(Zeitwerk::Loader, do_not_eager_load: nil)

      described_class.skip_eager_loading_web_only_code!(autoloader: autoloader)

      expected = described_class::WEB_ONLY_EAGER_LOAD_EXCLUSIONS.map { |dir| Rails.root.join(dir) }
      expect(autoloader).to have_received(:do_not_eager_load).with(*expected)
    end

    it "only lists directories that exist in the app" do
      described_class::WEB_ONLY_EAGER_LOAD_EXCLUSIONS.each do |dir|
        expect(Rails.root.join(dir)).to be_directory
      end
    end

    it "is never applied outside of Sidekiq server processes" do
      expect(Sidekiq).not_to be_server
    end

    context "with a real Zeitwerk loader" do
      let(:tmp_root) { Pathname.new(Dir.mktmpdir).realpath }
      let(:loader) { Zeitwerk::Loader.new }
      let(:controller_file) { tmp_root.join("app/controllers/boot_trimmer_spec_controller.rb") }
      let(:model_file) { tmp_root.join("app/models/boot_trimmer_spec_model.rb") }

      before do
        %w[app/controllers app/models].each { |dir| tmp_root.join(dir).mkpath }
        controller_file.write("class BootTrimmerSpecController; end\n")
        model_file.write("class BootTrimmerSpecModel; end\n")

        loader.push_dir(tmp_root.join("app/controllers"))
        loader.push_dir(tmp_root.join("app/models"))
        described_class.skip_eager_loading_web_only_code!(autoloader: loader, root: tmp_root)
        loader.setup
        loader.eager_load
      end

      after do
        loader.unload
        loader.unregister
        FileUtils.remove_entry(tmp_root)
      end

      it "skips web-only code during eager loading but keeps it autoloadable" do
        expect($LOADED_FEATURES).to include(model_file.to_s)
        expect($LOADED_FEATURES).not_to include(controller_file.to_s)

        expect(BootTrimmerSpecController).to be_a(Class)
        expect($LOADED_FEATURES).to include(controller_file.to_s)
      end
    end
  end

  describe ".release_bootsnap_load_path_cache!" do
    # Bootsnap is injected rather than stubbed globally: hiding or replacing the real constant
    # breaks Bootsnap's own Kernel#require patch for the rest of the example.
    it "unloads Bootsnap's load path cache when Bootsnap is loaded" do
      bootsnap = Class.new { def self.unload_cache!; end }
      allow(bootsnap).to receive(:unload_cache!)

      described_class.release_bootsnap_load_path_cache!(bootsnap: bootsnap)

      expect(bootsnap).to have_received(:unload_cache!)
    end

    it "does nothing when Bootsnap is not loaded" do
      expect { described_class.release_bootsnap_load_path_cache!(bootsnap: nil) }.not_to raise_error
    end
  end
end
