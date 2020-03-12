class GithubReposController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize GithubRepo

    client = create_octokit_client

    existing_user_repos = current_user.github_repos.where(featured: true).
      distinct.pluck(:github_id_code)

    @repos = client.repositories.map do |repo|
      repo.selected = existing_user_repos.include?(repo.id)
      repo
    end
  rescue Octokit::Unauthorized => e
    render json: { error: "Github Unauthorized: #{e.message}", status: 401 }, status: :unauthorized
  end

  def create
    authorize GithubRepo
    @repo = GithubRepo.find_or_create(fetched_repo_params(fetch_repo))
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

    repo = GithubRepo.find_or_create(fetched_repo_params(fetched_repo))

    current_user.touch(:github_repos_updated_at)

    if repo.valid?
      render json: { featured: repo.featured }
    else
      render json: "error: #{repo.errors.full_messages}"
    end
  end

  private

  def create_octokit_client
    current_user_token = current_user.identities.where(provider: "github").last.token
    client = Octokit::Client.new(access_token: current_user_token)
    client&.repositories&.sort_by!(&:name)
    client
  end

  def fetched_repo_params(fetched_repo)
    {
      github_id_code: fetched_repo.id,
      user_id: current_user.id,
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
