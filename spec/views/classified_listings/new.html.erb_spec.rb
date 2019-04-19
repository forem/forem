require 'rails_helper'

RSpec.describe "classified_listings/new", type: :view do
  before(:each) do
    assign(:classified_listing, ClassifiedListing.new())
  end

  it "renders new classified_listing form" do
    render

    assert_select "form[action=?][method=?]", classified_listings_path, "post" do
    end
  end
end
