module RSpec
  module Rails
    module Specs
      module Generators
        module Macros
          # Tell the generator where to put its output (what it thinks of as
          # Rails.root)
          def set_default_destination
            destination File.expand_path('../../tmp', __dir__)
          end

          def setup_default_destination
            set_default_destination
            before { prepare_destination }
          end
        end

        def self.included(klass)
          klass.extend(Macros)
          klass.include(RSpec::Rails::FeatureCheck)
        end

        RSpec.shared_examples_for 'a model generator with fixtures' do |name, class_name|
          before { run_generator [name, '--fixture'] }

          describe 'the spec' do
            subject { file("spec/models/#{name}_spec.rb") }

            it { is_expected.to exist }
            it { is_expected.to contain(/require 'rails_helper'/) }
            it { is_expected.to contain(/^RSpec.describe #{class_name}, #{type_metatag(:model)}/) }
          end

          describe 'the fixtures' do
            subject { file("spec/fixtures/#{name}.yml") }

            it { is_expected.to contain(Regexp.new('# Read about fixtures at https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html')) }
          end
        end

        RSpec.shared_examples_for "a request spec generator" do
          describe 'generated with flag `--no-request-specs`' do
            before do
              run_generator %w[posts --no-request-specs]
            end

            subject(:request_spec) { file('spec/requests/posts_spec.rb') }

            it "does not create the request spec" do
              expect(request_spec).not_to exist
            end
          end

          describe 'generated with no flags' do
            before do
              run_generator name
            end

            subject(:request_spec) { file(spec_file_name) }

            context 'When NAME=posts' do
              let(:name) { %w[posts] }
              let(:spec_file_name) { 'spec/requests/posts_spec.rb' }

              it "creates the request spec" do
                expect(request_spec).to exist
              end

              it "the generator requires 'rails_helper'" do
                expect(request_spec).to contain(/require 'rails_helper'/)
              end

              it "the generator describes the provided NAME without monkey " \
                 "patching setting the type to `:request`" do
                   expect(request_spec).to contain(
                     /^RSpec.describe \"Posts\", #{type_metatag(:request)}/
                   )
                 end

              it "the generator includes a sample GET request" do
                expect(request_spec).to contain(/describe "GET \/posts"/)
              end

              it "the generator sends the GET request to the index path" do
                expect(request_spec).to contain(/get posts_index_path/)
              end
            end

            context 'When NAME=api/posts' do
              let(:name) { %w[api/posts] }
              let(:spec_file_name) { 'spec/requests/api/posts_spec.rb' }

              it "creates the request spec" do
                expect(request_spec).to exist
              end

              it "the generator requires 'rails_helper'" do
                expect(request_spec).to contain(/require 'rails_helper'/)
              end

              it "the generator describes the provided NAME without monkey " \
                 "patching setting the type to `:request`" do
                   expect(request_spec).to contain(
                     /^RSpec.describe \"Api::Posts\", #{type_metatag(:request)}/
                   )
                 end

              it "the generator includes a sample GET request" do
                expect(request_spec).to contain(/describe "GET \/api\/posts\"/)
              end

              it "the generator sends the GET request to the index path" do
                expect(request_spec).to contain(/get api_posts_index_path\n/)
              end
            end
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Rails::Specs::Generators, type: :generator
end
