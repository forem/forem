# Note: on Travis, this Gemfile is only for installing
# dependencies. The actual builds use the Gemfiles in
# the gemspecs/* directory.

filename = "gemfiles/common"
instance_eval(IO.read(filename), filename, 1)

group :test do
  gem "rspec", "~> 3.4"
end

if ENV["USE_INSTALLED_GUARD_RSPEC"] == "1"
  gem "guard-rspec"
else
  gemspec development_group: :gem_build_tools
end

group :gem_build_tools do
end

group :development do
  gem "rubocop", require: false
  gem "guard-rubocop", require: false
  gem "guard-compat", ">= 0.0.2", require: false
end
