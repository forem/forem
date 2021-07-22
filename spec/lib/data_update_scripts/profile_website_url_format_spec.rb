require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210722135549_profile_website_url_format.rb",
)

describe DataUpdateScripts::ProfileWebsiteUrlFormat do
  let(:nil_profile) { create(:profile, website_url: nil) }
  let(:empty_profile) { create(:profile, website_url: "") }
  let(:valid_profile) { create(:profile, website_url: "https://www.example.com") }

  let(:invalid_profile) do
    build(:profile, website_url: "www.example.com").tap do |profile|
      profile.save(validate: false)
    end
  end

  let(:unfixable_profile) do
    build(:profile, website_url: "/local.html").tap do |profile|
      profile.save(validate: false)
    end
  end

  it "does not modify profiles where website url is null" do
    expect { described_class.new.run }.not_to change(nil_profile, :website_url)
  end

  it "does not modify profiles where website url is empty" do
    expect { described_class.new.run }.not_to change(empty_profile, :website_url)
  end

  it "does not modify profiles where website url is valid" do
    expect { described_class.new.run }.not_to change(valid_profile, :website_url)
  end

  it "prepends https:// to invalid urls to make a valid url from hostnames" do
    expect { described_class.new.run }
      .to change { invalid_profile.reload.website_url }
      .from("www.example.com")
      .to("https://www.example.com")
  end

  it "clears websites that don't form valid urls by prepending" do
    expect { described_class.new.run }
      .to change { unfixable_profile.reload.website_url }
      .from("/local.html")
      .to("")
  end
end
