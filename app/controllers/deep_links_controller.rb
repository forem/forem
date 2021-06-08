class DeepLinksController < ApplicationController
  def mobile; end

  # Apple Application Site Association - based on Apple docs guidelines
  # https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html
  def aasa
    # TODO: [@fdoxyz] Replace these hardcoded identifiers with configurations
    # creators can use to customize their Forems - `/admin/consumer_apps`
    supported_apps = ["R9SWHSQNV8.com.forem.app"]
    supported_apps << "R9SWHSQNV8.to.dev.ios" if ForemInstance.dev_to?
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
