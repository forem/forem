module Authorization
  class ArticlesController < ApplicationController
    include ApplicationHelper
    layout false

    before_action :authenticate_user!
    after_action :verify_authorized

    def create_post_button
      authorize Article, :create?
      unless FeatureFlag.enabled?(:limit_post_creation_to_admins)
        render file: "public/404.html", status: :not_found
      end
    end
  end
end
