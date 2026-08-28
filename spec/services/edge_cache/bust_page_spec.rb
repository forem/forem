require "rails_helper"

RSpec.describe EdgeCache::BustPage, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
  let(:slug) { "slug" }
  let(:paths) do
    [
      "/page/#{slug}",
      "/#{slug}",
    ]
  end

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)

    paths.each do |path|
      allow(cache_bust).to receive(:call).with(path).once
    end
  end

  it "busts the cache", :aggregate_failures do
    described_class.call(slug)

    paths.each do |path|
      expect(cache_bust).to have_received(:call).with(path).once
    end
  end

  context "when an organization is given" do
    let(:organization) { create(:organization) }
    let(:slug) { "#{organization.slug}/readme" }

    before do
      allow(EdgeCache::PurgeByKey).to receive(:call)
    end

    it "purges the organization's surrogate key with a profile path fallback", :aggregate_failures do
      described_class.call(slug, organization: organization)

      paths.each do |path|
        expect(cache_bust).to have_received(:call).with(path).once
      end
      expect(EdgeCache::PurgeByKey).to have_received(:call)
        .with(organization.record_key, fallback_paths: "/#{organization.slug}")
        .once
    end

    it "does not purge by key when no organization is given" do
      described_class.call(slug)

      expect(EdgeCache::PurgeByKey).not_to have_received(:call)
    end
  end
end
