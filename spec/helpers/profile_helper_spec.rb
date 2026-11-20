require "rails_helper"

describe ProfileHelper do
  before do
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

  describe "social_authentication_links_for" do
    let(:user) do
      create(:user)
    end
    let(:actual) { helper.social_authentication_links_for(user) }

    context "when a user has no social authentication providers linked" do
      it "does not return any links for a user without social authentication providers" do
        expect(actual).to eq({})
      end
    end

    context "when a user has one social authentication provider linked" do
      let(:user) do
        omniauth_mock_github_payload
        create(:user, :with_identity, identities: ["github"])
      end

      it "returns a link to the social authentication provider's link" do
        expect(actual).to eq({ github: "https://example.com" })
      end
    end

    context "when a user has a broken social authentication provider linked" do
      let(:user) do
        create(:user, :with_broken_identity, identities: ["github"])
      end

      it "ignores that auth provider" do
        expect(actual).to eq({})
      end
    end

    context "when a user has multiple social authentication providers linked" do
      let(:user) do
        omniauth_mock_github_payload
        omniauth_mock_twitter_payload
        omniauth_mock_facebook_payload
        omniauth_mock_apple_payload
        create(:user, :with_identity, identities: %w[github twitter facebook apple])
      end

      it "returns all supported links" do
        expected = { github: "https://example.com", twitter: "https://example.com", facebook: "https://example.com" }
        expect(actual).to eq(expected)
      end

      it "queries only the supported social providers in a single pluck without hydrating Identity records" do
        target_user = user
        queries = []
        callback = lambda { |*, payload|
          next unless payload[:sql]&.include?('"identities"')

          binds = payload[:type_casted_binds]
          binds = binds.call if binds.respond_to?(:call)
          queries << { sql: payload[:sql], binds: Array(binds) }
        }
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          expect(helper.social_authentication_links_for(target_user)).to eq(
            github: "https://example.com",
            twitter: "https://example.com",
            facebook: "https://example.com",
          )
        end

        expect(queries.size).to eq(1)
        expect(queries.first[:sql]).to include('"identities"."auth_data_dump"')
        expect(queries.first[:sql]).to include('"identities"."provider" IN')
        expect(queries.first[:sql]).not_to include('"identities".*')
        expect(queries.first[:binds]).to eq([target_user.id, "github", "twitter", "facebook"])
      end
    end

    context "when no supported social authentication providers are enabled" do
      let(:user) do
        omniauth_mock_github_payload
        create(:user, :with_identity, identities: ["github"])
      end

      before do
        allow(Settings::Authentication).to receive(:providers).and_return(%w[apple])
      end

      it "returns an empty hash without querying identities" do
        target_user = user
        queries = []
        callback = lambda { |*, payload|
          queries << payload[:sql] if payload[:sql]&.include?('"identities"')
        }
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          expect(helper.social_authentication_links_for(target_user)).to eq({})
        end
        expect(queries).to be_empty
      end
    end
  end

  describe "character_count_denominator" do
    it "returns '100' when the field_type is 'text_field'" do
      expect(helper.character_count_denominator("text_field")).to eq("100")
    end

    it "returns '200' when the field_type is 'text_area'" do
      expect(helper.character_count_denominator("text_area")).to eq("200")
    end
  end
end
