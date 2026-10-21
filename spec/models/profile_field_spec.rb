require "rails_helper"

RSpec.describe ProfileField do
  describe "associations" do
    it { is_expected.to belong_to(:profile_field_group) }
  end

  describe "validations" do
    describe "builtin validations" do
      it { is_expected.to validate_presence_of(:attribute_name).on(:update) }
      it { is_expected.to validate_presence_of(:display_area) }
      it { is_expected.to validate_presence_of(:input_type) }
      it { is_expected.to validate_presence_of(:label) }
    end

    it "ensures the label is case-insensitively unique" do
      create(:profile_field, label: "Test")
      expect do
        described_class.create!(label: "tEsT")
      end.to raise_error(ActiveRecord::RecordInvalid, /Label has already been taken/)
    end

    describe "#maximum_header_field_count" do
      before do
        count = [0, described_class::HEADER_FIELD_LIMIT - described_class.header.count].max
        create_list(:profile_field, count, :header)
      end

      let(:expected_message) { /#{Regexp.quote(ProfileField::HEADER_LIMIT_MESSAGE)}/ }

      it "limits the number of header fields on create" do
        expect { create(:profile_field, :header) }
          .to raise_error(ActiveRecord::RecordInvalid, expected_message)
      end

      it "limits the number of header fields on update", :aggregate_errors do
        expect(described_class.header.count).to be >= 3
        profile_field = create(:profile_field, display_area: :left_sidebar)

        expect { profile_field.header! }
          .to raise_error(ActiveRecord::RecordInvalid, expected_message)
      end

      it "considers existing header fields valid even if we reached the maximum", :aggregate_errors do
        expect(described_class.header.count).to be >= 3

        expect { described_class.header.last.validate! }.not_to raise_error
      end
    end
  end

  describe "callbacks" do
    it "automatically generates an attribute name" do
      field = create(:profile_field, label: "Test? Test! 1")
      expect(field.attribute_name).to start_with("attribute_")
    end

    describe "#maximum_header_field_count" do
      it "limits the number of header fields" do
        count = [0, described_class::HEADER_FIELD_LIMIT - described_class.header.count].max
        create_list(:profile_field, count, :header)

        expected_message = /#{Regexp.quote(ProfileField::HEADER_LIMIT_MESSAGE)}/

        expect { create(:profile_field, :header) }
          .to raise_error(ActiveRecord::RecordInvalid, expected_message)
      end
    end
  end

  describe ".cached_display_area_fields" do
    before { RequestStore.clear! }
    after { RequestStore.clear! }

    it "memoizes display area fields in RequestStore and invalidates on save or destroy" do
      field = create(:profile_field, label: "Cached Header Field", display_area: :left_sidebar)

      first_lookup = described_class.cached_display_area_fields(:left_sidebar)
      expect(first_lookup["Cached Header Field"]).to eq(field.attribute_name)

      field.update!(label: "Updated Header Field")
      updated_lookup = described_class.cached_display_area_fields(:left_sidebar)
      expect(updated_lookup["Updated Header Field"]).to eq(field.attribute_name)
      expect(updated_lookup).not_to have_key("Cached Header Field")

      field.destroy!
      expect(described_class.cached_display_area_fields(:left_sidebar)).not_to have_key("Updated Header Field")
    end
  end
end
