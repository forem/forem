require "rails_helper"

RSpec.describe GithubRepo, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_uniqueness_of(:url) }
  it { is_expected.to validate_uniqueness_of(:github_id_code) }

  let(:user) { create(:user) }
  let(:repo) { build(:github_repo, user_id: user.id) }

  it "saves" do
    repo.save
    expect(repo).to be_valid
  end

  describe "::find_or_create" do
    it "creates a new object if one doesn't already exists" do
      params = { name: Faker::Book.title, user_id: user.id }
      described_class.find_or_create("#{Faker::Internet.url}1", params)
      expect(described_class.count).to eq(1)
    end

    it "returns existing object if it already exists" do
      repo.save
      before_update_id = repo.id
      params = { name: Faker::Book.title }
      updated_repo = described_class.find_or_create(repo.url, params)
      expect(updated_repo.id).to eq(before_update_id)
    end
  end

  describe "::update_to_latest" do
    let(:my_ocktokit_client) { instance_double(Octokit::Client) }
    let(:stubbed_github_repos) do
      [OpenStruct.new(repo.attributes.merge(id: repo.github_id_code, html_url: repo.url))]
    end

    before do
      repo.save
      allow(Octokit::Client).to receive(:new).and_return(my_ocktokit_client)
      allow(my_ocktokit_client).to receive(:repositories) { stubbed_github_repos }
    end

    it "updates all repo" do
      old_updated_at = repo.updated_at
      Timecop.freeze(Date.today + 3) do
        described_class.update_to_latest
        expect(old_updated_at).not_to eq(GithubRepo.first.updated_at)
      end
    end

    it "uses repo's url as reference if id isn't provided" do
      repo.update(github_id_code: nil)
      Timecop.freeze(Date.today + 3) do
        described_class.update_to_latest
        expect(repo.updated_at).not_to eq(GithubRepo.first.updated_at)
      end
    end
  end
end
