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
      relation.create_or_find_by(app_bundle: ConsumerApp::FOREM_BUNDLE)
    end
  end
end
