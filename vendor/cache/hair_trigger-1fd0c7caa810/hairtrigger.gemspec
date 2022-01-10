# -*- encoding: utf-8 -*-
# stub: hairtrigger 0.2.24 ruby lib

Gem::Specification.new do |s|
  s.name = "hairtrigger".freeze
  s.version = "0.2.24"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jon Jensen".freeze]
  s.date = "2022-01-10"
  s.description = "allows you to declare database triggers in ruby in your models, and then generate appropriate migrations as they change".freeze
  s.email = "jenseng@gmail.com".freeze
  s.files = ["LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/hair_trigger.rb".freeze, "lib/hair_trigger/adapter.rb".freeze, "lib/hair_trigger/base.rb".freeze, "lib/hair_trigger/builder.rb".freeze, "lib/hair_trigger/migration_reader.rb".freeze, "lib/hair_trigger/migrator.rb".freeze, "lib/hair_trigger/railtie.rb".freeze, "lib/hair_trigger/schema_dumper.rb".freeze, "lib/hair_trigger/version.rb".freeze, "lib/hairtrigger.rb".freeze, "lib/tasks/hair_trigger.rake".freeze]
  s.homepage = "http://github.com/jenseng/hair_trigger".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.2.22".freeze
  s.summary = "easy database triggers for active record".freeze

  s.installed_by_version = "3.2.22" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.0", "< 8"])
    s.add_runtime_dependency(%q<ruby_parser>.freeze, ["~> 3.10"])
    s.add_runtime_dependency(%q<ruby2ruby>.freeze, ["~> 2.4"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 5.0", "< 8"])
    s.add_dependency(%q<ruby_parser>.freeze, ["~> 3.10"])
    s.add_dependency(%q<ruby2ruby>.freeze, ["~> 2.4"])
  end
end
