class TagsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]

  def index
    @tags_index = true
    @tags = Tag.all.order("hotness_score DESC").first(100)
  end
end
