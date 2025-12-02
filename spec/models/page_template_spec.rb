require "rails_helper"

RSpec.describe PageTemplate do
  describe "validations" do
    it "requires a name" do
      template = build(:page_template, name: nil)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name" do
      create(:page_template, name: "Test Template")
      template = build(:page_template, name: "Test Template")
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("has already been taken")
    end

    it "requires a valid template_type" do
      template = build(:page_template, template_type: "invalid")
      expect(template).not_to be_valid
      expect(template.errors[:template_type]).to include("is not included in the list")
    end

    it "validates data_schema format" do
      template = build(:page_template, data_schema: { "fields" => "not_an_array" })
      expect(template).not_to be_valid
      expect(template.errors[:data_schema]).to include("fields must be an array")
    end

    it "validates that schema fields have names" do
      template = build(:page_template, data_schema: { "fields" => [{ "type" => "text" }] })
      expect(template).not_to be_valid
      expect(template.errors[:data_schema]).to include("field at index 0 must have a name")
    end

    it "validates field types" do
      template = build(:page_template, data_schema: {
                         "fields" => [{ "name" => "test", "type" => "invalid_type" }]
                       })
      expect(template).not_to be_valid
      expect(template.errors[:data_schema].first).to include("has invalid type")
    end
  end

  describe "#schema_fields" do
    it "returns the fields from data_schema" do
      template = create(:page_template, data_schema: {
                          "fields" => [
                            { "name" => "title", "type" => "text", "label" => "Title", "required" => true },
                            { "name" => "content", "type" => "textarea", "label" => "Content" },
                          ]
                        })

      expect(template.schema_fields.count).to eq(2)
      expect(template.schema_fields.first["name"]).to eq("title")
    end

    it "returns empty array if no fields" do
      template = create(:page_template, data_schema: { "fields" => [] })
      expect(template.schema_fields).to eq([])
    end
  end

  describe "#render_with_data" do
    it "replaces placeholders with data values" do
      template = create(:page_template,
                        body_markdown: "Hello, {{name}}! Welcome to {{company}}.",
                        data_schema: {
                          "fields" => [
                            { "name" => "name", "type" => "text" },
                            { "name" => "company", "type" => "text" },
                          ]
                        })

      result = template.render_with_data({ "name" => "John", "company" => "Forem" })
      expect(result).to include("Hello, John!")
      expect(result).to include("Welcome to Forem.")
    end

    it "uses body_html if body_markdown is blank" do
      template = create(:page_template,
                        body_html: "<h1>Hello, {{name}}!</h1>",
                        body_markdown: nil,
                        data_schema: {
                          "fields" => [{ "name" => "name", "type" => "text" }]
                        })

      result = template.render_with_data({ "name" => "Jane" })
      expect(result).to eq("<h1>Hello, Jane!</h1>")
    end

    it "returns empty string if no content" do
      template = create(:page_template, body_html: nil, body_markdown: nil)
      expect(template.render_with_data({})).to eq("")
    end
  end

  describe "#validate_data" do
    it "returns errors for missing required fields" do
      template = create(:page_template, data_schema: {
                          "fields" => [
                            { "name" => "title", "type" => "text", "label" => "Title", "required" => true },
                            { "name" => "content", "type" => "textarea", "required" => false },
                          ]
                        })

      errors = template.validate_data({})
      expect(errors).to include("Title is required")
      expect(errors).not_to include("content is required")
    end

    it "returns empty array when all required fields are present" do
      template = create(:page_template, data_schema: {
                          "fields" => [
                            { "name" => "title", "type" => "text", "required" => true },
                          ]
                        })

      errors = template.validate_data({ "title" => "My Title" })
      expect(errors).to be_empty
    end
  end

  describe "#fork" do
    let(:original) do
      create(:page_template,
             name: "Original",
             description: "Original template",
             body_markdown: "# Hello",
             data_schema: { "fields" => [{ "name" => "test", "type" => "text" }] })
    end

    it "creates a new template with copied attributes" do
      forked = original.fork(new_name: "Forked Template")

      expect(forked.name).to eq("Forked Template")
      expect(forked.description).to eq(original.description)
      expect(forked.body_markdown).to eq(original.body_markdown)
      expect(forked.data_schema).to eq(original.data_schema)
    end

    it "sets forked_from to the original template" do
      forked = original.fork(new_name: "Forked Template")
      forked.save!

      expect(forked.forked_from).to eq(original)
      expect(original.forks).to include(forked)
    end
  end

  describe "#ancestors" do
    it "returns the chain of forked templates" do
      grandparent = create(:page_template, name: "Grandparent")
      parent = grandparent.fork(new_name: "Parent")
      parent.save!
      child = parent.fork(new_name: "Child")
      child.save!

      expect(child.ancestors).to eq([parent, grandparent])
      expect(parent.ancestors).to eq([grandparent])
      expect(grandparent.ancestors).to eq([])
    end
  end

  describe "re-rendering pages when template changes" do
    before do
      allow(PageTemplates::ReRenderPagesWorker).to receive(:perform_async)
    end

    it "queues a worker when body_markdown changes" do
      template = create(:page_template, body_markdown: "Original content")
      template.update!(body_markdown: "Updated content")

      expect(PageTemplates::ReRenderPagesWorker).to have_received(:perform_async).with(template.id)
    end

    it "queues a worker when body_html changes" do
      template = create(:page_template, body_html: "<p>Original</p>")
      template.update!(body_html: "<p>Updated</p>")

      expect(PageTemplates::ReRenderPagesWorker).to have_received(:perform_async).with(template.id)
    end

    it "does not queue a worker when other fields change" do
      template = create(:page_template, name: "Original Name")
      template.update!(name: "New Name")

      expect(PageTemplates::ReRenderPagesWorker).not_to have_received(:perform_async)
    end
  end
end

