require 'rails_helper'

RSpec.describe "classified_listings/index", type: :view do
  before(:each) do
    assign(:classified_listings, [
      ClassifiedListing.create!(),
      ClassifiedListing.create!()
    ])
  end

  it "renders a list of classified_listings" do
    render
  end
end
