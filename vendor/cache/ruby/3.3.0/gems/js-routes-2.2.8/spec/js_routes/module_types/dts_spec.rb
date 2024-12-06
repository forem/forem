
require "active_support/core_ext/string/strip"
require "fileutils"
require "open3"
require "spec_helper"

describe JsRoutes, "compatibility with DTS"  do

  OPTIONS = {module_type: 'DTS', include: [/^inboxes$/, /^inbox_message_attachment$/]}
  let(:extra_options) do
    {}
  end

  let(:generated_js) do
    JsRoutes.generate(**OPTIONS, **extra_options)
  end

  context "when file is generated" do
    let(:dir_name) do
       File.expand_path(__dir__ + "/dts")
    end

    let(:file_name) do
      dir_name + "/routes.spec.d.ts"
    end

    before do
      FileUtils.mkdir_p(dir_name)
      File.write(file_name, generated_js)
    end

    it "has no compile errors", :slow do
      command = "yarn tsc --strict --noEmit -p spec/tsconfig.json"
      stdout, stderr, status = Open3.capture3(command)
      expect(stderr).to eq("")
      expect(stdout).to include("Done in ")
      expect(status).to eq(0)
    end
  end

  context "when camel case is enabled" do
    let(:extra_options) { {camel_case: true} }

    it "camelizes route name and arguments" do

      expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes/:inbox_id/messages/:message_id/attachments/:id(.:format)
 * @param {any} inboxId
 * @param {any} messageId
 * @param {any} id
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inboxMessageAttachmentPath: ((
  inboxId: RequiredRouteParameter,
  messageId: RequiredRouteParameter,
  id: RequiredRouteParameter,
  options?: {format?: OptionalRouteParameter} & RouteOptions
) => string) & RouteHelperExtras;
DOC
    end
  end

  it "exports route helpers" do
    expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes(.:format)
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inboxes_path: ((
  options?: {format?: OptionalRouteParameter} & RouteOptions
) => string) & RouteHelperExtras;
DOC
    expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes/:inbox_id/messages/:message_id/attachments/:id(.:format)
 * @param {any} inbox_id
 * @param {any} message_id
 * @param {any} id
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inbox_message_attachment_path: ((
  inbox_id: RequiredRouteParameter,
  message_id: RequiredRouteParameter,
  id: RequiredRouteParameter,
  options?: {format?: OptionalRouteParameter} & RouteOptions
) => string) & RouteHelperExtras
DOC
  end

  it "exports utility methods" do
    expect(generated_js).to include("export const serialize: RouterExposedMethods['serialize'];")
  end

  it "prevents all types from automatic export" do
    expect(generated_js).to include("export {};")
  end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }
    it "should have js routes code" do
      is_expected.to include("export const inbox_message_path = /*#__PURE__*/ __jsr.r(")
    end
  end
end
