class DeepLinksController < ApplicationController
  def mobile; end

  # Apple Application Site Association
  def aasa
    forem_app_ids = ["R9SWHSQNV8.to.dev.ios", "1550146455.com.forem.app"]
    render json: {
      applinks: {
        details: [
          {
            appIDs: forem_app_ids,
            components: [{ "/" => "*" }]
          },
        ]
      },
      webcredentials: {
        apps: forem_app_ids
      }
    }
  end
end
