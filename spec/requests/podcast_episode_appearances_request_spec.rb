require "rails_helper"

RSpec.describe "PodcastEpisodeAppearances", type: :request do
  let(:user) { create(:user) }
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast: podcast) }
  let(:podcast_episode_appearance) { create(:podcast_episode_appearance, podcast_episode: podcast_episode) }

  def episode_appearance_params(role, **kwargs)
    {
      podcast_episode_appearance: {
        user_id: user.id,
        podcast_episode_id: podcast_episode.id,
        role: role
      }.merge(kwargs)
    }
  end

  describe "GET /podcast_episode_appearances" do
    # it is not required to be authenticated
    it "returns a successful response" do
      get podcast_episode_appearances_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /podcast_episode_appearances" do
    before { sign_in user }

    it "return unauthorized when user is not the podcast owner" do
      post podcast_episode_appearances_path, params: episode_appearance_params("guest")
      expect(response).to have_http_status(:unauthorized)
    end

    context "when user is the podcast owner" do
      before do
        create(:podcast_ownership, podcast: podcast, owner: user)
      end

      it "returns OK when values are valid" do
        expect do
          post podcast_episode_appearances_path,
               params: episode_appearance_params("guest")
        end.to change(PodcastEpisodeAppearance, :count).by(1)
        episode_appearance = PodcastEpisodeAppearance.last
        expect(episode_appearance.user_id).to eq user.id
        expect(episode_appearance.podcast_episode_id).to eq podcast_episode.id
        expect(episode_appearance.role).to eq "guest"
        expect(response).to have_http_status(:ok)
      end

      it "returns UNPROCESSABLE_ENTITY when the role is invalid" do
        post podcast_episode_appearances_path, params: episode_appearance_params("random_role")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT /podcast_episode_appearances/:id" do
    before { sign_in user }

    it "return unauthorized when user is not the podcast owner" do
      put "/podcast_episode_appearances/#{podcast_episode_appearance.id}", params: episode_appearance_params("host")
      expect(response).to have_http_status(:unauthorized)
    end

    context "when user is the podcast owner" do
      before do
        create(:podcast_ownership, podcast: podcast, owner: user)
      end

      it "returns OK when values are valid" do
        updated_at = podcast_episode_appearance.updated_at
        put "/podcast_episode_appearances/#{podcast_episode_appearance.id}", params: episode_appearance_params("host")
        podcast_episode_appearance.reload
        episode_appearance = PodcastEpisodeAppearance.find(podcast_episode_appearance.id)
        expect(episode_appearance.user_id).to eq user.id
        expect(episode_appearance.podcast_episode_id).to eq podcast_episode.id
        expect(episode_appearance.role).to eq "host"
        expect(episode_appearance.updated_at).not_to eq updated_at
        expect(response).to have_http_status(:ok)
      end

      it "returns error when role is invalid" do
        put "/podcast_episode_appearances/#{podcast_episode_appearance.id}", params: episode_appearance_params("xyz")
        expect(flash[:error]).not_to be_nil
      end
    end
  end

  describe "DELETE /podcast_episode_appearances/:id" do
    before { sign_in user }

    it "return unauthorized when user is not the podcast owner" do
      delete "/podcast_episode_appearances/#{podcast_episode_appearance.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns OK when request is good" do
      create(:podcast_ownership, podcast: podcast, owner: user)
      delete "/podcast_episode_appearances/#{podcast_episode_appearance.id}", params: episode_appearance_params("host")
      episode_appearance = PodcastEpisodeAppearance.find_by(id: podcast_episode_appearance.id)
      expect(episode_appearance).to be_nil
      expect(response).to have_http_status(:ok)
    end
  end
end
