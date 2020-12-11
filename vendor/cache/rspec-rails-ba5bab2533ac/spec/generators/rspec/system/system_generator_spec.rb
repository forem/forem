# Generators are not automatically loaded by rails
if ::Rails::VERSION::STRING >= '5.1'
  require 'generators/rspec/system/system_generator'
  require 'support/generators'

  RSpec.describe Rspec::Generators::SystemGenerator, type: :generator do
    setup_default_destination

    describe "system specs" do
      subject(:system_spec) { file("spec/system/posts_spec.rb") }
      describe "are generated independently from the command line" do
        before do
          run_generator %w[posts]
        end
        describe "the spec" do
          it "exists" do
            expect(system_spec).to exist
          end
          it "contains 'rails_helper'" do
            expect(system_spec).to contain(/require 'rails_helper'/)
          end
          it "contains the system" do
            expect(system_spec).to contain(/^RSpec.describe \"Posts\", #{type_metatag(:system)}/)
          end
        end
      end

      describe "are not generated" do
        before do
          run_generator %w[posts --no-system-specs]
        end
        describe "the spec" do
          it "does not exist" do
            expect(system_spec).to_not exist
          end
        end
      end
    end
  end
end
