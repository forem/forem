require "spec_helper"

describe JsRoutes, "compatibility with CJS"  do
  before(:each) do
    evaljs("module = { exports: null }")
    evaljs(JsRoutes.generate(
      module_type: 'CJS',
      include: /^inboxes/
    ))
  end

  it "should define module exports" do
    expectjs("module.exports.inboxes_path()").to eq(test_routes.inboxes_path())
  end
end
