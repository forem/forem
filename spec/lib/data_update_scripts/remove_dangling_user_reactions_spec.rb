require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211209213849_remove_dangling_user_reactions.rb",
)

describe DataUpdateScripts::RemoveDanglingUserReactions do
  let(:user_to_delete) { create(:user) }

  before do
    create(:vomit_reaction, reactable: user_to_delete)

    # there's no dependent callback on reactions_to so the reaction is not removed
    user_to_delete.destroy
  end

  it "removes reactions to deleted users" do
    expect { described_class.new.run }.to change(Reaction, :count).by(-1)
  end
end
