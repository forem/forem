require "rails_helper"

RSpec.describe Authentication::Authenticator, type: :service do
  before do
    omniauth_mock_providers_payload
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

  # A shared context is somewhat like a module mixin.  You define
  # the specs to share and then later you can `include_context` for
  # that shared context.
  shared_examples "spam handling" do
    context "when email is spammy" do
      it "raises an Identity::SpamDomainForIdentityError" do
        allow(Settings::Authentication).to receive(:acceptable_domain?).and_return(false)

        expect { service.call }.to raise_error(Authentication::Errors::SpammyEmailDomain)
      end
    end
  end

  context "when authenticating through an unknown provider" do
    it "raises ProviderNotFound" do
      auth_payload = OmniAuth.config.mock_auth[:github].merge(provider: "okta")
      expect { described_class.call(auth_payload) }.to raise_error(
        Authentication::Errors::ProviderNotFound,
      )
    end
  end

  context "when authenticating through Apple", vcr: { cassette_name: "fastly_sloan" } do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:apple] }
    let!(:service) { described_class.new(auth_payload) }

    include_context "spam handling"

    describe "new user" do
      it "creates a new user" do
        expect do
          service.call
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.call
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.call

        info = auth_payload.info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq("#{info.first_name} #{info.last_name}")
        expect(user.profile_image).not_to be_nil
        expect(user.apple_username).to match(/#{info.first_name.downcase}_\w+/)
      end

      it "sets default fields" do
        user = service.call

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.setting.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.call(auth_payload, cta_variant: "awesome")

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.call

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.id_info.auth_time = 1.minute.ago.to_i

        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          described_class.call(auth_payload)
        end
      end

      it "records successful identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).to have_received(:increment).with(
          "identity.created", tags: ["provider:apple"]
        )
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:apple]) }

      before do
        auth_payload.info.email = user.email
      end

      it "doesn't create a new user" do
        expect do
          service.call
        end.not_to change(User, :count)
      end

      it "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"

        expect do
          described_class.call(auth_payload)
        end.to change(Identity, :count).by(1)
      end

      it "does not create a new identity if the user has one" do
        expect do
          service.call
        end.not_to change(Identity, :count)
      end

      it "does not record an identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).not_to have_received(:increment)
      end

      it "updates the proper data from the auth payload" do
        # simulate changing apple data
        auth_payload.info.first_name = "Newname"

        expect do
          described_class.call(auth_payload)
        end.to change { user.reload.apple_username }.to("newname")
      end

      # rubocop:disable RSpec/AnyInstance
      it "avoids overriding the email when a provider has a different one" do
        existing_email = user.email

        # The following mocks the behavior of `current_user` being available
        # which means we're connecting an existing account with the new identity
        allow_any_instance_of(described_class).to receive(:proper_user).and_return(user)
        forem_auth_payload = OmniAuth.config.mock_auth[:forem].merge(email: "different+email@example.com")

        described_class.call(forem_auth_payload)

        # We want to keep the previous email the user had instead of overriding
        # with the new (different) email given by the OAuth provider
        expect(user.reload.email).to eq(existing_email)
        expect(user.reload.unconfirmed_email).to be_nil
      end
      # rubocop:enable RSpec/AnyInstance

      it "sets remember_me for the existing user" do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.call
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.first_name = new_username

        user = described_class.call(auth_payload)

        expect(user.apple_username).to eq(new_username)
      end

      it "does not update the username when the first_name is nil" do
        previous_username = user.apple_username
        auth_payload.info.first_name = nil

        user = described_class.call(auth_payload)

        expect(user.apple_username).to eq(previous_username)
      end

      it "updates profile_updated_at when the username is changed" do
        original_profile_updated_at = user.profile_updated_at

        new_username = "new_username#{rand(1000)}"
        auth_payload.info.first_name = new_username

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
      it "returns the current user if the identity exists" do
        user = create(:user, :with_identity, identities: [:apple])
        expect(described_class.call(auth_payload, current_user: user)).to eq(user)
      end

      it "creates the identity if for any reason it does not exist" do
        user = create(:user)
        expect do
          described_class.call(auth_payload, current_user: user)
        end.to change(Identity, :count).by(1)
      end
    end
  end

  context "when authenticating through Github" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:github] }
    let!(:service) { described_class.new(auth_payload) }

    include_context "spam handling"

    describe "new user" do
      it "creates a new user" do
        expect do
          service.call
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.call
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.call

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image)
        expect(user.github_username).to eq(info.nickname)
      end

      it "sets default fields" do
        user = service.call

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.setting.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.call(auth_payload, cta_variant: "awesome")

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.call

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339

        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          described_class.call(auth_payload)
        end
      end

      it "records successful identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).to have_received(:increment).with(
          "identity.created", tags: ["provider:github"]
        )
      end

      it "increments identity.errors if any errors occur in the transaction" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Identity).to receive(:save!).and_raise(StandardError)
        # rubocop:enable RSpec/AnyInstance
        allow(ForemStatsClient).to receive(:increment)

        expect { described_class.call(auth_payload) }.to raise_error(StandardError)

        tags = hash_including(tags: array_including("error:StandardError"))
        expect(ForemStatsClient).to have_received(:increment).with("identity.errors", tags)
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:github]) }

      before do
        auth_payload.info.email = user.email
      end

      it "doesn't create a new user" do
        expect do
          service.call
        end.not_to change(User, :count)
      end

      it "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"

        expect do
          described_class.call(auth_payload)
        end.to change(Identity, :count).by(1)
      end

      it "does not create a new identity if the user has one" do
        expect do
          service.call
        end.not_to change(Identity, :count)
      end

      it "does not record an identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).not_to have_received(:increment)
      end

      it "sets remember_me for the existing user" do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.call
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        user = described_class.call(auth_payload)

        expect(user.github_username).to eq(new_username)
      end

      it "updates profile_updated_at when the username is changed" do
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

      it "increments identity.errors if any errors occur in the transaction" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Identity).to receive(:save!).and_raise(StandardError)
        # rubocop:enable RSpec/AnyInstance
        allow(ForemStatsClient).to receive(:increment)

        expect { described_class.call(auth_payload) }.to raise_error(StandardError)

        tags = hash_including(tags: array_including("error:StandardError"))
        expect(ForemStatsClient).to have_received(:increment).with("identity.errors", tags)
      end

      it "does not update their github_username if the user is suspended" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username
        user.add_role :suspended

        user = described_class.call(auth_payload)
        expect(user.github_username).not_to eq(new_username)
      end
    end

    describe "user already logged in" do
      it "returns the current user if the identity exists" do
        user = create(:user, :with_identity, identities: [:github])
        expect(described_class.call(auth_payload, current_user: user)).to eq(user)
      end

      it "creates the identity if for any reason it does not exist" do
        user = create(:user)
        expect do
          described_class.call(auth_payload, current_user: user)
        end.to change(Identity, :count).by(1)
      end
    end
  end

  context "when authenticating through Facebook" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:facebook] }
    let!(:service) { described_class.new(auth_payload) }

    include_context "spam handling"

    describe "new user" do
      it "creates a new user" do
        expect do
          service.call
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.call
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.call

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image)
        expect(user.facebook_username).to match(/#{info.name.sub(' ', '_')}_\S*\z/)
      end

      it "sets default fields" do
        user = service.call

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.setting.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.call(auth_payload, cta_variant: "awesome")

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.call

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339

        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          described_class.call(auth_payload)
        end
      end

      it "records successful identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).to have_received(:increment).with(
          "identity.created", tags: ["provider:facebook"]
        )
      end

      it "increments identity.errors if any errors occur in the transaction" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Identity).to receive(:save!).and_raise(StandardError)
        # rubocop:enable RSpec/AnyInstance
        allow(ForemStatsClient).to receive(:increment)

        expect { described_class.call(auth_payload) }.to raise_error(StandardError)

        tags = hash_including(tags: array_including("error:StandardError"))
        expect(ForemStatsClient).to have_received(:increment).with("identity.errors", tags)
      end
    end
  end

  context "when authenticating through Twitter" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
    let!(:service) { described_class.new(auth_payload) }

    include_context "spam handling"

    describe "new user" do
      it "creates a new user" do
        expect do
          service.call
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.call
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.call

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image.to_s.gsub("_normal", ""))
        expect(user.twitter_username).to eq(info.nickname)
      end

      it "sets default fields" do
        user = service.call

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.setting.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.call(auth_payload, cta_variant: "awesome")

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.call

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339

        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          described_class.call(auth_payload)
        end
      end

      it "records successful identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).to have_received(:increment).with(
          "identity.created", tags: ["provider:twitter"]
        )
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:twitter]) }

      before do
        auth_payload.info.email = user.email
      end

      it "doesn't create a new user" do
        expect do
          service.call
        end.not_to change(User, :count)
      end

      it "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"

        expect do
          described_class.call(auth_payload)
        end.to change(Identity, :count).by(1)
      end

      it "does not create a new identity if the user has one" do
        expect do
          service.call
        end.not_to change(Identity, :count)
      end

      it "does not record an identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).not_to have_received(:increment)
      end

      it "updates the proper data from the auth payload" do
        # simulate changing twitter data
        auth_payload.info.nickname = "newnick"

        expect do
          described_class.call(auth_payload)
        end.to change { user.reload.twitter_username }.to eq("newnick")
      end

      it "sets remember_me for the existing user" do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.call
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        user = described_class.call(auth_payload)

        expect(user.twitter_username).to eq(new_username)
      end

      it "updates profile_updated_at when the username is changed" do
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

      it "does not update their twitter_username if the user is suspended" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username
        user.add_role :suspended

        user = described_class.call(auth_payload)
        expect(user.github_username).not_to eq(new_username)
      end
    end

    describe "user already logged in" do
      it "returns the current user if the identity exists" do
        user = create(:user, :with_identity, identities: [:twitter])
        expect(described_class.call(auth_payload, current_user: user)).to eq(user)
      end

      it "creates the identity if for any reason it does not exist" do
        user = create(:user)
        expect do
          described_class.call(auth_payload, current_user: user)
        end.to change(Identity, :count).by(1)
      end
    end
  end

  context "when authenticating through Forem Account" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:forem] }
    let!(:service) { described_class.new(auth_payload) }

    include_context "spam handling"

    describe "new user" do
      it "creates a new user" do
        expect do
          service.call
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.call
        end.to change(Identity, :count).by(1)
      end

      it "persists the user as confirmed when SMTP isn't enabled" do
        allow(ForemInstance).to receive(:smtp_enabled?).and_return(false)
        user = service.call
        expect(user.confirmed?).to be(true)
      end

      it "persists the user as confirmed (special provider provider) when SMTP is enabled" do
        allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
        user = service.call
        expect(user.confirmed?).to be(true)
      end

      it "extracts the proper data from the auth payload", :aggregate_failures do
        user = service.call

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image)
        expect(user.forem_username).to eq(info.user_nickname)
      end

      it "sets default fields", :aggregate_failures do
        user = service.call

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.setting.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.call(auth_payload, cta_variant: "awesome")

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user", :aggregate_failures do
        user = service.call

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339

        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          described_class.call(auth_payload)
        end
      end

      it "records successful identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).to have_received(:increment).with(
          "identity.created", tags: ["provider:forem"]
        )
      end

      it "increments identity.errors if any errors occur in the transaction", :aggregate_failures do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Identity).to receive(:save!).and_raise(StandardError)
        # rubocop:enable RSpec/AnyInstance
        allow(ForemStatsClient).to receive(:increment)

        expect { described_class.call(auth_payload) }.to raise_error(StandardError)

        tags = hash_including(tags: array_including("error:StandardError"))
        expect(ForemStatsClient).to have_received(:increment).with("identity.errors", tags)
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:forem]) }

      before do
        auth_payload.info.email = user.email
      end

      it "doesn't create a new user" do
        expect do
          service.call
        end.not_to change(User, :count)
      end

      it "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"

        expect do
          described_class.call(auth_payload)
        end.to change(Identity, :count).by(1)
      end

      it "does not create a new identity if the user has one" do
        expect do
          service.call
        end.not_to change(Identity, :count)
      end

      it "does not record an identity creation metric" do
        allow(ForemStatsClient).to receive(:increment)
        service.call

        expect(ForemStatsClient).not_to have_received(:increment)
      end

      it "sets remember_me for the existing user", :aggregate_failures do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.call
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.user_nickname = new_username

        user = described_class.call(auth_payload)

        expect(user.forem_username).to eq(new_username)
      end

      it "updates profile_updated_at when the username is changed" do
        original_profile_updated_at = user.profile_updated_at

        new_username = "new_username#{rand(1000)}"
        auth_payload.info.user_nickname = new_username

        Timecop.travel(1.minute.from_now) do
          described_class.call(auth_payload)
        end

        user.reload
        expect(
          user.profile_updated_at.to_i > original_profile_updated_at.to_i,
        ).to be(true)
      end

      it "increments identity.errors if any errors occur in the transaction", :aggregate_failures do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Identity).to receive(:save!).and_raise(StandardError)
        # rubocop:enable RSpec/AnyInstance
        allow(ForemStatsClient).to receive(:increment)

        expect { described_class.call(auth_payload) }.to raise_error(StandardError)

        tags = hash_including(tags: array_including("error:StandardError"))
        expect(ForemStatsClient).to have_received(:increment).with("identity.errors", tags)
      end

      it "does not update their forem_username if the user is suspended" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username
        user.add_role :suspended

        user = described_class.call(auth_payload)
        expect(user.forem_username).not_to eq(new_username)
      end
    end

    describe "user already logged in" do
      it "returns the current user if the identity exists" do
        user = create(:user, :with_identity, identities: [:forem])
        expect(described_class.call(auth_payload, current_user: user)).to eq(user)
      end

      it "creates the identity if for any reason it does not exist" do
        user = create(:user)
        expect do
          described_class.call(auth_payload, current_user: user)
        end.to change(Identity, :count).by(1)
      end
    end
  end
end
