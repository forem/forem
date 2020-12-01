# Generators are not automatically loaded by rails
require 'generators/rspec/feature/feature_generator'
require 'support/generators'

RSpec.describe Rspec::Generators::FeatureGenerator, type: :generator do
  setup_default_destination

  describe 'feature specs' do
    describe 'are generated independently from the command line' do
      before do
        run_generator %w[posts]
      end
      describe 'the spec' do
        subject(:feature_spec) { file('spec/features/posts_spec.rb') }
        it "exists" do
          expect(feature_spec).to exist
        end
        it "contains 'rails_helper'" do
          expect(feature_spec).to contain(/require 'rails_helper'/)
        end
        it "contains the feature" do
          expect(feature_spec).to contain(/^RSpec.feature \"Posts\", #{type_metatag(:feature)}/)
        end
      end
    end

    describe 'are generated with the correct namespace' do
      before do
        run_generator %w[folder/posts]
      end
      describe 'the spec' do
        subject(:feature_spec) { file('spec/features/folder/posts_spec.rb') }
        it "exists" do
          expect(feature_spec).to exist
        end
        it "contains the feature" do
          expect(feature_spec).to contain(/^RSpec.feature \"Folder::Posts\", #{type_metatag(:feature)}/)
        end
      end
    end

    describe 'are singularized appropriately with the --singularize flag' do
      before do
        run_generator %w[posts --singularize]
      end
      describe 'the spec' do
        subject(:feature_spec) { file('spec/features/post_spec.rb') }
        it "exists with the appropriate filename" do
          expect(feature_spec).to exist
        end
        it "contains the singularized feature" do
          expect(feature_spec).to contain(/^RSpec.feature \"Post\", #{type_metatag(:feature)}/)
        end
      end
    end

    describe "are not generated" do
      before do
        run_generator %w[posts --no-feature-specs]
      end
      describe "the spec" do
        subject(:feature_spec) { file('spec/features/posts_spec.rb') }
        it "does not exist" do
          expect(feature_spec).to_not exist
        end
      end
    end
  end
end
