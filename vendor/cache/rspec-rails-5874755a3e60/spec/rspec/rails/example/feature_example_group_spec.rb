module RSpec::Rails
  RSpec.describe FeatureExampleGroup do
    it_behaves_like "an rspec-rails example group mixin", :feature,
                    './spec/features/', '.\\spec\\features\\'

    it "includes Rails route helpers" do
      with_isolated_stderr do
        Rails.application.routes.draw do
          get "/foo", as: :foo, to: "foo#bar"
        end
      end

      group = RSpec::Core::ExampleGroup.describe do
        include FeatureExampleGroup
      end

      expect(group.new.foo_path).to eq("/foo")
      expect(group.new.foo_url).to eq("http://www.example.com/foo")
    end

    context "when nested inside a request example group" do
      it "includes Rails route helpers" do
        Rails.application.routes.draw do
          get "/foo", as: :foo, to: "foo#bar"
        end

        outer_group = RSpec::Core::ExampleGroup.describe do
          include RequestExampleGroup
        end
        group = outer_group.describe do
          include FeatureExampleGroup
        end

        expect(group.new.foo_path).to eq("/foo")
        expect(group.new.foo_url).to eq("http://www.example.com/foo")
      end
    end

    describe "#visit" do
      it "raises an error informing about missing Capybara" do
        group = RSpec::Core::ExampleGroup.describe do
          include FeatureExampleGroup
        end

        expect {
          group.new.visit('/foobar')
        }.to raise_error(/Capybara not loaded/)
      end

      it "is resistant to load order errors" do
        capybara = Module.new do
          def visit(url)
            "success: #{url}"
          end
        end

        group = RSpec::Core::ExampleGroup.describe do
          include capybara
          include FeatureExampleGroup
        end

        expect(group.new.visit("/foo")).to eq("success: /foo")
      end
    end
  end
end
