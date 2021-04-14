class DeepLinksController < ApplicationController
  def mobile; end

  # Apple Application Site Association
  def aasa
    forem_app = "R9SWHSQNV8.com.forem.app"
    dev_app = "R9SWHSQNV8.to.dev.ios"
    render json: {
      applinks: {
        apps: [forem_app, dev_app],
        details: [
          {
            appID: forem_app,
            paths: ["/*"]
          },
          {
            appID: dev_app,
            paths: ["/*"]
          },
        ]
      },
      activitycontinuation: {
        apps: [forem_app, dev_app]
      },
      webcredentials: {
        apps: [forem_app, dev_app]
      }
    }
  end
end
