desc "This task is called by the Heroku scheduler add-on"

task github_repo_fetch_all: :environment do
  GithubRepo.update_to_latest
end
