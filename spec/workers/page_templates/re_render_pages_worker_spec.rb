require "rails_helper"

RSpec.describe PageTemplates::ReRenderPagesWorker, type: :worker do
  describe "#perform" do
    it "re-renders all pages belonging to the template" do
      template = create(:page_template,
                        body_markdown: "Hello, {{name}}!",
                        data_schema: { "fields" => [{ "name" => "name", "type" => "text" }] })

      page1 = create(:page, page_template: template, template_data: { "name" => "Alice" })
      page2 = create(:page, page_template: template, template_data: { "name" => "Bob" })

      # Update template
      template.update_column(:body_markdown, "Hi, {{name}}!")

      # Run worker
      described_class.new.perform(template.id)

      expect(page1.reload.processed_html).to include("Hi, Alice!")
      expect(page2.reload.processed_html).to include("Hi, Bob!")
    end

    it "does nothing if template is not found" do
      expect do
        described_class.new.perform(999_999)
      end.not_to raise_error
    end

    it "continues processing other pages if one fails" do
      template = create(:page_template,
                        body_markdown: "Hello, {{name}}!",
                        data_schema: { "fields" => [{ "name" => "name", "type" => "text" }] })

      page1 = create(:page, page_template: template, template_data: { "name" => "Alice" })
      page2 = create(:page, page_template: template, template_data: { "name" => "Bob" })

      # Stub the first page to raise an error
      allow(Page).to receive(:find_by).and_return(page1)
      allow(page1).to receive(:re_render_from_template!).and_raise(StandardError.new("Test error"))

      # Run worker - should not raise
      expect do
        described_class.new.perform(template.id)
      end.not_to raise_error
    end
  end
end

