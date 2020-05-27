require "rails_helper"

RSpec.describe Authentication::Authenticator, type: :service do
  before { omniauth_mock_providers_payload }

  context "when authenticating through an unknown provider" do
    xit "raises ProviderNotFound" do
      auth_payload = OmniAuth.config.mock_auth[:github].merge(provider: "okta")
      expect { described_class.call(auth_payload) }.to raise_error(
        Authentication::Errors::ProviderNotFound,
      )
    end
  end

  context "when authenticating through Github" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:github] }
    let!(:service) { described_class.new(auth_payload) }

    describe "new user" do
      xit "creates a new user" do
        expect do
          service.call
        end.to change(User, :count).by(1)
      end

      xit "creates a new identity" do
        expect do
          service.call
        end.to change(Identity, :count).by(1)
      end

      xit "extracts the proper data from the auth payload" do
        user = service.call

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image)
        expect(user.github_created_at.to_i).to eq(Time.zone.parse(raw_info.created_at).to_i)
        expect(user.github_username).to eq(info.nickname)
      end

      xit "sets default fields" do
        user = service.call

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.editor_version).to eq("v2")
      end

      xit "sets the correct sign up cta variant" do
        user = described_class.call(auth_payload, cta_variant: "awesome")

        expect(user.signup_cta_variant).to eq("awesome")
      end

      xit "sets remember_me for the new user" do
        user = service.call

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      xit "sets confirmed_at" do
        user = service.call

        expect(user.confirmed_at).to be_present
      end

      xit "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339

        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          described_class.call(auth_payload)
        end
      end

      xit "records successful identity creation metric" do
        allow(DatadogStatsClient).to receive(:increment)
        service.call

        expect(DatadogStatsClient).to have_received(:increment).with(
          "identity.created", tags: ["provider:github"]
        )
      end

      xit "increments identity.errors if any errors occur in the transaction" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Identity).to receive(:save!).and_raise(StandardError)
        # rubocop:enable RSpec/AnyInstance
        allow(DatadogStatsClient).to receive(:increment)

        expect { described_class.call(auth_payload) }.to raise_error(StandardError)

        tags = hash_including(tags: array_including("error:StandardError"))
        expect(DatadogStatsClient).to have_received(:increment).with("identity.errors", tags)
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:github]) }

      before do
        auth_payload.info.email = user.email
      end

      xit "doesn't create a new user" do
        expect do
          service.call
        end.not_to change(User, :count)
      end

      xit "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"

        expect do
          described_class.call(auth_payload)
        end.to change(Identity, :count).by(1)
      end

      xit "does not create a new identity if the user has one" do
        expect do
          service.call
        end.not_to change(Identity, :count)
      end

      xit "does not record an identity creation metric" do
        allow(DatadogStatsClient).to receive(:increment)
        service.call

        expect(DatadogStatsClient).not_to have_received(:increment)
      end

      xit "sets remember_me for the existing user" do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.call
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      xit "updates confirmed_at with the current UTC time" do
        original_confirmed_at = user.confirmed_at

        Timecop.travel(1.minute.from_now) do
          service.call
        end

        user.reload
        expect(
          user.confirmed_at.utc.to_i > original_confirmed_at.utc.to_i,
        ).to be(true)
      end

      xit "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        user = described_class.call(auth_payload)

        expect(user.github_username).to eq(new_username)
      end

      xit "updates profile_updated_at when the username is changed" do
        original_profile_updated_at = user.profile_updated_at

        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        Timecop.travel(1.minute.from_now) do
          described_class.call(auth_payload)
        end

        user.reload
        expect(
          user.profile_updated_at.to_i > original_profile_updated_at.to_i,
        ).to be(true)
      end

      xit "increments identity.errors if any errors occur in the transaction" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Identity).to receive(:save!).and_raise(StandardError)
        # rubocop:enable RSpec/AnyInstance
        allow(DatadogStatsClient).to receive(:increment)

        expect { described_class.call(auth_payload) }.to raise_error(StandardError)

        tags = hash_including(tags: array_including("error:StandardError"))
        expect(DatadogStatsClient).to have_received(:increment).with("identity.errors", tags)
      end
    end

    describe "user already logged in" do
      xit "returns the current user if the identity exists" do
        user = create(:user, :with_identity, identities: [:github])
        expect(described_class.call(auth_payload, current_user: user)).to eq(user)
      end

      xit "creates the identity if for any reason it does not exist" do
        user = create(:user)
        expect do
          described_class.call(auth_payload, current_user: user)
        end.to change(Identity, :count).by(1)
      end
    end
  end

  context "when authenticating through Twitter" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
    let!(:service) { described_class.new(auth_payload) }

    describe "new user" do
      xit "creates a new user" do
        expect do
          service.call
        end.to change(User, :count).by(1)
      end

      xit "creates a new identity" do
        expect do
          service.call
        end.to change(Identity, :count).by(1)
      end

      xit "extracts the proper data from the auth payload" do
        user = service.call

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

      xit "sets default fields" do
        user = service.call

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.editor_version).to eq("v2")
      end

      xit "sets the correct sign up cta variant" do
        user = described_class.call(auth_payload, cta_variant: "awesome")

        expect(user.signup_cta_variant).to eq("awesome")
      end

      xit "sets remember_me for the new user" do
        user = service.call

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      xit "sets confirmed_at" do
        user = service.call

        expect(user.confirmed_at).to be_present
      end

      xit "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339

        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          described_class.call(auth_payload)
        end
      end

      xit "records successful identity creation metric" do
        allow(DatadogStatsClient).to receive(:increment)
        service.call

        expect(DatadogStatsClient).to have_received(:increment).with(
          "identity.created", tags: ["provider:twitter"]
        )
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:twitter]) }

      before do
        auth_payload.info.email = user.email
      end

      xit "doesn't create a new user" do
        expect do
          service.call
        end.not_to change(User, :count)
      end

      xit "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"

        expect do
          described_class.call(auth_payload)
        end.to change(Identity, :count).by(1)
      end

      xit "does not create a new identity if the user has one" do
        expect do
          service.call
        end.not_to change(Identity, :count)
      end

      xit "does not record an identity creation metric" do
        allow(DatadogStatsClient).to receive(:increment)
        service.call

        expect(DatadogStatsClient).not_to have_received(:increment)
      end

      xit "updates the proper data from the auth payload" do
        # simulate changing twitter data
        auth_payload.extra.raw_info.followers_count = rand(100).to_s
        auth_payload.extra.raw_info.friends_count = rand(100).to_s

        user = described_class.call(auth_payload)

        raw_info = auth_payload.extra.raw_info

        expect(user.twitter_created_at.to_i).to eq(Time.zone.parse(raw_info.created_at).to_i)
        expect(user.twitter_followers_count).to eq(raw_info.followers_count.to_i)
        expect(user.twitter_following_count).to eq(raw_info.friends_count.to_i)
      end

      xit "sets remember_me for the existing user" do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.call
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      xit "updates confirmed_at with the current UTC time" do
        original_confirmed_at = user.confirmed_at

        Timecop.travel(1.minute.from_now) do
          service.call
        end

        user.reload
        expect(
          user.confirmed_at.utc.to_i > original_confirmed_at.utc.to_i,
        ).to be(true)
      end

      xit "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        user = described_class.call(auth_payload)

        expect(user.twitter_username).to eq(new_username)
      end

      xit "updates profile_updated_at when the username is changed" do
        original_profile_updated_at = user.profile_updated_at

        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        Timecop.travel(1.minute.from_now) do
          described_class.call(auth_payload)
        end

        user.reload
        expect(
          user.profile_updated_at.to_i > original_profile_updated_at.to_i,
        ).to be(true)
      end
    end

    describe "user already logged in" do
      xit "returns the current user if the identity exists" do
        user = create(:user, :with_identity, identities: [:twitter])
        expect(described_class.call(auth_payload, current_user: user)).to eq(user)
      end

      xit "creates the identity if for any reason it does not exist" do
        user = create(:user)
        expect do
          described_class.call(auth_payload, current_user: user)
        end.to change(Identity, :count).by(1)
      end
    end
  end
end
