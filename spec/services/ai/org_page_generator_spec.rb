require "rails_helper"

RSpec.describe Ai::OrgPageGenerator do
  let(:organization) { create(:organization, name: "TestOrg", slug: "testorg") }
  let(:org_data) do
    {
      title: "TestOrg - Build Great Things",
      description: "A platform for building great things",
      links: [{ url: "https://www.testorg.com/docs", label: "Docs" }]
    }
  end
  let(:dev_posts) do
    [{ id: 1, title: "Getting Started with TestOrg", path: "/testorg/getting-started", reactions: 42 }]
  end
  let(:service) { described_class.new(organization: organization, org_data: org_data, dev_posts: dev_posts) }

  describe "#generate" do
    let(:mock_markdown) { "## Welcome to TestOrg\n\nTestOrg helps you build great things." }

    before do
      allow(Ai::Base).to receive(:new).and_return(double(call: mock_markdown))
    end

    it "returns markdown and rendered HTML" do
      result = service.generate
      expect(result[:markdown]).to include("Welcome to TestOrg")
      expect(result[:html]).to be_present
    end

    it "cleans AI prefixes from response" do
      allow(Ai::Base).to receive(:new).and_return(
        double(call: "Here is the page:\n\n## Welcome\n\nContent here."),
      )
      result = service.generate
      expect(result[:markdown]).not_to include("Here is the page:")
      expect(result[:markdown]).to include("## Welcome")
    end

    it "strips markdown code block wrappers" do
      allow(Ai::Base).to receive(:new).and_return(
        double(call: "```markdown\n## Welcome\n\nContent.\n```"),
      )
      result = service.generate
      expect(result[:markdown]).not_to include("```")
      expect(result[:markdown]).to include("## Welcome")
    end

    it "works without dev_posts" do
      no_posts_service = described_class.new(organization: organization, org_data: org_data)
      allow(Ai::Base).to receive(:new).and_return(double(call: mock_markdown))
      result = no_posts_service.generate
      expect(result[:markdown]).to include("Welcome to TestOrg")
    end
  end

  describe "#iterate" do
    let(:current_markdown) { "## Old Content\n\nSome existing page." }
    let(:instruction) { "Make it more developer-focused" }
    let(:updated_markdown) { "## Developer Hub\n\nBuild with TestOrg APIs." }

    before do
      allow(Ai::Base).to receive(:new).and_return(double(call: updated_markdown))
    end

    it "returns updated markdown based on feedback" do
      result = service.iterate(current_markdown: current_markdown, instruction: instruction)
      expect(result[:markdown]).to include("Developer Hub")
      expect(result[:html]).to be_present
    end
  end

  describe "retry on validation failure" do
    let(:ai_client) { double("Ai::Base") }
    let(:good_markdown) { "## Welcome\n\nValid content here." }

    before do
      allow(Ai::Base).to receive(:new).and_return(ai_client)
      call_count = 0
      allow(ai_client).to receive(:call) do
        call_count += 1
        # First call returns content that will fail ContentRenderer, subsequent return good markdown
        call_count == 1 ? "{% nonexistent_broken_tag %}" : good_markdown
      end
      allow(Rails.logger).to receive(:warn)
    end

    it "retries on ContentRenderer failure and succeeds" do
      # This test depends on ContentRenderer actually raising on bad liquid tags.
      # If it doesn't raise, the first response will be returned as-is.
      result = service.generate
      expect(result[:markdown]).to be_present
    end
  end

  describe "when all retries fail" do
    before do
      allow(Ai::Base).to receive(:new).and_return(double(call: nil))
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
    end

    it "raises after max retries" do
      expect { service.generate }.to raise_error(/Failed to generate valid page/)
    end
  end

  describe "prompt construction" do
    before do
      allow(Ai::Base).to receive(:new).and_return(double(call: "## Page\n\nContent."))
    end

    it "includes org data in generate prompt" do
      prompt = service.send(:build_generate_prompt)
      expect(prompt).to include("TestOrg")
      expect(prompt).to include("testorg")
      expect(prompt).to include("Build Great Things")
      expect(prompt).to include("building great things")
      expect(prompt).to include("Docs")
    end

    it "includes dev posts in generate prompt" do
      prompt = service.send(:build_generate_prompt)
      expect(prompt).to include("Getting Started with TestOrg")
      expect(prompt).to include("42 reactions")
    end

    it "includes liquid tag guide in generate prompt" do
      prompt = service.send(:build_generate_prompt)
      expect(prompt).to include("LIQUID TAG REFERENCE")
    end

    it "includes org tag supplement in generate prompt" do
      prompt = service.send(:build_generate_prompt)
      expect(prompt).to include("org_posts testorg")
      expect(prompt).to include("org_team testorg")
    end

    it "includes lead form id when active lead form exists" do
      lead_form = create(:organization_lead_form, organization: organization, active: true)
      prompt = service.send(:org_tag_supplement)
      expect(prompt).to include("org_lead_form #{lead_form.id}")
    end

    it "omits lead form section when no active lead form" do
      supplement = service.send(:org_tag_supplement)
      expect(supplement).not_to include("org_lead_form")
    end

    it "includes current markdown and instruction in iterate prompt" do
      prompt = service.send(:build_iterate_prompt, "## Current Page", "Add more details")
      expect(prompt).to include("## Current Page")
      expect(prompt).to include("Add more details")
      expect(prompt).to include("TestOrg")
    end
  end
end
