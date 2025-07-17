class SubforemsController < ApplicationController
  def index
    @subforems = Subforem.where(discoverable: true, root: false).order(score: :desc)
    set_surrogate_key_header "subforems", Subforem.table_key, @subforems.map(&:record_key)
  end
end