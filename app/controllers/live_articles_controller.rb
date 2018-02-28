class LiveArticlesController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]

  def index
    if @article = Article.where(live_now: true).order("featured_number DESC").first
      set_surrogate_key_header "live--#{@article.id}"
      render json: { 
                      title: @article.title,
                      path: @article.path,
                      tag_list: @article.tag_list,
                      comments_count: @article.comments_count,
                      positive_reactions_count: @article.positive_reactions_count,
                      user: {
                        name: @article.user.name,
                        profile_pic: ProfileImage.new(@article.user).get(50),
                      }
                  }
    else
      set_surrogate_key_header "live--nothing"
      render json: {}
    end
  end
end
