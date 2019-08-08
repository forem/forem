require "rails_helper"

class FakeGibbonRequest < Gibbon::Request
  def lists(*args)
    super
  end

  def members(*args)
    super
  end

  def tag_mods(*args)
    super
  end

  def community_mods(*args)
    super
  end
end

RSpec.describe MailchimpBot do
  let(:user) { create(:user, :ignore_after_callback) }
  let(:article) { create(:article, user_id: user.id) }
  let(:my_gibbon_client) { instance_double(FakeGibbonRequest) }
  let(:tag) { create(:tag, name: "tag name", bg_color_hex: Faker::Color.hex_color, text_color_hex: Faker::Color.hex_color, supported: true) }

  before do
    allow(Gibbon::Request).to receive(:new) { my_gibbon_client }
    allow(my_gibbon_client).to receive(:lists) { my_gibbon_client }
    allow(my_gibbon_client).to receive(:tag_mods) { my_gibbon_client }
    allow(my_gibbon_client).to receive(:community_mods) { my_gibbon_client }
    allow(my_gibbon_client).to receive(:members) { my_gibbon_client }
    allow(my_gibbon_client).to receive(:upsert).and_return(true)
  end

  def matcher
    {
      body: {
        email_address: user.email,
        status: "subscribed",
        merge_fields: {
          NAME: user.name.to_s,
          USERNAME: user.username.to_s,
          TWITTER: user.twitter_username.to_s,
          GITHUB: user.github_username.to_s,
          IMAGE_URL: user.profile_image_url.to_s,
          ARTICLES: user.articles.size,
          COMMENTS: user.comments.size,
          ONBOARD_PK: user.onboarding_package_requested.to_s,
          EXPERIENCE: user.experience_level || 666,
          COUNTRY: user.shipping_country.to_s,
          STATE: user.shipping_state.to_s,
          POSTAL_ZIP: user.shipping_postal_code.to_s
        }
      }
    }
  end

  describe "#upsert" do
    it "works" do
      described_class.new(user).upsert
      expect(my_gibbon_client).to have_received(:upsert)
    end
  end

  describe "#upsert_to_newsletter" do
    it "sends proper information" do
      described_class.new(user).upsert_to_newsletter
      expect(my_gibbon_client).to have_received(:upsert).with(matcher)
    end

    it "unsubscribes properly" do
      user.update(email_newsletter: false)
      described_class.new(user).upsert_to_newsletter
      expect(my_gibbon_client).to have_received(:upsert).
        with(hash_including(body: hash_including(status: "unsubscribed")))
    end

    it "subscribes properly" do
      user.update(email_newsletter: false)
      user.update(email_newsletter: true)
      described_class.new(user).upsert_to_newsletter
      expect(my_gibbon_client).to have_received(:upsert).
        with(hash_including(body: hash_including(status: "subscribed")))
    end

    it "updates email properly" do
      user.update(email: Faker::Internet.email)
      user.confirm
      described_class.new(user).upsert_to_newsletter
      expect(my_gibbon_client).to have_received(:upsert).
        with(hash_including(body: hash_including(email_address: user.email)))
    end
  end

  describe "manage community moderator list" do
    it "returns false if user isn't a community moderator" do
      expect(described_class.new(user).manage_community_moderator_list).to be(false)
    end

    it "sends proper information" do
      user.update(email_community_mod_newsletter: true)
      user.add_role :trusted
      described_class.new(user).manage_community_moderator_list
      expect(my_gibbon_client).to have_received(:upsert).
        with(hash_including(
               body: hash_including(
                 status: "subscribed",
               ),
             ))
    end
  end

  describe "manage tag moderator list" do
    it "returns false if user isn't a tag moderator" do
      expect(described_class.new(user).manage_community_moderator_list).to be(false)
    end

    it "sends proper information" do
      user.update(email_tag_mod_newsletter: true)
      user.add_role(:tag_moderator, tag)
      described_class.new(user).manage_tag_moderator_list
      expect(my_gibbon_client).to have_received(:upsert).
        with(hash_including(
               body: hash_including(
                 status: "subscribed",
               ),
             ))
    end
  end

  describe "#unsubscribe_all_newsletters" do
    context "when called" do
      before { allow(my_gibbon_client).to receive(:update).and_return(true) }

      it "unsubscribes the user from the weekly newsletter" do
        described_class.new(user).unsubscribe_all_newsletters
        expect(my_gibbon_client).to have_received(:update).
          with(hash_including(body: hash_including(status: "unsubscribed")))
      end
    end
  end
end
