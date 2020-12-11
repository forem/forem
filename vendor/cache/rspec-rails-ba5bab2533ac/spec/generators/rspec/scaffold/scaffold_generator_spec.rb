# Generators are not automatically loaded by Rails
require 'generators/rspec/scaffold/scaffold_generator'
require 'support/generators'
require 'rspec/support/spec/in_sub_process'

RSpec.describe Rspec::Generators::ScaffoldGenerator, type: :generator do
  include RSpec::Support::InSubProcess
  setup_default_destination

  describe 'standard request specs' do
    subject { file('spec/requests/posts_spec.rb') }

    describe 'with no options' do
      before { run_generator %w[posts --request_specs] }
      it { is_expected.to exist }
      it { is_expected.to contain("require 'rails_helper'") }
      it { is_expected.to contain(/^RSpec.describe "\/posts", #{type_metatag(:request)}/) }
      it { is_expected.to contain('GET /new') }
      it { is_expected.to contain(/"redirects to the created post"/) }
      it { is_expected.to contain('get post_url(post)') }
      it { is_expected.to contain('redirect_to(post_url(Post.last))') }
      it { is_expected.to contain(/"redirects to the \w+ list"/) }
    end

    describe 'with --no-request_specs' do
      before { run_generator %w[posts --no-request_specs] }
      it { is_expected.not_to exist }
    end

    describe 'with --api' do
      before { run_generator %w[posts --api] }
      it { is_expected.to exist }
      it { is_expected.to contain(/require 'rails_helper'/) }
      it { is_expected.to contain(/^RSpec.describe "\/posts", #{type_metatag(:request)}/) }
      it { is_expected.to contain('as: :json') }
      it { is_expected.not_to contain('get new_posts_path') }
      it { is_expected.not_to contain(/"redirects to\w+"/) }
      it { is_expected.to contain('renders a JSON response with the new post') }
      it { is_expected.to contain('renders a JSON response with errors for the new post') }
      it { is_expected.not_to contain('get edit_posts_path') }
      it { is_expected.to contain('renders a JSON response with the post') }
      it { is_expected.to contain('renders a JSON response with errors for the post') }
    end

    describe 'in an engine' do
      it 'generates files with Engine url_helpers' do
        in_sub_process do
          allow_any_instance_of(::Rails::Generators::NamedBase).to receive(:mountable_engine?).and_return(true)
          run_generator %w[posts --request_specs]
          is_expected.to contain('Engine.routes.url_helpers')
        end
      end
    end
  end

  describe 'standard controller spec' do
    subject { file('spec/controllers/posts_controller_spec.rb') }

    describe 'with --controller_specs' do
      before { run_generator %w[posts --controller_specs] }
      it { is_expected.to contain(/require 'rails_helper'/) }
      it { is_expected.to contain(/^RSpec.describe PostsController, #{type_metatag(:controller)}/) }
      it { is_expected.to contain(/GET #new/) }
      it { is_expected.to contain(/"redirects to the created \w+"/) }
      it { is_expected.to contain(/display the 'new' template/) }
      it { is_expected.not_to contain(/"renders a JSON response with the new \w+"/) }
      it { is_expected.not_to contain(/"renders a JSON response with errors for the new \w+"/) }

      it { is_expected.to contain(/GET #edit/) }
      it { is_expected.to contain(/"redirects to the \w+"/) }
      it { is_expected.to contain(/display the 'edit' template/) }
      it { is_expected.not_to contain(/"renders a JSON response with the \w+"/) }
      it { is_expected.not_to contain(/"renders a JSON response with errors for the \w+"/) }

      it { is_expected.to contain(/"redirects to the \w+ list"/) }
    end

    describe 'with no options' do
      before { run_generator %w[posts] }
      it { is_expected.not_to exist }
    end

    describe 'with --api' do
      before { run_generator %w[posts --controller_specs --api] }
      it { is_expected.to contain(/require 'rails_helper'/) }
      it { is_expected.to contain(/^RSpec.describe PostsController, #{type_metatag(:controller)}/) }
      it { is_expected.not_to contain(/GET #new/) }
      it { is_expected.not_to contain(/"redirects to the created \w+"/) }
      it { is_expected.not_to contain(/display the 'new' template/) }
      it { is_expected.to contain(/"renders a JSON response with the new \w+"/) }
      it { is_expected.to contain(/"renders a JSON response with errors for the new \w+"/) }
      it { is_expected.not_to contain(/GET #edit/) }
      it { is_expected.not_to contain(/"redirects to the \w+"/) }
      it { is_expected.not_to contain(/display the 'edit' template/) }
      it { is_expected.to contain(/"renders a JSON response with the \w+"/) }
      it { is_expected.to contain(/"renders a JSON response with errors for the \w+"/) }

      it { is_expected.not_to contain(/"redirects to the \w+ list"/) }
    end
  end

  describe 'namespaced request spec' do
    subject { file('spec/requests/admin/posts_spec.rb') }
    before  { run_generator %w[admin/posts] }
    it { is_expected.to exist }
    it { is_expected.to contain(/^RSpec.describe "\/admin\/posts", #{type_metatag(:request)}/) }
    it { is_expected.to contain('admin_post_url(admin_post)') }
    it { is_expected.to contain('Admin::Post.create') }
  end

  describe 'namespaced controller spec' do
    subject { file('spec/controllers/admin/posts_controller_spec.rb') }
    before  { run_generator %w[admin/posts --controller_specs] }
    it { is_expected.to contain(/^RSpec.describe Admin::PostsController, #{type_metatag(:controller)}/) }
  end

  describe 'view specs' do
    describe 'with no options' do
      before { run_generator %w[posts] }

      describe 'edit' do
        subject { file("spec/views/posts/edit.html.erb_spec.rb") }
        it { is_expected.to exist }
        it { is_expected.to contain(/require 'rails_helper'/) }
        it { is_expected.to contain(/^RSpec.describe "(.*)\/edit", #{type_metatag(:view)}/) }
        it { is_expected.to contain(/it "renders the edit (.*) form"/) }
      end

      describe 'index' do
        subject { file("spec/views/posts/index.html.erb_spec.rb") }
        it { is_expected.to exist }
        it { is_expected.to contain(/require 'rails_helper'/) }
        it { is_expected.to contain(/^RSpec.describe "(.*)\/index", #{type_metatag(:view)}/) }
        it { is_expected.to contain(/it "renders a list of (.*)"/) }
      end

      describe 'new' do
        subject { file("spec/views/posts/new.html.erb_spec.rb") }
        it { is_expected.to exist }
        it { is_expected.to contain(/require 'rails_helper'/) }
        it { is_expected.to contain(/^RSpec.describe "(.*)\/new", #{type_metatag(:view)}/) }
        it { is_expected.to contain(/it "renders new (.*) form"/) }
      end

      describe 'show' do
        subject { file("spec/views/posts/show.html.erb_spec.rb") }
        it { is_expected.to exist }
        it { is_expected.to contain(/require 'rails_helper'/) }
        it { is_expected.to contain(/^RSpec.describe "(.*)\/show", #{type_metatag(:view)}/) }
        it { is_expected.to contain(/it "renders attributes in <p>"/) }
      end
    end

    describe 'with multiple integer attributes index' do
      before { run_generator %w[posts upvotes:integer downvotes:integer] }
      subject { file("spec/views/posts/index.html.erb_spec.rb") }
      it { is_expected.to exist }
      it { is_expected.to contain('assert_select "tr>td", text: 2.to_s, count: 2') }
      it { is_expected.to contain('assert_select "tr>td", text: 3.to_s, count: 2') }
    end

    describe 'with multiple float attributes index' do
      before { run_generator %w[posts upvotes:float downvotes:float] }
      subject { file("spec/views/posts/index.html.erb_spec.rb") }
      it { is_expected.to exist }
      it { is_expected.to contain('assert_select "tr>td", text: 2.5.to_s, count: 2') }
      it { is_expected.to contain('assert_select "tr>td", text: 3.5.to_s, count: 2') }
    end

    if Rails.version.to_f >= 5.1
      describe 'with reference attribute' do
        before { run_generator %w[posts title:string author:references] }
        describe 'edit' do
          subject { file("spec/views/posts/edit.html.erb_spec.rb") }
          it { is_expected.to contain(/assert_select "input\[name=\?\]", "post\[author_id\]/) }
          it { is_expected.to contain(/assert_select "input\[name=\?\]", "post\[title\]/) }
        end

        describe 'new' do
          subject { file("spec/views/posts/new.html.erb_spec.rb") }
          it { is_expected.to contain(/assert_select "input\[name=\?\]", "post\[author_id\]"/) }
          it { is_expected.to contain(/assert_select "input\[name=\?\]", "post\[title\]/) }
        end
      end
    else
      describe 'with reference attribute' do
        before { run_generator %w[posts title:string author:references] }
        describe 'edit' do
          subject { file("spec/views/posts/edit.html.erb_spec.rb") }
          it { is_expected.to contain(/assert_select "input#(.*)_author_id\[name=\?\]", "\1\[author_id\]/) }
          it { is_expected.to contain(/assert_select "input#(.*)_title\[name=\?\]", "\1\[title\]/) }
        end

        describe 'new' do
          subject { file("spec/views/posts/new.html.erb_spec.rb") }
          it { is_expected.to contain(/assert_select "input#(.*)_author_id\[name=\?\]", "\1\[author_id\]"/) }
          it { is_expected.to contain(/assert_select "input#(.*)_title\[name=\?\]", "\1\[title\]/) }
        end
      end
    end

    describe 'with --no-template-engine' do
      before { run_generator %w[posts --no-template-engine] }
      describe 'edit' do
        subject { file("spec/views/posts/edit.html._spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'index' do
        subject { file("spec/views/posts/index.html._spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'new' do
        subject { file("spec/views/posts/new.html._spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'show' do
        subject { file("spec/views/posts/show.html._spec.rb") }
        it { is_expected.not_to exist }
      end
    end

    describe 'with --api' do
      before { run_generator %w[posts --api] }

      describe 'edit' do
        subject { file("spec/views/posts/edit.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'index' do
        subject { file("spec/views/posts/index.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'new' do
        subject { file("spec/views/posts/index.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'show' do
        subject { file("spec/views/posts/index.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end
    end

    describe 'with --no-view-specs' do
      before { run_generator %w[posts --no-view-specs] }

      describe 'edit' do
        subject { file("spec/views/posts/edit.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'index' do
        subject { file("spec/views/posts/index.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'new' do
        subject { file("spec/views/posts/new.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end

      describe 'show' do
        subject { file("spec/views/posts/show.html.erb_spec.rb") }
        it { is_expected.not_to exist }
      end
    end
  end

  describe 'routing spec' do
    subject { file('spec/routing/posts_routing_spec.rb') }

    describe 'with default options' do
      before { run_generator %w[posts] }
      it { is_expected.to contain(/require "rails_helper"/) }
      it { is_expected.to contain(/^RSpec.describe PostsController, #{type_metatag(:routing)}/) }
      it { is_expected.to contain(/describe "routing"/) }
      it { is_expected.to contain(/routes to #new/) }
      it { is_expected.to contain(/routes to #edit/) }
      it { is_expected.to contain('route_to("posts#new")') }
    end

    describe 'with --no-routing-specs' do
      before { run_generator %w[posts --no-routing_specs] }
      it { is_expected.not_to exist }
    end

    describe 'with --api' do
      before { run_generator %w[posts --api] }
      it { is_expected.not_to contain(/routes to #new/) }
      it { is_expected.not_to contain(/routes to #edit/) }
    end

    context 'with a namespaced name' do
      subject { file('spec/routing/api/v1/posts_routing_spec.rb') }

      describe 'with default options' do
        before { run_generator %w[api/v1/posts] }
        it { is_expected.to contain(/^RSpec.describe Api::V1::PostsController, #{type_metatag(:routing)}/) }
        it { is_expected.to contain('route_to("api/v1/posts#new")') }
      end
    end
  end
end
