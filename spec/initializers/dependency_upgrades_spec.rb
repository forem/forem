require "rails_helper"

describe "Dependency Upgrades Verification" do
  describe "JsRoutes" do
    it "is loaded and generates routes JavaScript" do
      expect(defined?(JsRoutes)).to eq("constant")
      routes_js = JsRoutes.generate
      expect(routes_js).to include("JsRoutes")
      expect(routes_js).to include("rootPath")
    end
  end

  describe "Jbuilder" do
    it "renders templates successfully" do
      expect(defined?(Jbuilder)).to eq("constant")
      result = Jbuilder.new do |json|
        json.test_key "test_value"
      end.attributes!
      expect(result).to eq({ "test_key" => "test_value" })
    end
  end

  describe "PgSearch" do
    it "is loaded and configured" do
      expect(defined?(PgSearch)).to eq("constant")
      expect(PgSearch.respond_to?(:multisearch)).to be true
    end
  end

  describe "PgHero" do
    it "is loaded" do
      expect(defined?(PgHero)).to eq("constant")
    end
  end
end
