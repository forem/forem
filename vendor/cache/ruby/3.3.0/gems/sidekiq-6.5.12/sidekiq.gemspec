require_relative "lib/sidekiq/version"

Gem::Specification.new do |gem|
  gem.authors = ["Mike Perham"]
  gem.email = ["mperham@gmail.com"]
  gem.summary = "Simple, efficient background processing for Ruby"
  gem.description = "Simple, efficient background processing for Ruby."
  gem.homepage = "https://sidekiq.org"
  gem.license = "LGPL-3.0"

  gem.executables = ["sidekiq", "sidekiqmon"]
  gem.files = ["sidekiq.gemspec", "README.md", "Changes.md", "LICENSE"] + `git ls-files | grep -E '^(bin|lib|web)'`.split("\n")
  gem.name = "sidekiq"
  gem.version = Sidekiq::VERSION
  gem.required_ruby_version = ">= 2.5.0"

  gem.metadata = {
    "homepage_uri" => "https://sidekiq.org",
    "bug_tracker_uri" => "https://github.com/mperham/sidekiq/issues",
    "documentation_uri" => "https://github.com/mperham/sidekiq/wiki",
    "changelog_uri" => "https://github.com/mperham/sidekiq/blob/main/Changes.md",
    "source_code_uri" => "https://github.com/mperham/sidekiq"
  }

  gem.add_dependency "redis", ["<5", ">= 4.5.0"]
  gem.add_dependency "connection_pool", ["<3", ">= 2.2.5"]
  gem.add_dependency "rack", "~> 2.0"
end
