RSpec.describe "route_to" do
  include RSpec::Rails::Matchers::RoutingMatchers
  include RSpec::Rails::Matchers::RoutingMatchers::RouteHelpers

  def assert_recognizes(*)
    # no-op
  end

  it "provides a description" do
    matcher = route_to("these" => "options")
    matcher.matches?(get: "path")
    expect(matcher.description).to eq("route {:get=>\"path\"} to {\"these\"=>\"options\"}")
  end

  it "delegates to assert_recognizes" do
    expect(self).to receive(:assert_recognizes).with({"these" => "options"}, {method: :get, path: "path"}, {})
    expect({get: "path"}).to route_to("these" => "options")
  end

  context "with shortcut syntax" do
    it "routes with extra options" do
      expect(self).to receive(:assert_recognizes).with({controller: "controller", action: "action", extra: "options"}, {method: :get, path: "path"}, {})
      expect(get("path")).to route_to("controller#action", extra: "options")
    end

    it "routes without extra options" do
      expect(self).to receive(:assert_recognizes).with(
        {controller: "controller", action: "action"},
        {method: :get, path: "path"},
        {}
      )
      expect(get("path")).to route_to("controller#action")
    end

    it "routes with one query parameter" do
      expect(self).to receive(:assert_recognizes).with(
        {controller: "controller", action: "action", queryitem: "queryvalue"},
        {method: :get, path: "path"},
        {'queryitem' => 'queryvalue'}
      )
      expect(get("path?queryitem=queryvalue")).to route_to("controller#action", queryitem: 'queryvalue')
    end

    it "routes with multiple query parameters" do
      expect(self).to receive(:assert_recognizes).with(
        {controller: "controller", action: "action", queryitem: "queryvalue", qi2: 'qv2'},
        {method: :get, path: "path"},
        {'queryitem' => 'queryvalue', 'qi2' => 'qv2'}
      )
      expect(get("path?queryitem=queryvalue&qi2=qv2")).to route_to("controller#action", queryitem: 'queryvalue', qi2: 'qv2')
    end

    it "routes with nested query parameters" do
      expect(self).to receive(:assert_recognizes).with(
        {:controller => "controller", :action => "action", 'queryitem' => {'qi2' => 'qv2'}},
        {method: :get, path: "path"},
        {'queryitem' => {'qi2' => 'qv2'}}
      )
      expect(get("path?queryitem[qi2]=qv2")).to route_to("controller#action", 'queryitem' => {'qi2' => 'qv2'})
    end

  end

  context "with should" do
    context "when assert_recognizes passes" do
      it "passes" do
        expect do
          expect({get: "path"}).to route_to("these" => "options")
        end.to_not raise_exception
      end
    end

    context "when assert_recognizes fails with an assertion failure" do
      it "fails with message from assert_recognizes" do
        def assert_recognizes(*)
          raise ActiveSupport::TestCase::Assertion.new("this message")
        end
        expect do
          expect({get: "path"}).to route_to("these" => "options")
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, "this message")
      end
    end

    context "when assert_recognizes fails with a routing error" do
      it "fails with message from assert_recognizes" do
        def assert_recognizes(*)
          raise ActionController::RoutingError.new("this message")
        end
        expect do
          expect({get: "path"}).to route_to("these" => "options")
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, "this message")
      end
    end

    context "when an exception is raised" do
      it "raises that exception" do
        def assert_recognizes(*)
          raise "oops"
        end
        expect do
          expect({get: "path"}).to route_to("these" => "options")
        end.to raise_exception("oops")
      end
    end
  end

  context "with should_not" do
    context "when assert_recognizes passes" do
      it "fails with custom message" do
        expect {
          expect({get: "path"}).not_to route_to("these" => "options")
        }.to raise_error(/expected \{:get=>"path"\} not to route to \{"these"=>"options"\}/)
      end
    end

    context "when assert_recognizes fails with an assertion failure" do
      it "passes" do
        def assert_recognizes(*)
          raise ActiveSupport::TestCase::Assertion.new("this message")
        end
        expect do
          expect({get: "path"}).not_to route_to("these" => "options")
        end.to_not raise_error
      end
    end

    context "when assert_recognizes fails with a routing error" do
      it "passes" do
        def assert_recognizes(*)
          raise ActionController::RoutingError.new("this message")
        end
        expect do
          expect({get: "path"}).not_to route_to("these" => "options")
        end.to_not raise_error
      end
    end

    context "when an exception is raised" do
      it "raises that exception" do
        def assert_recognizes(*)
          raise "oops"
        end
        expect do
          expect({get: "path"}).not_to route_to("these" => "options")
        end.to raise_exception("oops")
      end
    end
  end

  it "uses failure message from assert_recognizes" do
    def assert_recognizes(*)
      raise ActiveSupport::TestCase::Assertion, "this message"
    end
    expect do
      expect({"this" => "path"}).to route_to("these" => "options")
    end.to raise_error("this message")
  end
end
