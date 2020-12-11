source "https://rubygems.org"

gemspec

branch = File.read(File.expand_path("../maintenance-branch", __FILE__)).chomp
%w[rspec rspec-expectations rspec-mocks rspec-support].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => branch
  end
end

if RUBY_VERSION < '1.9.3'
  gem 'rake', '< 11.0.0' # rake 11 requires Ruby 1.9.3 or later
elsif RUBY_VERSION < '2.0.0'
  gem 'rake', '< 12.0.0' # rake 12 requires Ruby 2.0.0 or later
else
  gem 'rake', '> 12.3.2'
end

if ENV['DIFF_LCS_VERSION']
  gem 'diff-lcs', ENV['DIFF_LCS_VERSION']
else
  gem 'diff-lcs', '~> 1.4', '>= 1.4.3'
end

### deps for rdoc.info
group :documentation do
  gem 'redcarpet', :platform => :mri
  gem 'github-markup', :platform => :mri
  gem 'yard', '~> 0.9.24', :require => false
end

if RUBY_VERSION < '2.0.0'
  gem 'thor', '< 1.0.0'
else
  gem 'thor', '> 1.0.0'
end

if RUBY_VERSION < '2.0.0' || RUBY_ENGINE == 'java'
  gem 'json', '< 2.0.0'
else
  gem 'json', '> 2.3.0'
end

if RUBY_VERSION < '2.2.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem 'ffi', '< 1.10'
elsif RUBY_VERSION < '2.0'
  gem 'ffi', '< 1.9.19' # ffi dropped Ruby 1.8 support in 1.9.19
elsif RUBY_VERSION < '2.3.0'
  gem 'ffi', '~> 1.12.0'
else
  # Until 1.13.2 is released due to Rubygems usage
  gem 'ffi', '~> 1.12.0'
end

if RUBY_VERSION < '2.3.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem "childprocess", "< 1.0.0"
elsif RUBY_VERSION < '2.0.0'
  gem "childprocess", "< 1.0.0"
else
  gem "childprocess", "> 1.0.0"
end

platforms :jruby do
  if RUBY_VERSION < '1.9.0'
    # Pin jruby-openssl on older J Ruby
    gem "jruby-openssl", "< 0.10.0"
  else
    gem "jruby-openssl"
  end
end

group :coverage do
  gem 'simplecov', '~> 0.8'
end

# No need to run rubocop on earlier versions
if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  gem "rubocop", "~> 0.52.1"
end

gem 'test-unit', '~> 3.0' if RUBY_VERSION.to_f >= 2.2

# Version 5.12 of minitest requires Ruby 2.4
if RUBY_VERSION < '2.4.0'
  gem 'minitest', '< 5.12.0'
end

gem 'contracts', '< 0.16' if RUBY_VERSION < '1.9.0'

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
