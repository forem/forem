require "rails_helper"

RSpec.describe "layouts/_styles" do
  it "renders all stylesheet link tags with data-instant-track attribute" do
    render partial: "layouts/styles", locals: { qualifier: "main" }

    expect(rendered).to include('id="main-minimal-stylesheet"', 'data-instant-track="true"')
    expect(rendered).to include('id="main-views-stylesheet"', 'data-instant-track="true"')
    expect(rendered).to include('id="main-crayons-stylesheet"', 'data-instant-track="true"')
  end
end
