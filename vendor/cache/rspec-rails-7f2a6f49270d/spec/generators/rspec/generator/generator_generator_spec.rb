require 'generators/rspec/generator/generator_generator'
require 'support/generators'

RSpec.describe Rspec::Generators::GeneratorGenerator, type: :generator do
  setup_default_destination

  describe "generator specs" do
    subject(:generator_spec) { file("spec/generator/posts_generator_spec.rb") }
    before do
      run_generator %w[posts]
    end
    it "creates the spec file by default" do
      expect(generator_spec).to exist
    end
    it "contains 'rails_helper in the spec file'" do
      expect(generator_spec).to contain(/require 'rails_helper'/)
    end
    it "includes the generator type in the metadata" do
      expect(generator_spec).to contain(/^RSpec.describe \"Posts\", #{type_metatag(:generator)}/)
    end
  end
end
