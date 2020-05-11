class GithubReposController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize GithubRepo

    known_repositories_ids = current_user.github_repos.featured.distinct.pluck(:github_id_code)

    # NOTE: this will invoke autopaging, by issuing multiple calls to GitHub
    # to fetch all of the user's repositories. This could eventually become slow
    @repos = fetch_repositories_from_github(known_repositories_ids)
  rescue Octokit::Unauthorized => e
    render json: { error: "GitHub Unauthorized: #{e.message}", status: 401 }, status: :unauthorized
  end

  def create
    authorize GithubRepo

    @repo = GithubRepo.upsert(current_user, fetched_repo_params(fetch_repo))

    current_user.touch(:github_repos_updated_at)

    if @repo.valid?
      redirect_to "/settings/integrations", notice: "GitHub repo added"
    else
      redirect_to "/settings/integrations",
                  error: "There was an error adding your Github repo"
    end
  end

  def update
    @repo = GithubRepo.find(params[:id])
    current_user.touch(:github_repos_updated_at)
    authorize @repo
    if @repo.update(featured: false)
      redirect_to "/settings/integrations", notice: "GitHub repo added"
    else
      redirect_to "/settings/integrations",
                  error: "There was an error removing your Github repo"
    end
  end

  def update_or_create
    authorize GithubRepo

    params[:github_repo] = JSON.parse(params[:github_repo])
    fetched_repo = fetch_repo
    unless fetched_repo
      render json: "error: Could not find Github repo", status: :not_found
      return
    end

    repo = GithubRepo.upsert(current_user, fetched_repo_params(fetched_repo))

    current_user.touch(:github_repos_updated_at)

    if repo.valid?
      render json: { featured: repo.featured }
    else
      render json: "error: #{repo.errors.full_messages}"
    end
  end

  private

  # TODO: use Github::UserClient or something
  def create_octokit_client
    current_user_token = current_user.identities.where(provider: "github").last.token
    Octokit::Client.new(access_token: current_user_token)
  end

  def fetch_repositories_from_github(known_repositories_ids)
    client = create_octokit_client

    client.repositories(visibility: :public).map do |repo|
      repo.featured = known_repositories_ids.include?(repo.id)
      repo
    end.sort_by(&:name)
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

  def fetch_repo
    client = create_octokit_client

    client.repositories.detect do |repo|
      repo.id == repo_params[:github_id_code].to_i
    end
  end

  def repo_params
    permitted_attributes(GithubRepo)
  end
end
