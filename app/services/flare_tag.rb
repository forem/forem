class FlareTag
  FLARE_TAG_IDS_HASH = Tag.where(name: Constants::Tags::FLARE_TAG_NAMES).pluck(:name, :id).to_h.freeze

  def initialize(article, except_tag = nil)
    @article = article.decorate
    @except_tag = except_tag
  end

  def tag
    @tag ||= if tag_id
               Tag.select(%i[name bg_color_hex text_color_hex]).find_by(id: tag_id)
             end
  end

  def tag_hash
    tag&.slice(:name, :bg_color_hex, :text_color_hex)
  end

  private

  attr_reader :article, :except_tag

  def tag_id
    tag_name, tag_id = FLARE_TAG_IDS_HASH.slice(*article.cached_tag_list_array).first
    tag_id if tag_name && tag_name != except_tag
  end
end
