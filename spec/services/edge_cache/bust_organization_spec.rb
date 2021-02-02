require "rails_helper"

RSpec.describe EdgeCache::BustOrganization, type: :service do
  let(:organization) { create(:organization) }
  let(:article) { create(:article, organization: organization) }
  let(:slug) { "slug" }

  before do
    allow(described_class).to receive(:bust).with("/#{slug}").once
    allow(described_class).to receive(:bust).with(article.path).once
  end

  it "busts the cache" do
    described_class.call(organization, slug)

    expect(described_class).to have_received(:bust).with("/#{slug}").once
    expect(described_class).to have_received(:bust).with(article.path).once
  end

  it "logs an error" do
    allow(described_class).to receive(:bust).with("/5").once
    allow(Rails.logger).to receive(:error)
    described_class.call(4, 5)
    expect(Rails.logger).to have_received(:error).once
  end
end
