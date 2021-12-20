# -*- encoding: utf-8 -*-
# stub: acts-as-taggable-on 9.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "acts-as-taggable-on".freeze
  s.version = "9.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Joost Baaij".freeze]
  s.date = "2021-12-30"
  s.description = "With ActsAsTaggableOn, you can tag a single model on several contexts, such as skills, interests, and awards. It also provides other advanced functionality.".freeze
  s.email = ["michael@intridea.com".freeze, "joost@spacebabies.nl".freeze]
  s.files = [".github/workflows/spec.yml".freeze, ".gitignore".freeze, ".rspec".freeze, "Appraisals".freeze, "CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze, "Gemfile".freeze, "Guardfile".freeze, "LICENSE.md".freeze, "README.md".freeze, "Rakefile".freeze, "acts-as-taggable-on.gemspec".freeze, "db/migrate/1_acts_as_taggable_on_migration.rb".freeze, "db/migrate/2_add_missing_unique_indices.rb".freeze, "db/migrate/3_add_taggings_counter_cache_to_tags.rb".freeze, "db/migrate/4_add_missing_taggable_index.rb".freeze, "db/migrate/5_change_collation_for_tag_names.rb".freeze, "db/migrate/6_add_missing_indexes_on_taggings.rb".freeze, "db/migrate/7_add_tenant_to_taggings.rb".freeze, "docker-compose.yml".freeze, "gemfiles/activerecord_6.0.gemfile".freeze, "gemfiles/activerecord_6.1.gemfile".freeze, "gemfiles/activerecord_7.0.gemfile".freeze, "lib/acts-as-taggable-on.rb".freeze, "lib/acts_as_taggable_on.rb".freeze, "lib/acts_as_taggable_on/default_parser.rb".freeze, "lib/acts_as_taggable_on/engine.rb".freeze, "lib/acts_as_taggable_on/generic_parser.rb".freeze, "lib/acts_as_taggable_on/tag.rb".freeze, "lib/acts_as_taggable_on/tag_list.rb".freeze, "lib/acts_as_taggable_on/taggable.rb".freeze, "lib/acts_as_taggable_on/taggable/cache.rb".freeze, "lib/acts_as_taggable_on/taggable/collection.rb".freeze, "lib/acts_as_taggable_on/taggable/core.rb".freeze, "lib/acts_as_taggable_on/taggable/ownership.rb".freeze, "lib/acts_as_taggable_on/taggable/related.rb".freeze, "lib/acts_as_taggable_on/taggable/tag_list_type.rb".freeze, "lib/acts_as_taggable_on/taggable/tagged_with_query.rb".freeze, "lib/acts_as_taggable_on/taggable/tagged_with_query/all_tags_query.rb".freeze, "lib/acts_as_taggable_on/taggable/tagged_with_query/any_tags_query.rb".freeze, "lib/acts_as_taggable_on/taggable/tagged_with_query/exclude_tags_query.rb".freeze, "lib/acts_as_taggable_on/taggable/tagged_with_query/query_base.rb".freeze, "lib/acts_as_taggable_on/tagger.rb".freeze, "lib/acts_as_taggable_on/tagging.rb".freeze, "lib/acts_as_taggable_on/tags_helper.rb".freeze, "lib/acts_as_taggable_on/utils.rb".freeze, "lib/acts_as_taggable_on/version.rb".freeze, "lib/tasks/tags_collate_utf8.rake".freeze, "spec/acts_as_taggable_on/acts_as_taggable_on_spec.rb".freeze, "spec/acts_as_taggable_on/acts_as_tagger_spec.rb".freeze, "spec/acts_as_taggable_on/caching_spec.rb".freeze, "spec/acts_as_taggable_on/default_parser_spec.rb".freeze, "spec/acts_as_taggable_on/dirty_spec.rb".freeze, "spec/acts_as_taggable_on/generic_parser_spec.rb".freeze, "spec/acts_as_taggable_on/related_spec.rb".freeze, "spec/acts_as_taggable_on/single_table_inheritance_spec.rb".freeze, "spec/acts_as_taggable_on/tag_list_spec.rb".freeze, "spec/acts_as_taggable_on/tag_spec.rb".freeze, "spec/acts_as_taggable_on/taggable_spec.rb".freeze, "spec/acts_as_taggable_on/tagger_spec.rb".freeze, "spec/acts_as_taggable_on/tagging_spec.rb".freeze, "spec/acts_as_taggable_on/tags_helper_spec.rb".freeze, "spec/acts_as_taggable_on/utils_spec.rb".freeze, "spec/internal/app/models/altered_inheriting_taggable_model.rb".freeze, "spec/internal/app/models/cached_model.rb".freeze, "spec/internal/app/models/cached_model_with_array.rb".freeze, "spec/internal/app/models/columns_override_model.rb".freeze, "spec/internal/app/models/company.rb".freeze, "spec/internal/app/models/inheriting_taggable_model.rb".freeze, "spec/internal/app/models/market.rb".freeze, "spec/internal/app/models/non_standard_id_taggable_model.rb".freeze, "spec/internal/app/models/ordered_taggable_model.rb".freeze, "spec/internal/app/models/other_cached_model.rb".freeze, "spec/internal/app/models/other_taggable_model.rb".freeze, "spec/internal/app/models/student.rb".freeze, "spec/internal/app/models/taggable_model.rb".freeze, "spec/internal/app/models/untaggable_model.rb".freeze, "spec/internal/app/models/user.rb".freeze, "spec/internal/config/database.yml.sample".freeze, "spec/internal/db/schema.rb".freeze, "spec/spec_helper.rb".freeze, "spec/support/0-helpers.rb".freeze, "spec/support/array.rb".freeze, "spec/support/database.rb".freeze, "spec/support/database_cleaner.rb".freeze]
  s.homepage = "https://github.com/mbleigh/acts-as-taggable-on".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.2.22".freeze
  s.summary = "Advanced tagging for Rails.".freeze
  s.test_files = ["spec/acts_as_taggable_on/acts_as_taggable_on_spec.rb".freeze, "spec/acts_as_taggable_on/acts_as_tagger_spec.rb".freeze, "spec/acts_as_taggable_on/caching_spec.rb".freeze, "spec/acts_as_taggable_on/default_parser_spec.rb".freeze, "spec/acts_as_taggable_on/dirty_spec.rb".freeze, "spec/acts_as_taggable_on/generic_parser_spec.rb".freeze, "spec/acts_as_taggable_on/related_spec.rb".freeze, "spec/acts_as_taggable_on/single_table_inheritance_spec.rb".freeze, "spec/acts_as_taggable_on/tag_list_spec.rb".freeze, "spec/acts_as_taggable_on/tag_spec.rb".freeze, "spec/acts_as_taggable_on/taggable_spec.rb".freeze, "spec/acts_as_taggable_on/tagger_spec.rb".freeze, "spec/acts_as_taggable_on/tagging_spec.rb".freeze, "spec/acts_as_taggable_on/tags_helper_spec.rb".freeze, "spec/acts_as_taggable_on/utils_spec.rb".freeze, "spec/internal/app/models/altered_inheriting_taggable_model.rb".freeze, "spec/internal/app/models/cached_model.rb".freeze, "spec/internal/app/models/cached_model_with_array.rb".freeze, "spec/internal/app/models/columns_override_model.rb".freeze, "spec/internal/app/models/company.rb".freeze, "spec/internal/app/models/inheriting_taggable_model.rb".freeze, "spec/internal/app/models/market.rb".freeze, "spec/internal/app/models/non_standard_id_taggable_model.rb".freeze, "spec/internal/app/models/ordered_taggable_model.rb".freeze, "spec/internal/app/models/other_cached_model.rb".freeze, "spec/internal/app/models/other_taggable_model.rb".freeze, "spec/internal/app/models/student.rb".freeze, "spec/internal/app/models/taggable_model.rb".freeze, "spec/internal/app/models/untaggable_model.rb".freeze, "spec/internal/app/models/user.rb".freeze, "spec/internal/config/database.yml.sample".freeze, "spec/internal/db/schema.rb".freeze, "spec/spec_helper.rb".freeze, "spec/support/0-helpers.rb".freeze, "spec/support/array.rb".freeze, "spec/support/database.rb".freeze, "spec/support/database_cleaner.rb".freeze]

  s.installed_by_version = "3.2.22" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.0", "< 7.1"])
    s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<barrier>.freeze, [">= 0"])
    s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 6.0", "< 7.1"])
    s.add_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<barrier>.freeze, [">= 0"])
    s.add_dependency(%q<database_cleaner>.freeze, [">= 0"])
  end
end
