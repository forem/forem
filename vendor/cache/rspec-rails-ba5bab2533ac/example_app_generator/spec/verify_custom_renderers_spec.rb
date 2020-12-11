require 'rails_helper'

RSpec.describe "template rendering", type: :controller do
  context "without render_views" do
    context "with the standard renderers" do
      controller do
        def index
          render template: 'foo', layout: false
        end
      end

      it "renders the 'foo' template" do
        get :index

        expect(response).to render_template(:foo)
      end

      it "renders an empty string" do
        get :index

        expect(response.body).to eq("")
      end
    end

    context "with a String path prepended to the view path" do
      controller do
        def index
          prepend_view_path('app/views/some_templates')

          render template: 'bar', layout: false
        end
      end

      it "renders the 'bar' template" do
        get :index

        expect(response).to render_template(:bar)
      end

      it "renders an empty string", skip: Rails::VERSION::STRING.to_f >= 6.0 do
        get :index

        expect(response.body).to eq("")
      end
    end

    context "with a custom renderer prepended to the view path" do
      controller do
        def index
          prepend_view_path(MyResolver.new)

          render template: 'baz', layout: false
        end
      end

      it "renders the 'baz' template" do
        get :index

        expect(response).to render_template(:baz)
      end

      it "renders an empty string" do
        get :index

        expect(response.body).to eq("")
      end
    end
  end

  context "with render_views enabled" do
    render_views

    context "with the standard renderers" do
      controller do
        def index
          render template: 'foo', layout: false
        end
      end

      it "renders the 'foo' template" do
        get :index

        expect(response).to render_template(:foo)
      end

      it "renders the contents of the template" do
        get :index

        expect(response.body).to include("Static template named 'foo.html'")
      end
    end

    context "with a String path prepended to the view path" do
      controller do
        def index
          prepend_view_path('app/views/some_templates')

          render template: 'bar', layout: false
        end
      end

      it "renders the 'bar' template" do
        get :index

        expect(response).to render_template(:bar)
      end

      it "renders the contents of the template" do
        get :index

        expect(response.body).to include("Static template named 'bar.html'")
      end
    end

    context "with a custom renderer prepended to the view path" do
      controller do
        def index
          prepend_view_path(MyResolver.new)

          render template: 'baz', layout: false
        end
      end

      it "renders the 'baz' template" do
        get :index

        expect(response).to render_template(:baz)
      end

      it "renders the contents of the template" do
        get :index

        expect(response.body).to eq("Dynamic template with path '/baz'")
      end
    end
  end

  class MyResolver < ActionView::Resolver
    private

    def find_templates(name, prefix = nil, partial = false, _details = {}, _key = nil, _locals = [])
      name.prepend("_") if partial
      path = [prefix, name].join("/")
      template = find_template(name, path)

      [template]
    end

    def find_template(name, path)
      ActionView::Template.new(
        "",
        name,
        ->(template, _source = nil) { %("Dynamic template with path '#{template.virtual_path}'") },
        virtual_path: path,
        format: :html,
        locals: []
      )
    end
  end
end
