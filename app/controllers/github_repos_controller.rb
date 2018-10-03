class GithubReposController < ApplicationController
  after_action :verify_authorized

  def create
    authorize GithubRepo
    @client = create_octokit_client
    @repo = GithubRepo.find_or_create(fetched_repo_params)
    if @repo.valid?
      redirect_to "/settings/integrations", notice: "GitHub repo added"
    else
      redirect_to "/settings/integrations",
        error: "There was an error adding your Github repo"
    end
  end

  def update
    @repo = GithubRepo.find(params[:id])
    authorize @repo
    if @repo.update(featured: false)
      redirect_to "/settings/integrations", notice: "GitHub repo added"
    else
      redirect_to "/settings/integrations",
        error: "There was an error removing your Github repo"
    end
  end

  private

  def create_octokit_client
    current_user_token = current_user.identities.where(provider: "github").last.token
    client = Octokit::Client.new(access_token: current_user_token)
    client&.repositories&.sort_by!(&:name)
    client
  end

  def fetched_repo_params
    fetched_repo = @client.repositories.select do |repo|
      repo.id == permitted_attributes(GithubRepo)[:github_id_code].to_i
    end.first
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
      featured: true,
      info_hash: fetched_repo.to_hash
    }
  end
end
