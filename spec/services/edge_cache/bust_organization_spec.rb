require "rails_helper"

RSpec.describe EdgeCache::BustOrganization, type: :service do
  let(:organization) { create(:organization) }
  let(:article) { create(:article, organization: organization) }
  let(:slug) { "slug" }
  let(:buster) { instance_double(EdgeCache::Buster) }

  before do
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)
    allow(buster).to receive(:bust)
  end

  it "busts the cache" do
    described_class.call(organization, slug)

    expect(buster).to have_received(:bust).with("/#{slug}").once
    expect(buster).to have_received(:bust).with(article.path).once
  end

  it "logs an error" do
    allow(buster).to receive(:bust).with("/5").once
    allow(Rails.logger).to receive(:error)
    described_class.call(4, 5)
    expect(Rails.logger).to have_received(:error).once
  end
end
