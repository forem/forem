class DeepLinksController < ApplicationController
  def mobile; end

  # Apple Application Site Association - based on Apple docs guidelines
  # https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html
  def aasa
    # This query plucks :team_id & :app_bundle so we get an array or arrays
    # Example: [['TEAM1', 'app.bundle.one'], ['TEAM2', 'app.bundle.two']]
    consumer_apps = ConsumerApps::FindOrCreateAllQuery.call
      .where(platform: Device::IOS)
      .where.not(team_id: nil)
      .order(:created_at)
      .pluck(:team_id, :app_bundle)

    # Now restructure the array of arrays into valid AASA App ID's
    # Example: ['TEAM1.app.bundle.one', 'TEAM2.app.bundle.two']
    supported_apps = consumer_apps.map { |result| result.join(".") }

    render json: {
      applinks: {
        apps: [],
        details: supported_apps.map { |app_id| { appID: app_id, paths: ["/*"] } }
      },
      activitycontinuation: {
        apps: supported_apps
      },
      webcredentials: {
        apps: supported_apps
      }
    }
  end
end
