# Generators are not automatically loaded by Rails
require 'generators/rspec/model/model_generator'
require 'support/generators'

RSpec.describe Rspec::Generators::ModelGenerator, type: :generator do
  setup_default_destination

  it 'runs both the model and fixture tasks' do
    gen = generator %w[posts]
    expect(gen).to receive :create_model_spec
    expect(gen).to receive :create_fixture_file
    gen.invoke_all
  end

  it_behaves_like 'a model generator with fixtures', 'admin/posts', 'Admin::Posts'
  it_behaves_like 'a model generator with fixtures', 'posts', 'Posts'

  describe 'the generated files' do
    describe 'without fixtures' do
      before do
        run_generator %w[posts]
      end

      describe 'the fixtures' do
        subject { file('spec/fixtures/posts.yml') }

        it { is_expected.not_to exist }
      end
    end
  end
end
