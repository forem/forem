module ConsumerApps
  class FindOrCreateByQuery
    def self.call(app_bundle:, platform:)
      new(app_bundle: app_bundle, platform: platform).call
    end

    def initialize(app_bundle:, platform:)
      @app_bundle = app_bundle
      @platform = platform
    end

    def call
      # This guard clause handles the Forem app special case
      return forem_consumer_app if @app_bundle == ConsumerApp::FOREM_BUNDLE

      # All other ConsumerApp are simply fetched as usual
      relation.find_by(app_bundle: @app_bundle)
    end

    private

    attr_reader :platform

    def relation
      # taking advantage of enum scopes in Rails
      # see https://api.rubyonrails.org/classes/ActiveRecord/Enum.html
      ConsumerApp.public_send(platform)
    end

    def forem_consumer_app
      # iOS Forem Consumer App requires a team_id value but Android (future) doesn't
      team_id = platform == :ios ? ConsumerApp::FOREM_TEAM_ID : nil
      begin
        relation.create_or_find_by!(app_bundle: ConsumerApp::FOREM_BUNDLE, team_id: team_id)
      rescue StandardError => e
        error_tags = [
          "error:#{e.message}",
          "app_bundle:#{ConsumerApp::FOREM_BUNDLE}",
          "platform:#{platform}",
        ]
        ForemStatsClient.increment("consumer_apps.create", 1, tags: error_tags)
      end
    end
  end
end
