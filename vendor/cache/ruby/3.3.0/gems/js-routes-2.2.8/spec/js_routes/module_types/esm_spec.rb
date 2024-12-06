require "active_support/core_ext/string/strip"
require "spec_helper"

describe JsRoutes, "compatibility with ESM"  do

  let(:generated_js) {
    JsRoutes.generate(module_type: 'ESM')
  }

  before(:each) do
    # export keyword is not supported by a simulated js environment
    evaljs(generated_js.gsub("export const ", "const "))
  end

  it "defines route helpers" do
    expectjs("inboxes_path()").to eq(test_routes.inboxes_path())
  end

  it "exports route helpers" do
    expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes(.:format)
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inboxes_path = /*#__PURE__*/ __jsr.r(
DOC
  end

  it "exports utility methods" do
    expect(generated_js).to include("export const serialize = ")
  end

  it "defines utility methods" do
    expectjs("serialize({a: 1, b: 2})").to eq({a: 1, b: 2}.to_param)
  end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }
    it "should have js routes code" do
      is_expected.to include("export const inbox_message_path = /*#__PURE__*/ __jsr.r(")
    end
  end
end
