require "rails_helper"

RSpec.describe "Assets tasks", type: :task do
  describe "assets:clean_caches" do
    let(:bootsnap_dir) { Rails.root.join("tmp/cache/bootsnap") }
    let(:bootsnap_marker) { bootsnap_dir.join("compile-cache-iseq") }
    let(:other_cache_dir) { Rails.root.join("tmp/cache/assets_test_cleanup") }
    let(:other_cache_file) { other_cache_dir.join("stale.tmp") }

    before do
      Rake.application["assets:clean_caches"].reenable
      FileUtils.mkdir_p(bootsnap_dir)
      FileUtils.touch(bootsnap_marker)
      FileUtils.mkdir_p(other_cache_dir)
      FileUtils.touch(other_cache_file)
      allow(FileUtils).to receive(:rm_rf).and_call_original
      allow(FileUtils).to receive(:rm_rf).with("vendor/cache")
    end

    after do
      FileUtils.rm_rf(other_cache_dir)
    end

    it "removes transient asset caches in tmp/cache and vendor/cache while preserving tmp/cache/bootsnap" do
      Rake::Task["assets:clean_caches"].invoke

      expect(File.exist?(other_cache_dir)).to be(false)
      expect(File.exist?(bootsnap_dir)).to be(true)
      expect(File.exist?(bootsnap_marker)).to be(true)
      expect(FileUtils).to have_received(:rm_rf).with("vendor/cache")
    end
  end
end
