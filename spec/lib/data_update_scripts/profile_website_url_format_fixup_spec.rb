require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210722160452_profile_website_url_format_fixup.rb",
)

describe DataUpdateScripts::ProfileWebsiteUrlFormatFixup do
  let(:nil_profile) { create(:profile, website_url: nil) }
  let(:invalid_profile) { make_profile_for("www.example.com") }
  let(:unfixable_profile) { make_profile_for("/local.html") }
  let(:email_profile) { make_profile_for("dan@forem.com") }
  let(:spacey_profile) { make_profile_for("  example.com  ") }
  let(:unparseable_profile) { make_profile_for("this will not parse") }
  let(:empty_profile) { create(:profile, website_url: "") }
  let(:valid_profile) { create(:profile, website_url: "https://www.example.com") }

  def make_profile_for(website_url)
    build(:profile, website_url: website_url).tap do |profile|
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

  it "rejects users in the link" do
    # what was meant to be an email address is actually a valid user@host url
    # we just don't want to do this
    expect { described_class.new.run }
      .to change { email_profile.reload.website_url }
      .from("dan@forem.com")
      .to("")
  end

  it "trims the input to help parsing" do
    expect { described_class.new.run }
      .to change { spacey_profile.reload.website_url }
      .from("  example.com  ")
      .to("https://example.com")
  end

  it "handles parse errors by clearing the website url" do
    expect { described_class.new.run }
      .to change { unparseable_profile.reload.website_url }
      .from("this will not parse")
      .to("")
  end
end
