require 'rails_helper'

RSpec.describe "classified_listings/edit", type: :view do
  before(:each) do
    @classified_listing = assign(:classified_listing, ClassifiedListing.create!())
  end

  it "renders the edit classified_listing form" do
    render

    assert_select "form[action=?][method=?]", classified_listing_path(@classified_listing), "post" do
    end
  end
end
