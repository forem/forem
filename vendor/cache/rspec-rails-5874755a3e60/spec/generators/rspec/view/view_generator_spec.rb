# Generators are not automatically loaded by Rails
require 'generators/rspec/view/view_generator'
require 'support/generators'

RSpec.describe Rspec::Generators::ViewGenerator, type: :generator do
  setup_default_destination

  describe 'with default template engine' do
    it 'generates a spec for the supplied action' do
      run_generator %w[posts index]
      file('spec/views/posts/index.html.erb_spec.rb').tap do |f|
        expect(f).to contain(/require 'rails_helper'/)
        expect(f).to contain(/^RSpec.describe \"posts\/index\", #{type_metatag(:view)}/)
      end
    end

    describe 'with a nested resource' do
      it 'generates a spec for the supplied action' do
        run_generator %w[admin/posts index]
        file('spec/views/admin/posts/index.html.erb_spec.rb').tap do |f|
          expect(f).to contain(/require 'rails_helper'/)
          expect(f).to contain(/^RSpec.describe \"admin\/posts\/index\", #{type_metatag(:view)}/)
        end
      end
    end
  end

  describe 'with a specified template engine' do
    it 'generates a spec for the supplied action' do
      run_generator %w[posts index --template_engine haml]
      file('spec/views/posts/index.html.haml_spec.rb').tap do |f|
        expect(f).to contain(/require 'rails_helper'/)
        expect(f).to contain(/^RSpec.describe \"posts\/index\", #{type_metatag(:view)}/)
      end
    end
  end
end
