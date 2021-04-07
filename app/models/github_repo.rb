class GithubRepo < ApplicationRecord
  belongs_to :user

  serialize :info_hash, Hash

  validates :name, :url, :github_id_code, presence: true
  validates :url, url: true, uniqueness: true
  validates :github_id_code, uniqueness: true

  scope :featured, -> { where(featured: true) }

  before_destroy :clear_caches
  after_save :clear_caches

  # Update existing repository or create a new one with given params.
  # Repository is searched by either GitHub ID or URL.
  def self.upsert(user, **params)
    repo = user.github_repos
      .where(github_id_code: params[:github_id_code])
      .or(where(url: params[:url]))
      .first
    repo ||= new(params.merge(user_id: user.id))

    repo.update(params)

    repo
  end

  def self.update_to_latest
    where("updated_at < ?", 26.hours.ago).ids.each do |repo_id|
      GithubRepos::RepoSyncWorker.perform_async(repo_id)
    end
  end

  private

  def clear_caches
    return if user.blank?

    user.touch
    cache_bust = EdgeCache::Bust.new
    cache_bust.call(user.path)
    cache_bust.call("#{user.path}?i=i")
    cache_bust.call("#{user.path}/?i=i")
  end
end
