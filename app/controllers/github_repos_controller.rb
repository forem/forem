class GithubReposController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize GithubRepo
    known_repositories = current_user.github_repos.featured.distinct.to_a

    # NOTE: this will invoke autopaging, by issuing multiple calls to GitHub
    # to fetch all of the user's repositories. This could eventually become slow
    @repos = fetch_repositories_from_github(known_repositories)
  rescue Github::Errors::Unauthorized => e
    render json: { error: "GitHub Unauthorized: #{e.message}", status: 401 }, status: :unauthorized
  end

  def update_or_create
    authorize GithubRepo

    params[:github_repo] = JSON.parse(params[:github_repo])

    fetched_repo = fetch_repository_from_github(repo_params[:github_id_code])
    unless fetched_repo
      render json: { error: "GitHub repository not found", status: 404 }, status: :not_found
      return
    end

    repo = GithubRepo.upsert(current_user, **fetched_repo_params(fetched_repo))

    current_user.touch(:github_repos_updated_at)

    if repo.valid?
      render json: { featured: repo.featured }
    else
      render json: { error: repo.errors.full_messages, status: 422 }, status: :unprocessable_entity
    end
  end

  private

  def fetch_repositories_from_github(known_repositories)
    client = Github::OauthClient.for_user(current_user)

    repos = client.repositories(visibility: :public).map do |repo|
      if (known_index = known_repositories.find_index { |known| known.github_id_code == repo.id })
        repo.featured = true
        known_repositories.delete_at(known_index)
      end
      repo
    end

    # Remove pinned repositorioes that were removed from GH or are now private,
    # since the user will not be able to remove them by themselves.
    known_repositories.each(&:destroy)

    repos.sort_by(&:name)
  end

  def fetch_repository_from_github(repository_id)
    client = Github::OauthClient.for_user(current_user)

    client.repository(repository_id)
  rescue Github::Errors::NotFound
    nil
  end

  def fetched_repo_params(fetched_repo)
    {
      github_id_code: fetched_repo.id,
      name: fetched_repo.name,
      description: fetched_repo.description,
      language: fetched_repo.language,
      fork: fetched_repo.fork,
      url: fetched_repo.html_url,
      bytes_size: fetched_repo.size,
      watchers_count: fetched_repo.watchers,
      stargazers_count: fetched_repo.stargazers_count,
      featured: repo_params[:featured],
      info_hash: fetched_repo.to_hash
    }
  end

  def repo_params
    permitted_attributes(GithubRepo)
  end
end
