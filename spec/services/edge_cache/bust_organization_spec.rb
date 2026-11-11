require "rails_helper"

RSpec.describe EdgeCache::BustOrganization, type: :service do
  let(:organization) { create(:organization) }
  let!(:article) { create(:article, organization: organization) }
  let(:slug) { "slug" }

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "purges the organization's surrogate key with lazy fallback paths", :aggregate_failures do
    described_class.call(organization, slug)

    expect(EdgeCache::PurgeByKey).to have_received(:call).once do |keys, fallback_paths:|
      expect(keys).to eq(["organizations/#{organization.id}"])
      expect(fallback_paths).to respond_to(:call)
      expect(fallback_paths.call).to contain_exactly("/#{slug}", article.path)
    end
  end

  it "handles non-ActiveRecord inputs gracefully" do
    described_class.call(4, 5)

    expect(EdgeCache::PurgeByKey).to have_received(:call).once do |keys, fallback_paths:|
      expect(keys).to eq([])
      expect(fallback_paths.call).to eq(["/5"])
    end
  end
end
