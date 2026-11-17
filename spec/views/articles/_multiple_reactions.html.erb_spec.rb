require "rails_helper"

RSpec.describe "articles/_multiple_reactions.html.erb" do
  [false, true].each do |signed_in|
    it "batches public reaction buttons and preserves their content when signed_in=#{signed_in}" do
      allow(view).to receive(:user_signed_in?).and_return(signed_in)
      assign(:comments_count, 0)
      collections = []
      callback = lambda do |*, payload|
        collections << payload[:count] if payload[:identifier].end_with?("articles/_multireaction_button.html.erb")
      end

      ActiveSupport::Notifications.subscribed(callback, "render_collection.action_view") do
        render partial: "articles/multiple_reactions"
      end

      buttons = Nokogiri::HTML.fragment(rendered).css(".reaction-drawer__container button")
      expect(collections).to eq([ReactionCategory.for_view.size])
      expect(buttons.pluck("data-category")).to eq(ReactionCategory.for_view.map { |type| type.slug.to_s })
      buttons.zip(ReactionCategory.for_view).each do |button, type|
        expect(button["id"]).to eq("reaction-butt-#{type.slug}")
        expect(button["name"]).to eq(type.name)
        expect(button["aria-label"]).to eq(type.name)
        expect(button.at_css(".crayons-tooltip__content").text.strip).to eq(type.name)
        expect(button.css("img").size).to eq(signed_in ? 2 : 1)
        expect(button.css("img").pluck("src")).to all(include(type.icon))
      end
    end
  end

  it "renders an empty drawer when there are no public reaction categories" do
    allow(ReactionCategory).to receive(:for_view).and_return([])
    assign(:comments_count, 0)

    render partial: "articles/multiple_reactions"

    expect(Nokogiri::HTML.fragment(rendered).css(".reaction-drawer__container button")).to be_empty
  end
end
