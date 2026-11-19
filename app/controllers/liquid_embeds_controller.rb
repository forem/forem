class LiquidEmbedsController < ApplicationController
  VALID_TAG_NAME = /\A[a-z0-9_]+\z/
  FORBIDDEN_MARKUP_REGEX = /\{%|%\}|\{\{|\}\}|\x00/

  before_action :set_cache_control_headers, only: %i[show]
  after_action :allow_iframe, only: :show
  layout false

  def show
    set_surrogate_key_header params.to_s

    @rendered_node = render_liquid_embed(params[:embeddable], params[:args])
  rescue StandardError
    raise ActionController::RoutingError, "Not Found"
  end

  private

  def render_liquid_embed(embeddable, args)
    tag_name = embeddable.to_s
    markup = args.to_s
    raise ActionController::RoutingError, "Not Found" unless valid_embed_request?(tag_name, markup)

    tag_class = Liquid::Template.tags[tag_name]
    raise ActionController::RoutingError, "Not Found" unless embeddable_tag_class?(tag_class)

    node = tag_class.parse(tag_name, markup, Liquid::Tokenizer.new(""), Liquid::ParseContext.new)
    node.render(Liquid::Context.new)
  end

  def valid_embed_request?(tag_name, markup)
    tag_name.match?(VALID_TAG_NAME) &&
      markup.valid_encoding? &&
      !markup.match?(FORBIDDEN_MARKUP_REGEX)
  end

  def embeddable_tag_class?(tag_class)
    tag_class.is_a?(Class) &&
      tag_class < LiquidTagBase &&
      !(tag_class <= Liquid::Block)
  end

  def allow_iframe
    response.headers.except! "X-Frame-Options"
  end
end
