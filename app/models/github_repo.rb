class GithubRepo < ApplicationRecord
  belongs_to :user

  validates :name, :url, presence: true
  validates :url, uniqueness: true
  validates :github_id_code, uniqueness: true

  after_save :clear_caches
  before_destroy :clear_caches

  def self.find_or_create(github_url, params = {})
    repo = where(url: github_url).first_or_initialize
    repo.update(params)
    repo
  end

  def self.update_to_latest
    where("updated_at < ?", 1.day.ago).find_each do |repo|
      user_token = User.find_by_id(repo.user_id).identities.where(provider: "github").last.token
      client = Octokit::Client.new(access_token: user_token)
      fetched_repo = client.repositories.select do |fresh_repo|
        if repo[:github_id_code]
          fresh_repo.id == repo[:github_id_code]
        else
          fresh_repo.html_url == repo[:url]
        end
      end.first
      repo.update(
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
    end
  end

  private

  def clear_caches
    if user.present?
      user.touch
      CacheBuster.new.bust user.path
      CacheBuster.new.bust user.path + "?i=i"
      CacheBuster.new.bust user.path + "/?i=i"
    end
  end
end
