module Feeds
  class XmlImportsController < ApplicationController
    before_action :authenticate_user!

    def create
      result = Feeds::ImportFromXml.call(
        xml_content: params[:xml_content],
        user: current_user,
      )

      if result[:error]
        flash[:error] = result[:error]
      else
        flash[:notice] = t("feeds.xml_imports.success", count: result[:imported])
      end

      redirect_to dashboard_feed_imports_path
    end
  end
end
