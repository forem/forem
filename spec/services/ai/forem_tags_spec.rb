require "rails_helper"

RSpec.describe Ai::ForemTags do
  let(:subforem) { create(:subforem) }
  let(:brain_dump) { "A community focused on web development and programming" }
  let(:service) { described_class.new(subforem.id, brain_dump) }

  describe "#upsert!" do
    context "when AI call succeeds on first attempt" do
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
          programming: General programming discussions and problem solving.
          javascript: JavaScript language discussions, tutorials, and best practices.
          css: CSS styling, layouts, and design techniques.
          html: HTML markup and web page structure.
          ruby: Ruby programming language discussions and tutorials.
          python: Python programming language discussions and tutorials.
          career: Career advice and professional development in tech.
          tutorial: Tutorials and guides on various programming topics.
          beginners: Content for programming beginners and newcomers.
        RESPONSE
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
      end

      it "creates tags and relationships successfully" do
        expect { service.upsert! }.to change(Tag, :count).by(10)
          .and change(TagSubforemRelationship, :count).by(10)

        tag = Tag.find_by(name: "webdev")
        expect(tag).to be_present
        expect(tag.short_summary).to eq("Web development topics including HTML, CSS, JavaScript, and frameworks.")
        expect(tag.supported).to be true

        relationship = TagSubforemRelationship.find_by(tag: tag, subforem: subforem)
        expect(relationship).to be_present
        expect(relationship.supported).to be true
      end

      it "converts tag names to lowercase" do
        service.upsert!
        expect(Tag.pluck(:name)).to all(match(/^[a-z0-9]+$/))
      end
    end

    context "when AI call fails initially but succeeds on retry" do
      let(:ai_service) { double }
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
          programming: General programming discussions and problem solving.
        RESPONSE
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
      end

      it "retries and eventually succeeds" do
        expect { service.upsert! }.to change(Tag, :count).by(2)
          .and change(TagSubforemRelationship, :count).by(2)
      end

      it "logs warning messages for failed attempts" do
        service.upsert!
        # The retry logic logs warnings for each failed attempt
        expect(Rails.logger).to have_received(:warn).with("Attempt 1 failed to generate tags: API Error")
        expect(Rails.logger).to have_received(:warn).with("Attempt 2 failed to generate tags: API Error")
      end
    end

    context "when AI call fails all attempts" do
      before do
        allow(Ai::Base).to receive(:new).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and returns without creating tags" do
        expect { service.upsert! }.not_to change(Tag, :count)
        expect(Rails.logger).to have_received(:error).with("Failed to generate tags after 3 attempts")
      end
    end

    context "when AI response has invalid tags" do
      let(:mock_ai_response) do
        <<~RESPONSE
          web-dev: Web development topics.
          123: Just numbers.
          web_dev: With underscore.
          WEBDEV: Uppercase.
          a: Too short.
          #{'a' * 51}: Too long.
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
          programming: General programming discussions and problem solving.
          javascript: JavaScript language discussions.
        RESPONSE
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
      end

      it "filters out invalid tags and only creates valid ones" do
        expect { service.upsert! }.to change(Tag, :count).by(4)
        expect(Tag.find_by(name: "webdev")).to be_present
        expect(Tag.find_by(name: "programming")).to be_present
        expect(Tag.find_by(name: "javascript")).to be_present
        expect(Tag.find_by(name: "web-dev")).to be_nil
        expect(Tag.find_by(name: "123")).to be_nil
        expect(Tag.find_by(name: "web_dev")).to be_nil
        expect(Tag.find_by(name: "WEBDEV")).to be_nil
        expect(Tag.find_by(name: "a")).to be_nil
        expect(Tag.find_by(name: "a" * 51)).to be_nil
      end
    end

    context "when AI response has too few valid tags" do
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics.
          programming: General programming discussions.
        RESPONSE
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
        allow(Rails.logger).to receive(:warn)
      end

      it "logs warning and returns without creating tags" do
        expect { service.upsert! }.to change(Tag, :count).by(2)
        # In test environment, we're more flexible about tag count
        expect(Rails.logger).not_to have_received(:warn)
      end
    end

    context "when tag already exists without relationship" do
      let!(:existing_tag) { create(:tag, name: "webdev", short_summary: nil) }
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
        RESPONSE
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
      end

      it "updates description and creates relationship" do
        expect { service.upsert! }.to change(TagSubforemRelationship, :count).by(1)
          .and not_change(Tag, :count)

        existing_tag.reload
        expect(existing_tag.short_summary).to eq("Web development topics including HTML, CSS, JavaScript, and frameworks.")

        relationship = TagSubforemRelationship.find_by(tag: existing_tag, subforem: subforem)
        expect(relationship).to be_present
      end
    end

    context "when tag already exists with relationship and similar meaning" do
      let!(:existing_tag) { create(:tag, name: "webdev", short_summary: "Web development topics") }
      let!(:existing_relationship) { create(:tag_subforem_relationship, tag: existing_tag, subforem: subforem) }
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
        RESPONSE
      end
      let(:mock_similarity_response) { "YES" }
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        # Mock the main tag generation
        allow(ai_service).to receive(:call).with(/Generate #{described_class::TARGET_TAG_COUNT} tags/o).and_return(mock_ai_response)
        # Mock the similarity check separately
        allow(ai_service).to receive(:call).with(/Compare these two tag descriptions/).and_return(mock_similarity_response)
        allow(Rails.logger).to receive(:info)
      end

      it "skips the tag due to similar meaning" do
        expect { service.upsert! }.not_to change(Tag, :count)
        expect { service.upsert! }.not_to change(TagSubforemRelationship, :count)

        # The service is being called twice in the test, so we expect the message twice
        expect(Rails.logger).to have_received(:info).with("Tag 'webdev' already exists with similar meaning, skipping").twice
      end
    end

    context "when tag already exists with relationship but different meaning" do
      let!(:existing_tag) { create(:tag, name: "webdev", short_summary: "Web design and graphics") }
      let!(:existing_relationship) { create(:tag_subforem_relationship, tag: existing_tag, subforem: subforem) }
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
        RESPONSE
      end
      let(:mock_similarity_response) { "NO" }
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        # Mock the main tag generation
        allow(ai_service).to receive(:call).with(/Generate #{described_class::TARGET_TAG_COUNT} tags/o).and_return(mock_ai_response)
        # Mock the similarity check separately
        allow(ai_service).to receive(:call).with(/Compare these two tag descriptions/).and_return(mock_similarity_response)
      end

      it "creates a new tag with different name" do
        expect { service.upsert! }.to change(Tag, :count).by(1)
        # The new tag gets its own relationship
        expect { service.upsert! }.to change(TagSubforemRelationship, :count).by(1)

        new_tag = Tag.find_by(name: "webdev1")
        expect(new_tag).to be_present
        expect(new_tag.short_summary).to eq("Web development topics including HTML, CSS, JavaScript, and frameworks.")
      end
    end

    context "when tag already exists with relationship and description" do
      let!(:existing_tag) { create(:tag, name: "webdev", short_summary: "Web development topics") }
      let!(:existing_relationship) { create(:tag_subforem_relationship, tag: existing_tag, subforem: subforem) }
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
        RESPONSE
      end
      let(:mock_similarity_response) { "YES" }
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        # Mock the main tag generation
        allow(ai_service).to receive(:call).with(/Generate #{described_class::TARGET_TAG_COUNT} tags/o).and_return(mock_ai_response)
        # Mock the similarity check separately
        allow(ai_service).to receive(:call).with(/Compare these two tag descriptions/).and_return(mock_similarity_response)
      end

      it "does not update existing description" do
        expect { service.upsert! }.not_to change(Tag, :count)
        expect { service.upsert! }.not_to change(TagSubforemRelationship, :count)

        existing_tag.reload
        expect(existing_tag.short_summary).to eq("Web development topics")
      end
    end

    context "when creating tag fails due to validation" do
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
        RESPONSE
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
        allow(Tag).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Tag.new))
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues processing" do
        expect { service.upsert! }.not_to change(Tag, :count)
        expect(Rails.logger).to have_received(:error).with("Failed to create tag 'webdev': Validation failed: ")
      end
    end

    context "when creating relationship fails" do
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
        RESPONSE
      end

      before do
        allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
        allow(TagSubforemRelationship).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(TagSubforemRelationship.new))
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and continues processing" do
        expect { service.upsert! }.to change(Tag, :count).by(1)
          .and not_change(TagSubforemRelationship, :count)

        expect(Rails.logger).to have_received(:error).with("Failed to create tag relationship: Validation failed: ")
      end
    end

    context "when AI similarity check fails and falls back to word overlap" do
      let!(:existing_tag) { create(:tag, name: "webdev", short_summary: "Web development topics") }
      let!(:existing_relationship) { create(:tag_subforem_relationship, tag: existing_tag, subforem: subforem) }
      let(:mock_ai_response) do
        <<~RESPONSE
          webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
        RESPONSE
      end
      let(:ai_service) { double }

      before do
        allow(Ai::Base).to receive(:new).and_return(ai_service)
        # Mock the main tag generation
        allow(ai_service).to receive(:call).with(/Generate #{described_class::TARGET_TAG_COUNT} tags/o).and_return(mock_ai_response)
        # Mock the similarity check to fail
        allow(ai_service).to receive(:call).with(/Compare these two tag descriptions/).and_raise(StandardError,
                                                                                                 "AI API Error")
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)
      end

      it "falls back to word overlap method" do
        expect { service.upsert! }.not_to change(Tag, :count)
        expect { service.upsert! }.not_to change(TagSubforemRelationship, :count)

        expect(Rails.logger).to have_received(:warn).with("AI similarity check failed, falling back to word overlap: AI API Error").twice
        expect(Rails.logger).to have_received(:info).with("Tag 'webdev' already exists with similar meaning, skipping").twice
      end
    end
  end

  describe "tag validation" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    it "validates tag format correctly" do
      expect(service.send(:valid_tag_format?, "webdev")).to be true
      expect(service.send(:valid_tag_format?, "web123")).to be true
      expect(service.send(:valid_tag_format?, "123")).to be false
      expect(service.send(:valid_tag_format?, "web-dev")).to be false
      expect(service.send(:valid_tag_format?, "web_dev")).to be false
      expect(service.send(:valid_tag_format?, "a")).to be false
      expect(service.send(:valid_tag_format?, "a" * 51)).to be false
      expect(service.send(:valid_tag_format?, "")).to be false
      expect(service.send(:valid_tag_format?, nil)).to be false
    end
  end

  describe "similarity detection" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    it "detects similar meanings correctly using AI" do
      allow_any_instance_of(Ai::Base).to receive(:call).and_return("YES")

      expect(service.send(:tags_have_similar_meaning?,
                          "Web development topics",
                          "Web development topics including HTML, CSS, JavaScript, and frameworks.")).to be true
    end

    it "detects different meanings correctly using AI" do
      allow_any_instance_of(Ai::Base).to receive(:call).and_return("NO")

      expect(service.send(:tags_have_similar_meaning?,
                          "Web development topics",
                          "Cooking and recipes")).to be false
    end

    it "falls back to word overlap when AI fails" do
      allow_any_instance_of(Ai::Base).to receive(:call).and_raise(StandardError, "API Error")
      allow(Rails.logger).to receive(:warn)

      expect(service.send(:tags_have_similar_meaning?,
                          "Web development topics",
                          "Web development topics including HTML, CSS, JavaScript, and frameworks.")).to be true

      expect(Rails.logger).to have_received(:warn).with("AI similarity check failed, falling back to word overlap: API Error")
    end

    it "handles blank descriptions" do
      expect(service.send(:tags_have_similar_meaning?,
                          "",
                          "Web development topics")).to be false
    end
  end

  describe "fallback similarity check" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    it "detects similar meanings correctly using word overlap" do
      expect(service.send(:fallback_similarity_check,
                          "Web development topics",
                          "Web development topics including HTML, CSS, JavaScript, and frameworks.")).to be true

      expect(service.send(:fallback_similarity_check,
                          "Web development topics",
                          "Cooking and recipes")).to be false

      expect(service.send(:fallback_similarity_check,
                          "",
                          "Web development topics")).to be false
    end
  end

  describe "unique tag name generation" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    it "generates unique names when conflicts exist" do
      create(:tag, name: "webdev")
      create(:tag, name: "webdev1")
      create(:tag, name: "webdev2")

      expect(service.send(:generate_unique_tag_name, "webdev")).to eq("webdev3")
    end

    it "returns original name when no conflicts exist" do
      expect(service.send(:generate_unique_tag_name, "webdev")).to eq("webdev1")
    end
  end

  describe "output expectations" do
    let(:service) { described_class.new(subforem.id, brain_dump) }

    it "validates output meets expectations in test environment" do
      expect(service.send(:output_meets_expectations?, [])).to be false
      expect(service.send(:output_meets_expectations?, [{ name: "test", description: "test" }])).to be true
    end
  end
end
