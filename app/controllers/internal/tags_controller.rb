class Internal::TagsController < Internal::ApplicationController
  layout 'internal'

  def index
    if params[:state] == "supported"
      @tags = Tag.where(supported: true).order("taggings_count DESC").limit(120)
    elsif params[:state] == "unsupported"
      @tags = Tag.where(supported: false).order("taggings_count DESC").limit(120)
    else
      @tags = Tag.order("taggings_count DESC").limit(120)
    end
  end

  def update
    @tag = Tag.find(params[:id])
    @tag.update!(tag_params)
    redirect_to(action: :index)
  end  

  private

  def tag_params
    params.require(:tag).permit(:supported,
                                :rules_markdown,
                                :short_summary,
                                :pretty_name,
                                :bg_color_hex,
                                :text_color_hex)
  end

end