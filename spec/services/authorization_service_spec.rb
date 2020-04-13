require "rails_helper"

RSpec.describe AuthorizationService, type: :service do
  before { mock_auth_hash }

  context "when authenticating through an unknown provider" do
    it "raises ProviderNotFound" do
      auth_payload = OmniAuth.config.mock_auth[:github].merge(provider: "okta")
      expect { described_class.new(auth_payload) }.to raise_error(
        Authentication::Errors::ProviderNotFound
      )
    end
  end

  context "when authenticating through Github" do
    describe "new user" do
      let!(:auth_payload) { OmniAuth.config.mock_auth[:github] }
      let!(:service) { described_class.new(auth_payload) }

      it "creates a new user" do
        expect do
          service.get_user
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.get_user
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.get_user

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image)
        expect(user.github_created_at.to_i).to eq(Time.zone.parse(raw_info.created_at).to_i)
        expect(user.github_username).to eq(info.nickname)
      end

      it "sets default fields" do
        user = service.get_user

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.new(auth_payload, cta_variant: "awesome").get_user

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.get_user

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339
        service = described_class.new(auth_payload)

        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          service.get_user
        end
      end
    end
  end

  context "when authenticating through Twitter" do
    describe "new user" do
      let!(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
      let!(:service) { described_class.new(auth_payload) }

      it "creates a new user" do
        expect do
          service.get_user
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.get_user
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.get_user

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image.to_s.gsub("_normal", ""))
        expect(user.twitter_created_at.to_i).to eq(Time.zone.parse(raw_info.created_at).to_i)
        expect(user.twitter_followers_count).to eq(raw_info.followers_count.to_i)
        expect(user.twitter_following_count).to eq(raw_info.friends_count.to_i)
        expect(user.twitter_username).to eq(info.nickname)
      end

      it "sets default fields" do
        user = service.get_user

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.new(auth_payload, cta_variant: "awesome").get_user

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.get_user

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339
        service = described_class.new(auth_payload)

        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          service.get_user
        end
      end
    end
  end

  describe "existing user" do
    let(:auth) { OmniAuth.config.mock_auth[:twitter] }
    let(:user) { create(:user) }

    before { OmniAuth.config.mock_auth[:twitter].info.email = user.email }

    it "doesn't create a duplicate user" do
      service = described_class.new(auth)
      expect do
        service.get_user
      end.not_to change(User, :count)
    end

    it "sets remember_me for the existing user" do
      user.update_columns(remember_token: nil, remember_created_at: nil)
      service = described_class.new(auth)
      service.get_user
      user.reload
      expect(user.remember_me).to be_truthy
      expect(user.remember_token).to be_truthy
      expect(user.remember_created_at).to be_truthy
    end

    context "when the user has a new Twitter username" do
      it "updates their username properly" do
        new_username = "new_username#{rand(1000)}"
        auth.info.nickname = new_username
        service = described_class.new(auth)
        service.get_user
        user.reload
        expect(user.twitter_username).to eq new_username
      end

      it "touches the profile_updated_at timestamp" do
        original_profile_updated_at = user.profile_updated_at
        new_username = "new_username#{rand(1000)}"
        auth.info.nickname = new_username
        service = described_class.new(auth)
        service.get_user
        user.reload
        expect(user.profile_updated_at).to be > original_profile_updated_at
      end
    end
  end
end
