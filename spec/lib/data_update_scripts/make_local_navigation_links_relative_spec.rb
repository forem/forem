require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210119060219_make_local_navigation_links_relative.rb",
)

describe DataUpdateScripts::MakeLocalNavigationLinksRelative do
  let(:base_url) { "https://testforem.com" }

  before { allow(URL).to receive(:url).and_return(base_url) }

  it "makes local navigation links relative" do
    absolute_url = "#{base_url}/test"
    navigation_link = create(:navigation_link, :without_url_normalization, url: absolute_url)

    expect do
      described_class.new.run
    end.to change { navigation_link.reload.url }.from(absolute_url).to("/test")
  end

  it "leaves external navigation links unchanged" do
    absolute_url = "https://example.com/test"
    navigation_link = create(:navigation_link, url: absolute_url)

    expect do
      described_class.new.run
    end.not_to change { navigation_link.reload.url }
  end
end
