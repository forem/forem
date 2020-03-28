require "rails_helper"

RSpec.describe GithubRepo, type: :model do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:repo) { build(:github_repo, user_id: user.id) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_uniqueness_of(:url) }
  it { is_expected.to validate_uniqueness_of(:github_id_code) }

  it "saves" do
    repo.save
    expect(repo).to be_valid
  end

  describe "::find_or_create" do
    it "creates a new object if one doesn't already exists" do
      params = { name: Faker::Book.title, user_id: user.id, github_id_code: rand(1000),
                 url: Faker::Internet.url }
      described_class.find_or_create(params)
      expect(described_class.count).to eq(1)
    end

    it "returns existing object if it already exists" do
      repo.save
      before_update_id = repo.id
      params = { github_id_code: repo.github_id_code }
      updated_repo = described_class.find_or_create(params)
      expect(updated_repo.id).to eq(before_update_id)
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
