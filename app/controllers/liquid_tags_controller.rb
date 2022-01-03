class LiquidTagsController < ApplicationController
  before_action :authenticate_user!

  FILTER_REGEX = /^(?:NullTag|Liquid::)/

  def index
    custom_tags = Liquid::Template.tags.filter_map do |name, tag|
      name unless tag.match?(FILTER_REGEX)
    end.sort

    render json: { liquid_tags: custom_tags }
  end
end
