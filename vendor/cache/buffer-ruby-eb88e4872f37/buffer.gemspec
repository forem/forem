# -*- encoding: utf-8 -*-
# stub: buffer 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "buffer".freeze
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["ZPH".freeze]
  s.date = "2021-03-25"
  s.description = "Buffer is an API Wrapper Gem for Bufferapp.com's API".freeze
  s.email = ["Zander@civet.ws".freeze]
  s.executables = ["buffer".freeze]
  s.files = [".bufferapprc.template".freeze, ".gitignore".freeze, ".rubocop.yml".freeze, ".ruby-version".freeze, ".travis.yml".freeze, "API_COVERAGE.md".freeze, "Gemfile".freeze, "Guardfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "TODO.md".freeze, "bin/buffer".freeze, "buffer.gemspec".freeze, "lib/buffer.rb".freeze, "lib/buffer/client.rb".freeze, "lib/buffer/core.rb".freeze, "lib/buffer/datastructure.rb".freeze, "lib/buffer/encode.rb".freeze, "lib/buffer/error.rb".freeze, "lib/buffer/info.rb".freeze, "lib/buffer/link.rb".freeze, "lib/buffer/profile.rb".freeze, "lib/buffer/update.rb".freeze, "lib/buffer/user.rb".freeze, "lib/buffer/version.rb".freeze, "spec/fixtures/destroy.txt".freeze, "spec/fixtures/info.txt".freeze, "spec/fixtures/interactions_by_update_id.txt".freeze, "spec/fixtures/link.txt".freeze, "spec/fixtures/profile_authenticated.txt".freeze, "spec/fixtures/profile_schedules_by_id.txt".freeze, "spec/fixtures/profiles_by_id.txt".freeze, "spec/fixtures/update_by_id.txt".freeze, "spec/fixtures/update_by_id_non_auth.txt".freeze, "spec/fixtures/updates_by_profile_id.txt".freeze, "spec/fixtures/updates_by_profile_id_pending.txt".freeze, "spec/fixtures/user_authenticated.txt".freeze, "spec/lib/buffer/encode_spec.rb".freeze, "spec/lib/buffer/link_spec.rb".freeze, "spec/lib/buffer/profile_spec.rb".freeze, "spec/lib/buffer/schedule_spec.rb".freeze, "spec/lib/buffer/update_spec.rb".freeze, "spec/lib/buffer/user_spec.rb".freeze, "spec/lib/buffer_spec.rb".freeze, "spec/lib/core_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "http://github.com/bufferapp/buffer-ruby".freeze
  s.rubygems_version = "3.2.3".freeze
  s.summary = "Buffer is an API Wrapper Gem for Bufferapp.com's API".freeze
  s.test_files = ["spec/fixtures/destroy.txt".freeze, "spec/fixtures/info.txt".freeze, "spec/fixtures/interactions_by_update_id.txt".freeze, "spec/fixtures/link.txt".freeze, "spec/fixtures/profile_authenticated.txt".freeze, "spec/fixtures/profile_schedules_by_id.txt".freeze, "spec/fixtures/profiles_by_id.txt".freeze, "spec/fixtures/update_by_id.txt".freeze, "spec/fixtures/update_by_id_non_auth.txt".freeze, "spec/fixtures/updates_by_profile_id.txt".freeze, "spec/fixtures/updates_by_profile_id_pending.txt".freeze, "spec/fixtures/user_authenticated.txt".freeze, "spec/lib/buffer/encode_spec.rb".freeze, "spec/lib/buffer/link_spec.rb".freeze, "spec/lib/buffer/profile_spec.rb".freeze, "spec/lib/buffer/schedule_spec.rb".freeze, "spec/lib/buffer/update_spec.rb".freeze, "spec/lib/buffer/user_spec.rb".freeze, "spec/lib/buffer_spec.rb".freeze, "spec/lib/core_spec.rb".freeze, "spec/spec_helper.rb".freeze]

  s.installed_by_version = "3.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard-bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rb-fsevent>.freeze, [">= 0"])
    s.add_development_dependency(%q<growl>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry-uber>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<yajl-ruby>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<faraday_middleware>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<faraday>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<hashie>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<addressable>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<environs>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<webmock>.freeze, [">= 0"])
    s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_dependency(%q<guard-bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rb-fsevent>.freeze, [">= 0"])
    s.add_dependency(%q<growl>.freeze, [">= 0"])
    s.add_dependency(%q<pry-uber>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<yajl-ruby>.freeze, [">= 0"])
    s.add_dependency(%q<faraday_middleware>.freeze, [">= 0"])
    s.add_dependency(%q<faraday>.freeze, [">= 0"])
    s.add_dependency(%q<hashie>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<addressable>.freeze, [">= 0"])
    s.add_dependency(%q<environs>.freeze, [">= 0"])
  end
end
