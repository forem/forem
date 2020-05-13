require "rails_helper"

RSpec.describe GithubRepo, type: :model do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:repo) { create(:github_repo, user: user) }

  before do
    omniauth_mock_github_payload
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
        allow(CacheBuster).to receive(:bust)

        repo.save

        expect(CacheBuster).to have_received(:bust).with(user.path)
        expect(CacheBuster).to have_received(:bust).with("#{user.path}?i=i")
        expect(CacheBuster).to have_received(:bust).with("#{user.path}/?i=i")
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
    let(:my_ocktokit_client) { instance_double(Octokit::Client) }
    let(:url_of_repos_without_github_id) { Faker::Internet.url }
    let(:repo_without_github_id) do
      create(:github_repo, user_id: user.id, url: url_of_repos_without_github_id)
    end
    let(:stubbed_github_repo) do
      OpenStruct.new(repo.attributes.merge(id: repo.github_id_code, html_url: repo.url))
    end

    before do
      repo.save
      allow(Octokit::Client).to receive(:new).and_return(my_ocktokit_client)
      allow(my_ocktokit_client).to receive(:repo) { stubbed_github_repo }
    end

    it "updates all repo" do
      old_updated_at = repo.updated_at
      Timecop.freeze(3.days.from_now) do
        described_class.update_to_latest
        expect(old_updated_at).not_to eq(described_class.find(repo.id).updated_at)
      end
    end
  end
end
