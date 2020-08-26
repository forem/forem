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
    where("updated_at < ?", 26.hours.ago).includes(:user).find_each do |repo|
      user = repo.user
      next unless user

      client = Github::OauthClient.for_user(user)
      begin
        fetched_repo = client.repository(repo.info_hash[:full_name])

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
      rescue Github::Errors::NotFound
        repo.destroy
      rescue StandardError
        next
      end
    end
  end

  private

  def clear_caches
    return if user.blank?

    user.touch
    CacheBuster.bust(user.path)
    CacheBuster.bust("#{user.path}?i=i")
    CacheBuster.bust("#{user.path}/?i=i")
  end
end
