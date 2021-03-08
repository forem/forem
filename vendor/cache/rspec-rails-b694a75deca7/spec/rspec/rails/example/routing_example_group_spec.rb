module RSpec::Rails
  RSpec.describe RoutingExampleGroup do
    it_behaves_like "an rspec-rails example group mixin", :routing,
                    './spec/routing/', '.\\spec\\routing\\'

    describe "named routes" do
      it "delegates them to the route_set" do
        group = RSpec::Core::ExampleGroup.describe do
          include RoutingExampleGroup
        end

        example = group.new

        # Yes, this is quite invasive
        url_helpers = double('url_helpers', foo_path: "foo")
        routes = double('routes', url_helpers: url_helpers)
        allow(example).to receive_messages(routes: routes)

        expect(example.foo_path).to eq("foo")
      end
    end
  end
end
