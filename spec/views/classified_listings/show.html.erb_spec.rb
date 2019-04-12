require 'rails_helper'

RSpec.describe "classified_listings/show", type: :view do
  before(:each) do
    @classified_listing = assign(:classified_listing, ClassifiedListing.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
