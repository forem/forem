class DeepLinksController < ApplicationController
  def mobile; end

  # Apple Application Site Association - based on Apple docs guidelines
  # https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html
  def aasa
    @apps = ConsumerApps::FindOrCreateAllQuery.call.where(platform: Device::IOS)
    supported_apps = @apps.map(&:app_bundle)
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
