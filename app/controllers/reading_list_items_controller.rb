class ReadingListItemsController < ApplicationController
  def index
    @reading_list_items_index = true
    set_view
  end

  def update
    @reaction = Reaction.find(params[:id])
    not_authorized if @reaction.user_id != session_current_user_id

    @reaction.status = params[:current_status] == "archived" ? "valid" : "archived"
    @reaction.save
    head :ok
  end

  private

  def set_view
    @view = if params[:view] == "archive"
              "archived"
            else
              "valid,confirmed"
            end
  end
end
