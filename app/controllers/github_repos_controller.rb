class GithubReposController < ApplicationController
  def create
    @client = create_octokit_client
    @repo = GithubRepo.find_or_create(github_repo_params[:url], fetched_repo_params)
    redirect_to "/settings/integrations", notice: "GitHub repo added"
  end

  def update
    @repo = GithubRepo.find(params[:id])
    @repo.update(featured: false)
    redirect_to "/settings/integrations", notice: "GitHub repo added"
  end

  private

  def create_octokit_client
    current_user_token = current_user.identities.where(provider: "github").last.token
    client = Octokit::Client.new(access_token: current_user_token)
    client.repositories.sort_by!(&:name) if client
    client
  end

  def fetched_repo_params
    fetched_repo = @client.repositories.select do |repo|
      repo.id == github_repo_params[:github_id_code].to_i
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
      info_hash: fetched_repo.to_hash,
    }
  end

  def github_repo_params
    params.require(:github_repo).permit(:github_id_code)
  end
end
