module AlgoliaSearch
  module Utilities
    class << self
      def get_model_classes
        if Rails.application && defined?(Rails.autoloaders) && Rails.autoloaders.zeitwerk_enabled?
          Zeitwerk::Loader.eager_load_all
        elsif Rails.application
          Rails.application.eager_load!
        end
        AlgoliaSearch.instance_variable_get :@included_in
      end

      def clear_all_indexes
        get_model_classes.each do |klass|
          klass.clear_index!
        end
      end

      def reindex_all_models
        klasses = get_model_classes

        puts ''
        puts "Reindexing #{klasses.count} models: #{klasses.to_sentence}."
        puts ''

        klasses.each do |klass|
          puts klass
          puts "Reindexing #{klass.count} records..."
          klass.algolia_reindex
        end
      end

      def set_settings_all_models
        klasses = get_model_classes

        puts ''
        puts "Pushing settings for #{klasses.count} models: #{klasses.to_sentence}."
        puts ''

        klasses.each do |klass|
          puts "Pushing #{klass} settings..."
          klass.algolia_set_settings
        end
      end
    end
  end
end

