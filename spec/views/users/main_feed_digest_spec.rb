require "rails_helper"

RSpec.describe "users/_main_feed cache digest" do
  it "tracks the comments partials, so edits to them expire cached profiles" do
    tree = ActionView::Digestor.tree("users/_main_feed", ApplicationController.new.lookup_context, true)

    expect(tree.children.map(&:name)).to include("users/comments_section", "users/comments_locked_cta")
    expect(tree.children).not_to include(an_instance_of(ActionView::Digestor::Missing))
  end
end
