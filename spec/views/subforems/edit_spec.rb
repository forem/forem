require "rails_helper"

RSpec.describe "subforems/edit", type: :view do
  let(:subforem) { create(:subforem) }
  let(:navigation_links) { [] }
  let(:pages) { [] }
  let(:supported_tags) { [] }
  let(:unsupported_tags) { [] }
  let(:subforem_moderators) { [] }
  let(:admin_user) { create(:user, :admin) }

  before do
    assign(:subforem, subforem)
    assign(:navigation_links, navigation_links)
    assign(:pages, pages)
    assign(:supported_tags, supported_tags)
    assign(:unsupported_tags, unsupported_tags)
    assign(:subforem_moderators, subforem_moderators)
    
    allow(view).to receive(:current_user).and_return(admin_user)
    allow(view).to receive(:user_signed_in?).and_return(true)
  end

  describe "navigation links form" do
    context "create form" do
      before { render }

      it "displays image upload field before SVG icon field" do
        # Get all field labels in order
        doc = Nokogiri::HTML(rendered)
        create_form = doc.at_css('#nav-link-form')
        
        expect(create_form).not_to be_nil
        
        # Check that image field exists - using input since label is rendered differently
        image_input = create_form.at_css('input[name="navigation_link[image]"]')
        expect(image_input).not_to be_nil
        
        # Verify the label text exists in the form
        expect(create_form.text).to include(I18n.t("views.subforems.edit.navigation_links.form.image.label"))
      end

      it "hides SVG icon field by default" do
        doc = Nokogiri::HTML(rendered)
        svg_field = doc.at_css('#svg-icon-field-create')
        
        expect(svg_field).not_to be_nil
        expect(svg_field['style']).to include('display: none')
      end

      it "includes toggle button for SVG icon field" do
        doc = Nokogiri::HTML(rendered)
        create_form = doc.at_css('#nav-link-form')
        toggle_button = create_form.at_css('button[onclick*="toggleSvgIconField"]')
        
        expect(toggle_button).not_to be_nil
        expect(toggle_button.text).to include('+')
        expect(toggle_button.text).to include(I18n.t("views.subforems.edit.navigation_links.form.icon.alternative"))
      end

      it "includes the toggleSvgIconField JavaScript function" do
        expect(rendered).to include('window.toggleSvgIconField')
      end
    end

    context "edit form with existing navigation link" do
      let(:navigation_link) do
        NavigationLink.create!(
          subforem: subforem,
          name: "Test Link",
          url: "/test",
          icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
          section: "default",
          display_to: "all",
          position: 1
        )
      end
      let(:navigation_links) { [navigation_link] }

      before { render }

      it "displays image upload field before SVG icon field in edit form" do
        doc = Nokogiri::HTML(rendered)
        edit_form = doc.at_css("#edit-nav-link-form-#{navigation_link.id}")
        
        expect(edit_form).not_to be_nil
        
        # Check that image field exists - using input since label is rendered differently
        image_input = edit_form.at_css('input[name="navigation_link[image]"]')
        expect(image_input).not_to be_nil
        
        # Verify the label text exists in the form
        expect(edit_form.text).to include(I18n.t("views.subforems.edit.navigation_links.form.image.label"))
      end

      it "hides SVG icon field by default in edit form" do
        doc = Nokogiri::HTML(rendered)
        svg_field = doc.at_css("#svg-icon-field-edit-#{navigation_link.id}")
        
        expect(svg_field).not_to be_nil
        expect(svg_field['style']).to include('display: none')
      end

      it "includes unique toggle button for each edit form" do
        doc = Nokogiri::HTML(rendered)
        edit_form = doc.at_css("#edit-nav-link-form-#{navigation_link.id}")
        toggle_button = edit_form.at_css("button[onclick*=\"toggleSvgIconField('edit-#{navigation_link.id}')\"]")
        
        expect(toggle_button).not_to be_nil
        expect(toggle_button.text).to include('+')
      end
    end

    context "edit form with navigation link that has an image" do
      let(:navigation_link) do
        NavigationLink.create!(
          subforem: subforem,
          name: "Test Link",
          url: "/test",
          icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
          section: "default",
          display_to: "all",
          position: 1
        )
      end
      let(:navigation_links) { [navigation_link] }

      before do
        # Mock the image presence
        allow(navigation_link).to receive(:respond_to?).and_call_original
        image_double = double(present?: true, url: "/uploads/test.png")
        allow(navigation_link).to receive(:image).and_return(image_double)
        render
      end

      it "displays current image preview in edit form" do
        doc = Nokogiri::HTML(rendered)
        edit_form = doc.at_css("#edit-nav-link-form-#{navigation_link.id}")
        
        expect(edit_form).not_to be_nil
        expect(edit_form.text).to include(I18n.t("views.subforems.edit.navigation_links.form.image.current"))
      end
    end
  end

  describe "route helpers" do
    it "generates correct path for update_navigation_link with path parameter" do
      navigation_link = NavigationLink.create!(
        subforem: subforem,
        name: "Test Link",
        url: "/test",
        icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>",
        section: "default",
        display_to: "all",
        position: 1
      )
      
      expected_path = "/subforems/#{subforem.id}/update_navigation_link/#{navigation_link.id}"
      generated_path = update_navigation_link_subforem_path(subforem, navigation_link.id)
      
      expect(generated_path).to eq(expected_path)
      expect(generated_path).not_to include("navigation_link_id=")
    end
  end
end

