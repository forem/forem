module Authorization
  class ArticlesController < ApplicationController
    include ApplicationHelper
    layout false

    before_action :authenticate_user!

    def create_post_button
      if policy(Article).create?
        render text: "allowed", status: :ok
      else
        render file: "public/404.html", status: :not_found
      end
    end
  end
end
