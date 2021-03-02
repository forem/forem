require "rails_helper"

RSpec.describe GithubRepo, type: :model do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:repo) { create(:github_repo, user: user) }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  before do
    omniauth_mock_github_payload
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    allow(cache_bust).to receive(:call)
  end

  describe "validations" do
    describe "builtin validations" do
      subject { repo }

      it { is_expected.to validate_presence_of(:github_id_code) }
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_uniqueness_of(:github_id_code) }
      it { is_expected.to validate_uniqueness_of(:url) }
      it { is_expected.to validate_url_of(:url) }
    end
  end

  context "when callbacks are triggered after save" do
    let(:repo) { build(:github_repo, user: user) }

    describe "clearing caches" do
      it "updates the user's updated_at" do
        old_updated_at = user.updated_at

        Timecop.travel(1.minute.from_now) do
          repo.save
        end

        expect(user.reload.updated_at.to_i > old_updated_at.to_i).to be(true)
      end

      it "busts the correct caches" do
        repo.save

        expect(cache_bust).to have_received(:call).with(user.path)
        expect(cache_bust).to have_received(:call).with("#{user.path}?i=i")
        expect(cache_bust).to have_received(:call).with("#{user.path}/?i=i")
      end
    end
  end

  describe ".upsert" do
    let(:params) do
      {
        github_id_code: rand(1000),
        name: Faker::Book.title,
        url: Faker::Internet.url
      }
    end

    it "creates a new repo" do
      expect do
        described_class.upsert(user, params)
      end.to change(described_class, :count).by(1)
    end

    it "creates a repo for the given user" do
      repo = described_class.upsert(user, params)

      expect(repo.user_id).to eq(user.id)
    end

    it "returns an existing repo updated with new params" do
      new_name = Faker::Book.title

      new_repo = described_class.upsert(user, url: repo.url, name: new_name)

      expect(new_repo.id).to eq(repo.id)
      expect(repo.reload.name).to eq(new_name)
    end
  end

  describe "::update_to_latest" do
    it "enqueues GithubRepos::RepoSyncWorker" do
      repo.update(updated_at: 1.week.ago)
      allow(GithubRepos::RepoSyncWorker).to receive(:perform_async)
      described_class.update_to_latest
      expect(GithubRepos::RepoSyncWorker).to have_received(:perform_async).with(repo.id)
    end
  end
end
