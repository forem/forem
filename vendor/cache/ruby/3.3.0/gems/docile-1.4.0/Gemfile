# frozen_string_literal: true

source "https://rubygems.org"

# CI-only dependencies go here
if ENV["CI"] == "true" # rubocop:disable Style/IfUnlessModifier
  gem "simplecov-cobertura", require: false, group: "test"
end

# Specify gem's dependencies in docile.gemspec
gemspec

group :test do
  gem "rspec", "~> 3.10"
  gem "simplecov", require: false
end

# Excluded from CI except on latest MRI Ruby, to reduce compatibility burden
group :checks do
  gem "panolint", github: "panorama-ed/panolint", branch: "main"
end

# Optional, only used locally to release to rubygems.org
group :release, optional: true do
  gem "rake"
end
