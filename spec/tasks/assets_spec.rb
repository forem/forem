require "rails_helper"

RSpec.describe "Assets tasks", type: :task do
  describe "assets:clean_caches" do
    let(:bootsnap_dir) { Rails.root.join("tmp/cache/bootsnap") }
    let(:bootsnap_marker) { bootsnap_dir.join("compile-cache-iseq") }
    let(:other_cache_dir) { Rails.root.join("tmp/cache/assets_test_cleanup") }
    let(:other_cache_file) { other_cache_dir.join("stale.tmp") }
    let(:dummy_gem_archive) { Rails.root.join("vendor/cache/test_cleanup_dummy.gem") }
    let(:git_gem_dir) { Rails.root.join("vendor/cache/acts_as_follower-06393d3693a1") }

    before do
      Rake.application["assets:clean_caches"].reenable
      FileUtils.mkdir_p(bootsnap_dir)
      FileUtils.touch(bootsnap_marker)
      FileUtils.mkdir_p(other_cache_dir)
      FileUtils.touch(other_cache_file)
      FileUtils.touch(dummy_gem_archive)
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with("vendor/cache/*.gem").and_return([dummy_gem_archive.to_s])
    end

    after do
      FileUtils.rm_rf(other_cache_dir)
      FileUtils.rm_f(dummy_gem_archive)
    end

    it "removes transient asset caches and .gem archives in vendor/cache while preserving git gems and bootsnap" do
      Rake::Task["assets:clean_caches"].invoke

      expect(File.exist?(other_cache_dir)).to be(false)
      expect(File.exist?(dummy_gem_archive)).to be(false)
      expect(File.exist?(git_gem_dir)).to be(true)
      expect(File.exist?(bootsnap_dir)).to be(true)
      expect(File.exist?(bootsnap_marker)).to be(true)
    end
  end
end
