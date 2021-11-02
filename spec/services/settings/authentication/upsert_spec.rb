require "rails_helper"

RSpec.describe Settings::Authentication::Upsert, type: :service do
  before { Settings::Authentication.providers = %w[github] }

  it "assigns enabled providers from parameters" do
    expect do
      described_class.call(
        {
          "auth_providers_to_enable" => "github,facebook,twitter",
          "github_key" => "asdf",
          "github_secret" => "asdf_secret",
          "twitter_key" => "asdf",
          "twitter_secret" => "asdf_secret",
          "facebook_key" => "asdf",
          "facebook_secret" => "asdf_secret"
        },
      )
    end.to change {
      Settings::Authentication.providers
    }.from(%w[github]).to(%w[github facebook twitter])
  end

  it "disables providers that are not present" do
    expect do
      described_class.call(
        {
          "auth_providers_to_enable" => "twitter",
          "twitter_key" => "asdf",
          "twitter_secret" => "asdf_secret"
        },
      )
    end.to change {
      Settings::Authentication.providers
    }.from(%w[github]).to(%w[twitter])
  end

  it "disables providers even when provider parameter is blank" do
    expect do
      described_class.call({ "auth_providers_to_enable" => "" })
    end.to change {
      Settings::Authentication.providers
    }.from(%w[github]).to([])
  end
end
