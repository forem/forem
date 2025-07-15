class SubforemsController < ApplicationController
  def index
    @subforems = Subforem.where(discoverable: true).or(Subforem.where(root: true)).order(root: :desc, id: :asc)
    set_surrogate_key_header "subforems", Subforem.table_key, @subforems.map(&:record_key)
  end
end