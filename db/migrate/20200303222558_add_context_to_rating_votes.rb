class AddContextToRatingVotes < ActiveRecord::Migration[5.2]
  def change
    add_column :rating_votes, :context, :string, default: "explicit"
  end
end
