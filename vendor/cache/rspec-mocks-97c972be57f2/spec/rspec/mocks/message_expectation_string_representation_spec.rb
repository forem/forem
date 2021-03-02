module RSpec
  module Mocks
    RSpec.describe MessageExpectation, "has a nice string representation" do
      let(:test_double) { double }

      example "for a raw message expectation on a test double" do
        expect(allow(test_double).to receive(:foo)).to have_string_representation(
          "#<RSpec::Mocks::MessageExpectation #<Double (anonymous)>.foo(any arguments)>"
        )
      end

      example "for a raw message expectation on a partial double" do
        expect(allow("partial double".dup).to receive(:foo)).to have_string_representation(
          '#<RSpec::Mocks::MessageExpectation "partial double".foo(any arguments)>'
        )
      end

      example "for a message expectation constrained by `with`" do
        expect(allow(test_double).to receive(:foo).with(1, a_kind_of(String), any_args)).to have_string_representation(
          "#<RSpec::Mocks::MessageExpectation #<Double (anonymous)>.foo(1, a kind of String, *(any args))>"
        )
      end

      RSpec::Matchers.define :have_string_representation do |expected_representation|
        match do |object|
          values_match?(expected_representation, object.to_s) && object.to_s == object.inspect
        end

        failure_message do |object|
          "expected string representation: #{expected_representation}\n" \
          " but got string representation: #{object.to_s}"
        end
      end
    end
  end
end
