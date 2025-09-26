require "rails_helper"

RSpec.describe Ai::CommunityCopy do
  let(:subforem) { create(:subforem) }
  let(:brain_dump) { "A community focused on web development and programming" }
  let(:service) { described_class.new(subforem.id, brain_dump) }

  describe "#write!" do
    context "when all AI calls succeed on first attempt" do
      let(:mock_description_response) do
        "A vibrant community for web developers and programmers to share knowledge and collaborate on projects."
      end
      let(:mock_tagline_response) { "Code. Share. Grow." }
      let(:mock_content_description_response) do
        "This community focuses on web development and programming content. All posts should be related to coding, development practices, or programming topics. No spam, self-promotion, or off-topic content allowed."
      end
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        allow(ai_service).to receive(:call).with(/Generate a community description/).and_return(mock_description_response)
        allow(ai_service).to receive(:call).with(/Generate a tagline/).and_return(mock_tagline_response)
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return(mock_content_description_response)
        allow(Settings::Community).to receive(:set_community_description)
        allow(Settings::Community).to receive(:set_tagline)
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec)
      end

      it "generates and saves all community copy successfully" do
        service.write!

        expect(Settings::Community).to have_received(:set_community_description).with(
          "A vibrant community for web developers and programmers to share knowledge and collaborate on projects", subforem_id: subforem.id
        )
        expect(Settings::Community).to have_received(:set_tagline).with("Code. Share. Grow", subforem_id: subforem.id)
        expect(Settings::RateLimit).to have_received(:set_internal_content_description_spec).with(
          "This community focuses on web development and programming content. All posts should be related to coding, development practices, or programming topics. No spam, self-promotion, or off-topic content allowed", subforem_id: subforem.id
        )
      end
    end

    context "when AI calls fail initially but succeed on retry" do
      let(:mock_description_response) do
        "A vibrant community for web developers and programmers to share knowledge and collaborate on projects."
      end
      let(:mock_tagline_response) { "Code. Share. Grow." }
      let(:mock_content_description_response) { "This community focuses on web development and programming content." }
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)

        # Mock description generation to fail twice, then succeed
        call_count = 0
        allow(ai_service).to receive(:call).with(/Generate a community description/) do
          call_count += 1
          raise StandardError, "API Error" if call_count <= 2

          mock_description_response
        end

        # Mock tagline generation to succeed immediately
        allow(ai_service).to receive(:call).with(/Generate a tagline/).and_return(mock_tagline_response)

        # Mock content description generation to succeed immediately
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return(mock_content_description_response)

        allow(Settings::Community).to receive(:set_community_description)
        allow(Settings::Community).to receive(:set_tagline)
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec)
        allow(Rails.logger).to receive(:warn)
      end

      it "retries and eventually succeeds" do
        service.write!

        expect(Settings::Community).to have_received(:set_community_description).with(
          "A vibrant community for web developers and programmers to share knowledge and collaborate on projects", subforem_id: subforem.id
        )
        expect(Settings::Community).to have_received(:set_tagline).with("Code. Share. Grow", subforem_id: subforem.id)
        expect(Settings::RateLimit).to have_received(:set_internal_content_description_spec).with(
          "This community focuses on web development and programming content", subforem_id: subforem.id
        )
      end

      it "logs warning messages for failed attempts" do
        service.write!
        expect(Rails.logger).to have_received(:warn).with("Attempt 1 failed to generate description: API Error")
        expect(Rails.logger).to have_received(:warn).with("Attempt 2 failed to generate description: API Error")
      end
    end

    context "when AI calls fail all attempts" do
      before do
        allow(Ai::Base).to receive(:new).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and returns without saving" do
        service.write!
        expect(Rails.logger).to have_received(:error).with("Failed to generate description after 3 attempts")
        expect(Rails.logger).to have_received(:error).with("Failed to generate tagline after 3 attempts")
        expect(Rails.logger).to have_received(:error).with("Failed to generate content description after 3 attempts")
      end
    end

    context "when AI response has extra text that needs cleaning" do
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        allow(Settings::Community).to receive(:set_community_description)
        allow(Settings::Community).to receive(:set_tagline)
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec)
      end

      it "cleans description responses with extra text" do
        dirty_response = "Here is the description: A vibrant community for web developers. Hope this helps!"
        clean_response = "A vibrant community for web developers"

        allow(ai_service).to receive(:call).with(/Generate a community description/).and_return(dirty_response)
        allow(ai_service).to receive(:call).with(/Generate a tagline/).and_return("Code. Share. Grow.")
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return("Content guidelines here.")

        service.write!

        expect(Settings::Community).to have_received(:set_community_description).with(clean_response,
                                                                                      subforem_id: subforem.id)
      end

      it "cleans tagline responses with extra text" do
        dirty_response = "Okay, here's the tagline: Code. Share. Grow. Let me know if you need anything else!"
        clean_response = "Code. Share. Grow"

        allow(ai_service).to receive(:call).with(/Generate a community description/).and_return("A vibrant community for web developers")
        allow(ai_service).to receive(:call).with(/Generate a tagline/).and_return(dirty_response)
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return("Content guidelines here.")

        service.write!

        expect(Settings::Community).to have_received(:set_tagline).with(clean_response, subforem_id: subforem.id)
      end

      it "cleans content description responses with extra text" do
        dirty_response = "I have generated the specification: This community focuses on web development and programming content. All posts should be related to coding, development practices, or programming topics. Feel free to ask if you need any modifications!"
        clean_response = "This community focuses on web development and programming content. All posts should be related to coding, development practices, or programming topics"

        allow(ai_service).to receive(:call).with(/Generate a community description/).and_return("A vibrant community for web developers")
        allow(ai_service).to receive(:call).with(/Generate a tagline/).and_return("Code. Share. Grow.")
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return(dirty_response)

        service.write!

        expect(Settings::RateLimit).to have_received(:set_internal_content_description_spec).with(clean_response,
                                                                                                  subforem_id: subforem.id)
      end
    end

    context "when AI response is too short" do
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        allow(Rails.logger).to receive(:warn)
      end

      it "retries when description is too short" do
        short_response = "Dev"
        good_response = "A vibrant community for web developers and programmers"

        call_count = 0
        allow(ai_service).to receive(:call).with(/Generate a community description/) do
          call_count += 1
          if call_count == 1
            short_response
          else
            good_response
          end
        end
        allow(ai_service).to receive(:call).with(/Generate a tagline/).and_return("Code. Share. Grow.")
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return("Content guidelines here.")

        allow(Settings::Community).to receive(:set_community_description)
        allow(Settings::Community).to receive(:set_tagline)
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec)

        service.write!

        expect(Rails.logger).to have_received(:warn).with("Attempt 1 generated insufficient description, retrying...")
        expect(Settings::Community).to have_received(:set_community_description).with(good_response,
                                                                                      subforem_id: subforem.id)
      end

      it "retries when tagline is too short" do
        short_response = "A"
        good_response = "Code. Share. Grow."

        call_count = 0
        allow(ai_service).to receive(:call).with(/Generate a community description/).and_return("A vibrant community for web developers")
        allow(ai_service).to receive(:call).with(/Generate a tagline/) do
          call_count += 1
          if call_count == 1
            short_response
          else
            good_response
          end
        end
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return("Content guidelines here.")

        allow(Settings::Community).to receive(:set_community_description)
        allow(Settings::Community).to receive(:set_tagline)
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec)

        service.write!

        expect(Rails.logger).to have_received(:warn).with("Attempt 1 generated insufficient tagline, retrying...")
        expect(Settings::Community).to have_received(:set_tagline).with("Code. Share. Grow", subforem_id: subforem.id)
      end
    end

    context "when saving fails" do
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        allow(ai_service).to receive(:call).with(/Generate a community description/).and_return("A vibrant community for web developers")
        allow(ai_service).to receive(:call).with(/Generate a tagline/).and_return("Code. Share. Grow.")
        allow(ai_service).to receive(:call).with(/Generate an internal content specification/).and_return("This community focuses on web development and programming content. All posts should be related to coding, development practices, or programming topics. No spam, self-promotion, or off-topic content allowed.")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error when saving description fails" do
        allow(Settings::Community).to receive(:set_community_description).and_raise(StandardError, "Save failed")
        allow(Settings::Community).to receive(:set_tagline)
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec)

        service.write!

        expect(Rails.logger).to have_received(:error).with("Failed to save community description: Save failed")
      end

      it "logs error when saving tagline fails" do
        allow(Settings::Community).to receive(:set_community_description)
        allow(Settings::Community).to receive(:set_tagline).and_raise(StandardError, "Save failed")
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec)

        service.write!

        expect(Rails.logger).to have_received(:error).with("Failed to save community tagline: Save failed")
      end

      it "logs error when saving content description fails" do
        allow(Settings::Community).to receive(:set_community_description)
        allow(Settings::Community).to receive(:set_tagline)
        allow(Settings::RateLimit).to receive(:set_internal_content_description_spec).and_raise(StandardError,
                                                                                                "Save failed")

        service.write!

        expect(Rails.logger).to have_received(:error).with("Failed to save internal content description: Save failed")
      end
    end
  end

  describe "response cleaning" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    it "removes common AI prefixes and suffixes" do
      dirty_responses = [
        "Here is the description: A vibrant community for web developers. Hope this helps!",
        "Okay, here's the tagline: Code. Share. Grow. Let me know if you need anything else!",
        "I have generated the specification: This community focuses on web development. Feel free to ask if you need any modifications!",
        "Sure, here you go: A great place for developers. Is there anything else you'd like me to help with?",
        "The community description is: Build amazing things together.",
        "Here's a tagline: Innovate. Create. Share.",
      ]

      clean_responses = [
        "A vibrant community for web developers",
        "Code. Share. Grow",
        "This community focuses on web development",
        "A great place for developers. Is there anything else you'd like me to help with?",
        "Build amazing things together",
        "Innovate. Create. Share",
      ]

      dirty_responses.each_with_index do |dirty, index|
        expect(service.send(:clean_response, dirty)).to eq(clean_responses[index])
      end
    end

    it "handles responses without extra text" do
      clean_response = "A vibrant community for web developers"
      expect(service.send(:clean_response, clean_response)).to eq(clean_response)
    end

    it "handles empty or nil responses" do
      expect(service.send(:clean_response, "")).to eq("")
      expect(service.send(:clean_response, nil)).to eq("")
    end
  end

  describe "output validation" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    context "description validation" do
      it "validates description length correctly" do
        expect(service.send(:output_meets_expectations_for_description?, "")).to be false
        expect(service.send(:output_meets_expectations_for_description?, "Short")).to be true # In test env, only needs 5 chars
        expect(service.send(:output_meets_expectations_for_description?, "A good description")).to be true
        # Test with a string that's too long even for test environment
        expect(service.send(:output_meets_expectations_for_description?, "a" * 501)).to be false
      end
    end

    context "tagline validation" do
      it "validates tagline length correctly" do
        expect(service.send(:output_meets_expectations_for_tagline?, "")).to be false
        expect(service.send(:output_meets_expectations_for_tagline?, "A")).to be false # In test env, needs 2 chars
        expect(service.send(:output_meets_expectations_for_tagline?, "Good")).to be true
        # Test with a string that's too long even for test environment
        expect(service.send(:output_meets_expectations_for_tagline?, "a" * 101)).to be false
      end
    end

    context "content description validation" do
      it "validates content description length correctly" do
        expect(service.send(:output_meets_expectations_for_content_description?, "")).to be false
        expect(service.send(:output_meets_expectations_for_content_description?, "Short text")).to be true # In test env, only needs 10 chars
        expect(service.send(:output_meets_expectations_for_content_description?,
                            "A good content description with sufficient length")).to be true
        # Test with a string that's too long even for test environment
        expect(service.send(:output_meets_expectations_for_content_description?, "a" * 2001)).to be false
      end
    end
  end

  describe "prompt building" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    it "builds description prompt correctly" do
      comparable_descriptions = ["Community 1", "Community 2"]
      prompt = service.send(:build_description_prompt, comparable_descriptions)

      expect(prompt).to include("Generate a community description")
      expect(prompt).to include("Return ONLY the community description text")
      expect(prompt).to include("Do not include any introductory text")
      expect(prompt).to include("Community 1, Community 2")
      expect(prompt).to include("Provide ONLY the description text:")
    end

    it "builds tagline prompt correctly" do
      comparable_taglines = ["Tagline 1", "Tagline 2"]
      prompt = service.send(:build_tagline_prompt, comparable_taglines)

      expect(prompt).to include("Generate a tagline")
      expect(prompt).to include("Return ONLY the tagline text")
      expect(prompt).to include("Do not include any introductory text")
      expect(prompt).to include("Tagline 1, Tagline 2")
      expect(prompt).to include("Provide ONLY the tagline text:")
    end

    it "builds content description prompt correctly" do
      prompt = service.send(:build_content_description_prompt)

      expect(prompt).to include("Generate an internal content specification")
      expect(prompt).to include("Return ONLY the content specification text")
      expect(prompt).to include("Do not include any introductory text")
      expect(prompt).to include("Provide ONLY the content specification text:")
    end
  end
end
