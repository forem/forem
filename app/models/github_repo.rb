class GithubRepo < ApplicationRecord
  belongs_to :user

  serialize :info_hash, Hash
  validates :name, :url, :github_id_code, presence: true
  validates :url, uniqueness: true
  validates :github_id_code, uniqueness: true

  after_save :clear_caches
  before_destroy :clear_caches

  def self.find_or_create(params)
    repo = where(github_id_code: params[:github_id_code]).
      or(where(url: params[:url])).
      first_or_initialize
    repo.update(params)
    repo
  end

  def self.update_to_latest
    where("updated_at < ?", 1.day.ago).find_each do |repo|
      user_token = User.find_by(id: repo.user_id).identities.where(provider: "github").last.token
      client = Octokit::Client.new(access_token: user_token)
      begin
        fetched_repo = client.repo(repo.info_hash[:full_name])
        repo.update!(
          github_id_code: fetched_repo.id,
          name: fetched_repo.name,
          description: fetched_repo.description,
          language: fetched_repo.language,
          fork: fetched_repo.fork,
          bytes_size: fetched_repo.size,
          watchers_count: fetched_repo.watchers,
          stargazers_count: fetched_repo.stargazers_count,
          info_hash: fetched_repo.to_hash,
        )
        repo.user&.touch(:github_repos_updated_at)
      rescue StandardError => e
        repo.destroy if e.message.include?("404 - Not Found")
      end
    end
  end

  private

  def clear_caches
    return if user.blank?

    user.touch
    cache_buster = CacheBuster.new
    cache_buster.bust user.path
    cache_buster.bust user.path + "?i=i"
    cache_buster.bust user.path + "/?i=i"
  end
end
