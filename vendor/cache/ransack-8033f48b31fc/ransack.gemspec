# -*- encoding: utf-8 -*-
# stub: ransack 2.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "ransack".freeze
  s.version = "2.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ernie Miller".freeze, "Ryan Bigg".freeze, "Jon Atack".freeze, "Sean Carroll".freeze]
  s.date = "2020-12-21"
  s.description = "Ransack is the successor to the MetaSearch gem. It improves and expands upon MetaSearch's functionality, but does not have a 100%-compatible API.".freeze
  s.email = ["ernie@erniemiller.org".freeze, "radarlistener@gmail.com".freeze, "jonnyatack@gmail.com".freeze, "sfcarroll@gmail.com".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "lib/polyamorous/activerecord_5.2_ruby_2/join_association.rb".freeze, "lib/polyamorous/activerecord_5.2_ruby_2/join_dependency.rb".freeze, "lib/polyamorous/activerecord_5.2_ruby_2/reflection.rb".freeze, "lib/polyamorous/activerecord_6.0_ruby_2/join_association.rb".freeze, "lib/polyamorous/activerecord_6.0_ruby_2/join_dependency.rb".freeze, "lib/polyamorous/activerecord_6.0_ruby_2/reflection.rb".freeze, "lib/polyamorous/activerecord_6.1_ruby_2/join_association.rb".freeze, "lib/polyamorous/activerecord_6.1_ruby_2/join_dependency.rb".freeze, "lib/polyamorous/activerecord_6.1_ruby_2/reflection.rb".freeze, "lib/polyamorous/join.rb".freeze, "lib/polyamorous/polyamorous.rb".freeze, "lib/polyamorous/swapping_reflection_class.rb".freeze, "lib/polyamorous/tree_node.rb".freeze, "lib/ransack.rb".freeze, "lib/ransack/adapters.rb".freeze, "lib/ransack/adapters/active_record.rb".freeze, "lib/ransack/adapters/active_record/base.rb".freeze, "lib/ransack/adapters/active_record/context.rb".freeze, "lib/ransack/adapters/active_record/ransack/constants.rb".freeze, "lib/ransack/adapters/active_record/ransack/context.rb".freeze, "lib/ransack/adapters/active_record/ransack/nodes/condition.rb".freeze, "lib/ransack/adapters/active_record/ransack/translate.rb".freeze, "lib/ransack/adapters/active_record/ransack/visitor.rb".freeze, "lib/ransack/configuration.rb".freeze, "lib/ransack/constants.rb".freeze, "lib/ransack/context.rb".freeze, "lib/ransack/helpers.rb".freeze, "lib/ransack/helpers/form_builder.rb".freeze, "lib/ransack/helpers/form_helper.rb".freeze, "lib/ransack/locale/ar.yml".freeze, "lib/ransack/locale/az.yml".freeze, "lib/ransack/locale/bg.yml".freeze, "lib/ransack/locale/ca.yml".freeze, "lib/ransack/locale/cs.yml".freeze, "lib/ransack/locale/da.yml".freeze, "lib/ransack/locale/de.yml".freeze, "lib/ransack/locale/el.yml".freeze, "lib/ransack/locale/en.yml".freeze, "lib/ransack/locale/es.yml".freeze, "lib/ransack/locale/fa.yml".freeze, "lib/ransack/locale/fi.yml".freeze, "lib/ransack/locale/fr.yml".freeze, "lib/ransack/locale/hu.yml".freeze, "lib/ransack/locale/id.yml".freeze, "lib/ransack/locale/it.yml".freeze, "lib/ransack/locale/ja.yml".freeze, "lib/ransack/locale/nl.yml".freeze, "lib/ransack/locale/pt-BR.yml".freeze, "lib/ransack/locale/ro.yml".freeze, "lib/ransack/locale/ru.yml".freeze, "lib/ransack/locale/sk.yml".freeze, "lib/ransack/locale/tr.yml".freeze, "lib/ransack/locale/zh-CN.yml".freeze, "lib/ransack/locale/zh-TW.yml".freeze, "lib/ransack/naming.rb".freeze, "lib/ransack/nodes.rb".freeze, "lib/ransack/nodes/attribute.rb".freeze, "lib/ransack/nodes/bindable.rb".freeze, "lib/ransack/nodes/condition.rb".freeze, "lib/ransack/nodes/grouping.rb".freeze, "lib/ransack/nodes/node.rb".freeze, "lib/ransack/nodes/sort.rb".freeze, "lib/ransack/nodes/value.rb".freeze, "lib/ransack/predicate.rb".freeze, "lib/ransack/ransacker.rb".freeze, "lib/ransack/search.rb".freeze, "lib/ransack/translate.rb".freeze, "lib/ransack/version.rb".freeze, "lib/ransack/visitor.rb".freeze, "logo/ransack-h.png".freeze, "logo/ransack-h.svg".freeze, "logo/ransack-v.png".freeze, "logo/ransack-v.svg".freeze, "logo/ransack.png".freeze, "logo/ransack.svg".freeze, "ransack.gemspec".freeze, "spec/blueprints/articles.rb".freeze, "spec/blueprints/comments.rb".freeze, "spec/blueprints/notes.rb".freeze, "spec/blueprints/people.rb".freeze, "spec/blueprints/tags.rb".freeze, "spec/console.rb".freeze, "spec/helpers/polyamorous_helper.rb".freeze, "spec/helpers/ransack_helper.rb".freeze, "spec/polyamorous/join_association_spec.rb".freeze, "spec/polyamorous/join_dependency_spec.rb".freeze, "spec/polyamorous/join_spec.rb".freeze, "spec/ransack/adapters/active_record/base_spec.rb".freeze, "spec/ransack/adapters/active_record/context_spec.rb".freeze, "spec/ransack/configuration_spec.rb".freeze, "spec/ransack/helpers/form_builder_spec.rb".freeze, "spec/ransack/helpers/form_helper_spec.rb".freeze, "spec/ransack/nodes/condition_spec.rb".freeze, "spec/ransack/nodes/grouping_spec.rb".freeze, "spec/ransack/predicate_spec.rb".freeze, "spec/ransack/search_spec.rb".freeze, "spec/ransack/translate_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/support/en.yml".freeze, "spec/support/schema.rb".freeze]
  s.homepage = "https://github.com/activerecord-hackery/ransack".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Object-based searching for Active Record and Mongoid (currently).".freeze
  s.test_files = ["spec/blueprints/articles.rb".freeze, "spec/blueprints/comments.rb".freeze, "spec/blueprints/notes.rb".freeze, "spec/blueprints/people.rb".freeze, "spec/blueprints/tags.rb".freeze, "spec/console.rb".freeze, "spec/helpers/polyamorous_helper.rb".freeze, "spec/helpers/ransack_helper.rb".freeze, "spec/polyamorous/join_association_spec.rb".freeze, "spec/polyamorous/join_dependency_spec.rb".freeze, "spec/polyamorous/join_spec.rb".freeze, "spec/ransack/adapters/active_record/base_spec.rb".freeze, "spec/ransack/adapters/active_record/context_spec.rb".freeze, "spec/ransack/configuration_spec.rb".freeze, "spec/ransack/helpers/form_builder_spec.rb".freeze, "spec/ransack/helpers/form_helper_spec.rb".freeze, "spec/ransack/nodes/condition_spec.rb".freeze, "spec/ransack/nodes/grouping_spec.rb".freeze, "spec/ransack/predicate_spec.rb".freeze, "spec/ransack/search_spec.rb".freeze, "spec/ransack/translate_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/support/en.yml".freeze, "spec/support/schema.rb".freeze]

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.2.4"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2.4"])
    s.add_runtime_dependency(%q<i18n>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 5.2.4"])
    s.add_dependency(%q<activesupport>.freeze, [">= 5.2.4"])
    s.add_dependency(%q<i18n>.freeze, [">= 0"])
  end
end
