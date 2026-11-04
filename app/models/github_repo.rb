class GithubRepo < ApplicationRecord
  belongs_to :user

  serialize :info_hash, coder: YAML, type: Hash

  validates :name, :url, :github_id_code, presence: true
  # Organization repositories are visible to all of the organization's members,
  # so each user must be able to pin the same repository independently.
  validates :url, url: true, uniqueness: { scope: :user_id }
  validates :github_id_code, uniqueness: { scope: :user_id }

  scope :featured, -> { where(featured: true) }

  before_destroy :clear_caches
  after_save :clear_caches

  # Update existing repository or create a new one with given params.
  # Repository is searched by either GitHub ID or URL, among the user's own repositories.
  def self.upsert(user, **params)
    repo = user.github_repos
      .where(github_id_code: params[:github_id_code])
      .or(user.github_repos.where(url: params[:url]))
      .first
    repo ||= new(params.merge(user_id: user.id))

    repo.update(params)

    repo
  end

  def self.update_to_latest
    ids = where(updated_at: ...26.hours.ago).ids.map { |id| [id] }
    GithubRepos::RepoSyncWorker.perform_bulk(ids)
  end

  # Login of the GitHub user or organization owning the repository.
  def owner_login
    info_hash.dig(:owner, :login)
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
