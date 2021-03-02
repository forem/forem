require "rails_helper"

RSpec.describe EdgeCache::BustOrganization, type: :service do
  let(:organization) { create(:organization) }
  let(:article) { create(:article, organization: organization) }
  let(:slug) { "slug" }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    allow(cache_bust).to receive(:call)
  end

  it "busts the cache" do
    described_class.call(organization, slug)

    expect(cache_bust).to have_received(:call).with("/#{slug}").once
    expect(cache_bust).to have_received(:call).with(article.path).once
  end

  it "logs an error" do
    allow(cache_bust).to receive(:call).with("/5").once
    allow(Rails.logger).to receive(:error)
    described_class.call(4, 5)
    expect(Rails.logger).to have_received(:error).once
  end
end
