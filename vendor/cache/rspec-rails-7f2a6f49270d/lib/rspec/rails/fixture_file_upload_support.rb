module RSpec
  module Rails
    # @private
    module FixtureFileUploadSupport
      delegate :fixture_file_upload, to: :rails_fixture_file_wrapper

    private

      # In Rails 6.2 fixture file path needs to be relative to `file_fixture_path` instead, this change
      # was brought in with a deprecation warning on 6.1. In Rails 6.2 expect to rework this to remove
      # the old accessor.
      if ::Rails.version.to_f >= 6.1
        def rails_fixture_file_wrapper
          RailsFixtureFileWrapper.file_fixture_path = nil
          resolved_fixture_path =
            if respond_to?(:file_fixture_path) && !file_fixture_path.nil?
              file_fixture_path.to_s
            else
              (RSpec.configuration.fixture_path || '').to_s
            end
          RailsFixtureFileWrapper.file_fixture_path = File.join(resolved_fixture_path, '') unless resolved_fixture_path.strip.empty?
          RailsFixtureFileWrapper.instance
        end
      else
        def rails_fixture_file_wrapper
          RailsFixtureFileWrapper.fixture_path = nil
          resolved_fixture_path =
            if respond_to?(:fixture_path) && !fixture_path.nil?
              fixture_path.to_s
            else
              (RSpec.configuration.fixture_path || '').to_s
            end
          RailsFixtureFileWrapper.fixture_path = File.join(resolved_fixture_path, '') unless resolved_fixture_path.strip.empty?
          RailsFixtureFileWrapper.instance
        end
      end

      class RailsFixtureFileWrapper
        include ActionDispatch::TestProcess if defined?(ActionDispatch::TestProcess)

        if ::Rails.version.to_f >= 6.1
          include ActiveSupport::Testing::FileFixtures
        end

        class << self
          attr_accessor :fixture_path

          # Get instance of wrapper
          def instance
            @instance ||= new
          end
        end
      end
    end
  end
end
