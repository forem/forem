require "rails_helper"

RSpec.describe ClassifiedListingTag, type: :liquid_template do
  # create user, organization and two listings (one user only and other with organization)
  # def generate new liquid
  # raises error when invalid link/slug/path
  it "raises an error when invalid" do
    expect { generate_new_liquid("/listings/fakecategory/fakeslug") }.
      to raise_error("Invalid listing URL or listing does not exist").

  end
  # renders liquid tag with slug only
  # renders liquid tag with category and slug
  # renders liquid tag with full link
  # renders organization listing with organization name as author
  # render user listing with user name as author
end
