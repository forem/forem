require "rails_helper"

RSpec.describe Ai::AboutPageGenerator do
  let(:subforem) { create(:subforem) }
  let(:brain_dump) { "A community focused on web development and programming" }
  let(:name) { "WebDev Community" }
  let(:service) { described_class.new(subforem.id, brain_dump, name) }

  describe "#generate!" do
    context "when AI call succeeds on first attempt" do
      let(:mock_ai_response) do
        <<~RESPONSE
          # Welcome to WebDev Community

          We're a vibrant community of web developers and programmers who share knowledge, collaborate on projects, and help each other grow.

          ## What We're About

          Our community focuses on web development and programming topics. Whether you're a beginner or an experienced developer, you'll find valuable discussions and resources here.

          ## What We Discuss

          - **Web Development**: HTML, CSS, JavaScript, and modern frameworks
          - **Programming**: Best practices, problem-solving, and code reviews
          - **Career Development**: Job opportunities, skill building, and industry trends
          - **Tools & Technologies**: New libraries, frameworks, and development tools

          ## How to Participate

          - Share your knowledge and experiences
          - Ask questions and seek help
          - Contribute to discussions and code reviews
          - Follow community guidelines and be respectful

          Join us in building a supportive and inclusive developer community!
        RESPONSE
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
        allow(Rails.logger).to receive(:info)
      end

      it "creates an about page successfully" do
        expect { service.generate! }.to change(Page, :count).by(1)

        page = Page.last
        expect(page.title).to eq("About #{name}")
        expect(page.description).to eq("Overview page for #{name}")
        expect(page.slug).to eq("about")
        expect(page.subforem_id).to eq(subforem.id)
        expect(page.is_top_level_path).to be true
        expect(page.template).to eq("contained")
        expect(page.body_markdown).to include("Welcome to WebDev Community")
        expect(page.body_markdown).to include("web development and programming")
      end

      it "logs success message" do
        service.generate!
        expect(Rails.logger).to have_received(:info).with("Creating new about page for subforem #{subforem.id}")
      end
    end

    context "when about page already exists" do
      let!(:existing_page) do
        create(:page,
               slug: "about",
               subforem_id: subforem.id,
               title: "Old Title",
               description: "Old description",
               body_markdown: "Old content")
      end
      let(:mock_ai_response) { "# New About Content\n\nThis is updated content." }

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
        allow(Rails.logger).to receive(:info)
      end

      it "updates the existing about page" do
        expect { service.generate! }.not_to change(Page, :count)

        existing_page.reload
        expect(existing_page.title).to eq("About #{name}")
        expect(existing_page.description).to eq("Overview page for #{name}")
        expect(existing_page.body_markdown).to include("New About Content")
      end

      it "logs update message" do
        service.generate!
        expect(Rails.logger).to have_received(:info).with("About page already exists for subforem #{subforem.id}, updating content")
      end
    end

    context "when AI call fails initially but succeeds on retry" do
      let(:ai_service) { double }
      let(:mock_ai_response) do
        "# About Page\n\nThis is the about content with enough length to pass validation in test environment."
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        # Mock the call method to fail twice, then succeed
        call_count = 0
        allow(ai_service).to receive(:call) do
          call_count += 1
          raise StandardError, "API Error" if call_count <= 2

          mock_ai_response
        end
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)
      end

      it "retries and eventually succeeds" do
        expect { service.generate! }.to change(Page, :count).by(1)
      end

      it "logs warning messages for failed attempts" do
        service.generate!
        expect(Rails.logger).to have_received(:warn).with("Attempt 1 failed to generate about content: API Error")
        expect(Rails.logger).to have_received(:warn).with("Attempt 2 failed to generate about content: API Error")
      end
    end

    context "when AI call fails all attempts" do
      before do
        allow(Ai::Base).to receive(:new).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and returns without creating page" do
        expect { service.generate! }.not_to change(Page, :count)
        expect(Rails.logger).to have_received(:error).with("Failed to generate about content after 3 attempts")
      end
    end

    context "when AI response is too short" do
      let(:short_response) { "A" } # Very short content

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: short_response))
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:error)
      end

      it "retries due to insufficient content" do
        service.generate!
        expect(Rails.logger).to have_received(:warn).with("Attempt 1 generated insufficient about content, retrying...")
        expect(Rails.logger).to have_received(:error).with("Failed to generate about content after 3 attempts")
      end
    end

    context "when AI response is too long" do
      let(:long_response) { "A" * 6000 } # Too long content

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: long_response))
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:error)
        # Mock the environment to be production-like for this test
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it "retries due to content being too long" do
        service.generate!
        expect(Rails.logger).to have_received(:warn).with("Attempt 1 generated insufficient about content, retrying...")
        expect(Rails.logger).to have_received(:error).with("Failed to generate about content after 3 attempts")
      end
    end

    context "when AI response contains markdown code blocks" do
      let(:mock_ai_response) do
        "```markdown\n# About Page\n\nThis is content with enough length to pass validation in test environment.\n```"
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
      end

      it "cleans up markdown code blocks" do
        service.generate!

        page = Page.last
        expect(page.body_markdown).to eq("# About Page\n\nThis is content with enough length to pass validation in test environment.")
        expect(page.body_markdown).not_to include("```markdown")
        expect(page.body_markdown).not_to include("```")
      end
    end

    context "when AI response contains common prefixes" do
      let(:mock_ai_response) do
        "Here is the about page:\n\n# About Page\n\nThis is content with enough length to pass validation in test environment."
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
      end

      it "removes common AI prefixes" do
        service.generate!

        page = Page.last
        expect(page.body_markdown).to eq("# About Page\n\nThis is content with enough length to pass validation in test environment.")
        expect(page.body_markdown).not_to include("Here is the about page:")
      end
    end
  end

  describe "output validation" do
    context "in test environment" do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)
      end

      it "accepts shorter content in test environment" do
        short_content = "A" * 50
        expect(service.send(:output_meets_expectations?, short_content)).to be true
      end

      it "rejects very short content even in test environment" do
        very_short_content = "A" * 10
        expect(service.send(:output_meets_expectations?, very_short_content)).to be false
      end
    end

    context "in production environment" do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it "accepts content of appropriate length" do
        good_content = "A" * 300
        expect(service.send(:output_meets_expectations?, good_content)).to be true
      end

      it "rejects content that is too short" do
        short_content = "A" * 150
        expect(service.send(:output_meets_expectations?, short_content)).to be false
      end

      it "rejects content that is too long" do
        long_content = "A" * 6000
        expect(service.send(:output_meets_expectations?, long_content)).to be false
      end
    end
  end
end
