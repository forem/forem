Feature: render_template matcher

  The `render_template` matcher is used to specify that a request renders a
  given template or layout.  It delegates to
  [`assert_template`](https://api.rubyonrails.org/classes/ActionController/TemplateAssertions.html#method-i-assert_template)

  It is available in controller specs (spec/controllers) and request
  specs (spec/requests).

  NOTE: use `redirect_to(:action => 'new')` for redirects, not `render_template`.

  Scenario: render_template with three possible options
    Given a file named "spec/controllers/gadgets_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe GadgetsController do
        describe "GET #index" do
          subject { get :index }

          it "renders the index template" do
            expect(subject).to render_template(:index)
            expect(subject).to render_template("index")
            expect(subject).to render_template("gadgets/index")
          end

          it "does not render a different template" do
            expect(subject).to_not render_template("gadgets/show")
          end
        end
      end
      """
    When I run `rspec spec/controllers/gadgets_spec.rb`
    Then the examples should all pass

  Scenario: specify that a request renders a given layout
    Given a file named "spec/controllers/gadgets_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe GadgetsController do
        describe "GET #index" do
          subject { get :index }

          it "renders the application layout" do
            expect(subject).to render_template("layouts/application")
          end

          it "does not render a different layout" do
            expect(subject).to_not render_template("layouts/admin")
          end
        end
      end
      """
    When I run `rspec spec/controllers/gadgets_spec.rb`
    Then the examples should all pass

  Scenario: render_template in a view spec
    Given a file named "spec/views/gadgets/index.html.erb_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "gadgets/index" do
        it "renders the index template" do
          assign(:gadgets, [Gadget.create!])
          render

          expect(view).to render_template(:index)
          expect(view).to render_template("index")
          expect(view).to render_template("gadgets/index")
        end

        it "does not render a different template" do
          expect(view).to_not render_template("gadgets/show")
        end
      end
      """
    When I run `rspec spec/views`
    Then the examples should all pass
