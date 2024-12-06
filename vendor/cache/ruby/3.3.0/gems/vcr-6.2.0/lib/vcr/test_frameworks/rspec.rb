module VCR
  # Integrates VCR with RSpec.
  module RSpec
    # @private
    module Metadata
      extend self

      def vcr_cassette_name_for(metadata)
        description = 
          if metadata[:description].empty?
            # we have an "it { is_expected.to be something }" block
            metadata[:scoped_id]
          else
            metadata[:description]
          end
        example_group = 
          if metadata.key?(:example_group)
            metadata[:example_group]
          else
            metadata[:parent_example_group]
          end

        if example_group
          [vcr_cassette_name_for(example_group), description].join('/')
        else
          description
        end
      end

      def configure!
        ::RSpec.configure do |config|

          when_tagged_with_vcr = { :vcr => lambda { |v| !!v } }

          config.before(:each, when_tagged_with_vcr) do |ex|
            example = ex.respond_to?(:metadata) ? ex : ex.example

            cassette_name = nil
            options = example.metadata[:vcr]
            options = case options
                      when Hash #=> vcr: { cassette_name: 'foo' }
                        options.dup
                      when String #=> vcr: 'bar'
                        cassette_name = options.dup
                        {}
                      else #=> :vcr or vcr: true
                        {}
                      end

            cassette_name ||= options.delete(:cassette_name) ||
                              VCR::RSpec::Metadata.vcr_cassette_name_for(example.metadata)
            VCR.insert_cassette(cassette_name, options)
          end

          config.after(:each, when_tagged_with_vcr) do |ex|
            example = ex.respond_to?(:metadata) ? ex : ex.example
            VCR.eject_cassette(:skip_no_unused_interactions_assertion => !!example.exception)
          end
        end
      end
    end
  end
end

