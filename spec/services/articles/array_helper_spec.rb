require "rails_helper"

RSpec.describe Articles::ArrayHelper, type: :helper do
  let(:odd_number) { 2 * rand(6) + 1 }
  let(:even_number) { 2 * rand(6) }
  let(:array_with_length_odd) { Array.new(odd_number) { rand(odd_number) } }
  let(:array_with_length_even) { Array.new(even_number) { rand(even_number) } }
  let(:empty_array) { [] }

  context "when split an array with odd length" do
    it "returns the first half of it" do
      first_half = described_class.first_half(array_with_length_odd)
      expect(first_half).to eq(array_with_length_odd[0...(odd_number / 2)])
      expect(first_half.length).to eq(odd_number / 2)
    end

    it "returns the second half of it" do
      second_half = described_class.last_half(array_with_length_odd)
      expect(second_half).to eq(array_with_length_odd[(odd_number / 2)..array_with_length_odd.length])
      expect(second_half.length).to eq((odd_number / 2) + 1)
    end
  end

  context "when split an array with even length" do
    it "returns the first half of it" do
      first_half = described_class.first_half(array_with_length_even)
      expect(first_half).to eq(array_with_length_even[0...(even_number / 2)])
      expect(first_half.length).to eq(even_number / 2)
    end

    it "returns the second half of it" do
      second_half = described_class.last_half(array_with_length_even)
      expect(second_half).to eq(array_with_length_even[(even_number / 2)..array_with_length_even.length])
      expect(second_half.length).to eq((even_number / 2))
    end
  end
end
