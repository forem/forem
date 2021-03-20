require "rails_helper"

RSpec.describe Profiles::Update, type: :service do
  def sidekiq_assert_resave_article_worker(user, &block)
    sidekiq_assert_enqueued_with(
      job: Users::ResaveArticlesWorker,
      args: [user.id],
      queue: "medium_priority",
      &block
    )
  end

  let(:profile) do
    create(:profile, data: { education: "maybe", removed: "Bla" })
  end
  let(:user) { profile.user }

  it "correctly typecasts new attributes", :aggregate_failures do
    described_class.call(user, profile: { location: 123, education: "false" })
    expect(user.location).to eq "123"
    expect(profile.education).to eq "false"
  end

  it "removes old attributes from the profile" do
    expect do
      described_class.call(user, profile: {})
    end.to change { profile.data.key?("removed") }.to(false)
  end

  it "propagates changes to user", :agregate_failures do
    new_name = "Sloan Doe"
    described_class.call(user, profile: {}, user: { name: new_name })
    expect(profile.user.name).to eq new_name
  end

  it "sets custom attributes for the user" do
    custom_profile_field = create(:custom_profile_field, label: "Custom test", profile: profile)
    custom_attribute = custom_profile_field.attribute_name

    described_class.call(user, profile: { custom_attribute => "Test" }, user: {})
    expect(profile.custom_attributes[custom_attribute]).to eq "Test"
  end

  it "updates the profile_updated_at column" do
    expect do
      described_class.call(user, profile: { education: "false" })
    end.to change { user.reload.profile_updated_at }
  end

  it "returns an error if Profile image is too large" do
    profile_image = fixture_file_upload("large_profile_img.jpg", "image/jpeg")
    service = described_class.call(user, profile: {}, user: { profile_image: profile_image })

    expect(service.success?).to be false
    expect(service.errors_as_sentence).to eq "Profile image File size should be less than 2 MB"
  end

  it "returns an error if Profile image is not a file" do
    profile_image = "A String"
    service = described_class.call(user, profile: {}, user: { profile_image: profile_image })

    expect(service.success?).to be false
    expect(service.errors_as_sentence).to eq "invalid file type. Please upload a valid image."
  end

  it "returns an error if Profile image file name is too long" do
    profile_image = fixture_file_upload("800x600.png", "image/png")
    allow(profile_image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")
    service = described_class.call(user, profile: {}, user: { profile_image: profile_image })

    expect(service.success?).to be false
    expect(service.errors_as_sentence).to eq "filename too long - the max is 250 characters."
  end

  context "when conditionally resaving articles" do
    it "enqueues resave articles job when changing username" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user: { username: "#{user.username}_changed" })
      end
    end

    it "enqueues resave articles job when changing profile_image" do
      profile_image = fixture_file_upload("800x600.jpg")

      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user: { profile_image: profile_image })
      end
    end

    it "enqueues resave articles job when changing name" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, user: { name: "#{user.name} changed" })
      end
    end

    it "enqueues resave articles job when changing summary" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, profile: { summary: "#{user.summary} changed" })
      end
    end

    it "enqueues resave articles job when changing bg_color_hex" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, profile: { brand_color1: "#12345F" })
      end
    end

    it "enqueues resave articles job when changing text_color_hex" do
      sidekiq_assert_resave_article_worker(user) do
        described_class.call(user, profile: { brand_color2: "#12345F" })
      end
    end

    Authentication::Providers.username_fields.each do |username_field|
      it "enqueues resave articles job when changing #{username_field}" do
        sidekiq_assert_resave_article_worker(user) do
          described_class.call(user, user: { username_field => "greatnewusername" })
        end
      end

      it "doesn't enqueue resave articles job when changing #{username_field} for a banned user" do
        banned_user = create(:user, :banned)

        expect do
          described_class.call(banned_user, user: { username_field => "greatnewusername" })
        end.not_to change(Users::ResaveArticlesWorker.jobs, :size)
      end
    end
  end
end
