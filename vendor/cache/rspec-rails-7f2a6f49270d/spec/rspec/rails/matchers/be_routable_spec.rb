RSpec.describe "be_routable" do
  include RSpec::Rails::Matchers::RoutingMatchers
  attr_reader :routes

  before { @routes = double("routes") }

  it "provides a description" do
    expect(be_routable.description).to eq("be routable")
  end

  context "with should" do
    it "passes if routes recognize the path" do
      allow(routes).to receive(:recognize_path) { {} }
      expect do
        expect({get: "/a/path"}).to be_routable
      end.to_not raise_error
    end

    it "fails if routes do not recognize the path" do
      allow(routes).to receive(:recognize_path) { raise ActionController::RoutingError.new('ignore') }
      expect do
        expect({get: "/a/path"}).to be_routable
      end.to raise_error(/expected \{:get=>"\/a\/path"\} to be routable/)
    end
  end

  context "with should_not" do

    it "passes if routes do not recognize the path" do
      allow(routes).to receive(:recognize_path) { raise ActionController::RoutingError.new('ignore') }
      expect do
        expect({get: "/a/path"}).not_to be_routable
      end.to_not raise_error
    end

    it "fails if routes recognize the path" do
      allow(routes).to receive(:recognize_path) { {controller: "foo"} }
      expect do
        expect({get: "/a/path"}).not_to be_routable
      end.to raise_error(/expected \{:get=>"\/a\/path"\} not to be routable, but it routes to \{:controller=>"foo"\}/)
    end
  end
end
