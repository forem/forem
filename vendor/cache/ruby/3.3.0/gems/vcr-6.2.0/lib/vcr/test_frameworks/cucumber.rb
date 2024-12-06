module VCR
  # Provides integration with Cucumber using tags.
  class CucumberTags
    class << self
      # @private
      def tags
        @tags.dup
      end

      # @private
      def add_tag(tag)
        @tags << tag
      end
    end

    @tags = []

    # @private
    def initialize(main_object)
      @main_object = main_object
    end

    # Adds `Before` and `After` cucumber hooks for the named tags that
    # will cause a VCR cassette to be used for scenarios with matching tags.
    #
    # @param tag_names [Array<String,Hash>] the cucumber scenario tags. If
    #  the last argument is a hash it is treated as cassette options.
    #   - `:use_scenario_name => true` to automatically name the
    #     cassette according to the scenario name.
    def tags(*tag_names)
      original_options = tag_names.last.is_a?(::Hash) ? tag_names.pop : {}
      tag_names.each do |tag_name|
        tag_name = "@#{tag_name}" unless tag_name =~ /\A@/

        # It would be nice to use an Around hook here, but
        # cucumber has a bug: background steps do not run
        # within an around hook.
        # https://gist.github.com/652968
        @main_object.Before(tag_name) do |scenario|
          options = original_options.dup

          cassette_name = if options.delete(:use_scenario_name)
            if scenario.respond_to?(:outline?) && scenario.outline?
              ScenarioNameBuilder.new(scenario).cassette_name
            elsif scenario.respond_to?(:scenario_outline)
              [ scenario.scenario_outline.feature.name.split("\n").first,
                scenario.scenario_outline.name,
                scenario.name.split("\n").first
              ].join("/")
            elsif scenario.respond_to?(:feature)
              [ scenario.feature.name.split("\n").first,
                scenario.name.split("\n").first
              ].join("/")
            elsif scenario.location.lines.min == scenario.location.lines.max
              # test case from a regular scenario in cucumber version 4
              [ scenario.location.file.split("/").last.split(".").first,
                scenario.name.split("\n").first
              ].join("/")
            else
              # test case from a scenario with examples ("scenario outline") in cucumber version 4
              [ scenario.location.file.split("/").last.split(".").first,
                scenario.name.split("\n").first,
                "Example at line #{scenario.location.lines.max}"
              ].join("/")
            end
          else
            "cucumber_tags/#{tag_name.gsub(/\A@/, '')}"
          end

          VCR.insert_cassette(cassette_name, options)
        end

        @main_object.After(tag_name) do |scenario|
          VCR.eject_cassette(:skip_no_unused_interactions_assertion => scenario.failed?)
        end

        self.class.add_tag(tag_name)
      end
    end
    alias :tag :tags

    # Constructs a cassette name from a Cucumber 2 scenario outline
    # @private
    class ScenarioNameBuilder
      def initialize(test_case)
        @parts = []
        test_case.describe_source_to self
      end

      def cassette_name
        @parts.join("/")
      end

      def feature(feature)
        @parts.unshift feature.name
        self
      end
      alias scenario_outline feature

      def scenario(*) self end
      alias examples_table scenario

      def examples_table_row(row)
        @parts.unshift "| %s |" % row.values.join(" | ")
        self
      end
    end
  end
end
