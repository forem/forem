require "rails_helper"

RSpec.describe "Podcast Create", type: :request do
  let(:user) { create(:user) }

  context "when unauthorized user" do
    it "redirects" do
      get new_podcast_path
      expect(response).to redirect_to(sign_up_path)
    end
  end

  context "when signed in" do
    let(:valid_attributes) do
      {
        title: Faker::Hipster.words(number: 2).join(", "),
        description: Faker::Hipster.paragraph(sentence_count: 1),
        twitter_username: "hello-pod",
        image: fixture_file_upload("podcast.png", "image/png"),
        slug: "hello-pod",
        main_color_hex: "ffffff",
        website_url: Faker::Internet.url,
        feed_url: Faker::Internet.url
      }
    end

    before do
      sign_in user
    end

    it "renders new" do
      get new_podcast_path
      expect(response).to be_successful
    end

    it "creates a podcast with valid attributes" do
      expect do
        post podcasts_path, params: { podcast: valid_attributes }
      end.to change(Podcast, :count).by(1)
    end

    it "creates an unpublished podcast" do
      post podcasts_path, params: { podcast: valid_attributes }
      pod = Podcast.find_by(slug: valid_attributes[:slug])
      expect(pod.published).to be false
    end

    it "creates a podcast with correct attributes" do
      post podcasts_path, params: { podcast: valid_attributes }
      pod = Podcast.find_by(slug: valid_attributes[:slug])
      expect(pod.title).to eq(valid_attributes[:title])
    end

    it "creates a podcast_admin role when created by an owner" do
      post podcasts_path, params: { podcast: valid_attributes, i_am_owner: "1" }
      pod = Podcast.find_by(title: valid_attributes[:title])
      expect(user.has_role?(:podcast_admin, pod)).to be true
    end

    it "doesn't create a podcast_admin role when not created by an owner" do
      post podcasts_path, params: { podcast: valid_attributes, i_am_owner: "" }
      pod = Podcast.find_by(title: valid_attributes[:title])
      expect(user.has_role?(:podcast_admin, pod)).to be false
    end

    it "sets the creator" do
      post podcasts_path, params: { podcast: valid_attributes }
      pod = Podcast.find_by(title: valid_attributes[:title])
      expect(pod.creator).to eq(user)
    end

    it "doesn't create with invalid attributes" do
      create(:podcast, slug: valid_attributes[:slug])
      post podcasts_path, params: { podcast: valid_attributes }
      expect(response.body).to include("Suggest a Podcast")
    end

    it "returns error if image file name is too long" do
      image = fixture_file_upload("podcast.png", "image/png")
      allow(image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")
      valid_attributes[:image] = image
      post podcasts_path, params: { podcast: valid_attributes }
      expect(response.body).to include("Suggest a Podcast")
    end

    it "returns error if image is not a file" do
      image = "A String"
      valid_attributes[:image] = image
      post podcasts_path, params: { podcast: valid_attributes }
      expect(response.body).to include("Suggest a Podcast")
    end

    it "returns error if pattern_image file name is too long" do
      image = fixture_file_upload("podcast.png", "image/png")
      allow(image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")
      valid_attributes[:pattern_image] = image
      post podcasts_path, params: { podcast: valid_attributes }
      expect(response.body).to include("Suggest a Podcast")
    end

    it "returns error if pattern_image is not a file" do
      image = "A String"
      valid_attributes[:pattern_image] = image
      post podcasts_path, params: { podcast: valid_attributes }
      expect(response.body).to include("Suggest a Podcast")
    end
  end
end
