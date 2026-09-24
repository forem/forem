module Feeds
  class XmlImportsController < ApplicationController
    before_action :authenticate_user!
    after_action :verify_authorized

    def create
      authorize Article, :create?

      result = Feeds::ImportFromXml.call(
        xml_content: params[:xml_content],
        user: current_user,
      )

      if result[:error]
        flash[:error] = result[:error]
      elsif result[:imported].to_i.positive?
        flash[:notice] = t("feeds.xml_imports.success", count: result[:imported])
      else
        flash[:warning] = t("feeds.xml_imports.none_imported")
      end

      redirect_to dashboard_feed_imports_path
    end
  end
end
