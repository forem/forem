require 'spec_helper'

describe JsRoutes, "options" do

  let(:generated_js) do
    JsRoutes.generate(
      module_type: nil,
      namespace: 'Routes',
      **_options
    )
  end

  before(:each) do
    evaljs(_presetup) if _presetup
    with_warnings(_warnings) do
      evaljs(generated_js)
      App.routes.default_url_options = _options[:default_url_options] || {}
    end
  end

  after(:each) do
    App.routes.default_url_options = {}
  end

  let(:_presetup) { nil }
  let(:_options) { {} }
  let(:_warnings) { true }

  describe "serializer" do
    context "when specified" do
      # define custom serializer
      # this is a nonsense serializer, which always returns foo=bar
      # for all inputs
      let(:_presetup){ %q(function myCustomSerializer(object, prefix) { return "foo=bar"; }) }
      let(:_options) { {:serializer => "myCustomSerializer"} }

      it "should set configurable serializer" do
        # expect the nonsense serializer above to have appened foo=bar
        # to the end of the path
        expectjs(%q(Routes.inboxes_path())).to eql("/inboxes?foo=bar")
      end
    end

    context "when specified, but not function" do
      let(:_presetup){ %q(var myCustomSerializer = 1) }
      let(:_options) { {:serializer => "myCustomSerializer"} }

      it "should throw error" do
      expect {
        evaljs(%q(Routes.inboxes_path({a: 1})))
      }.to raise_error(js_error_class)
      end
    end

    context "when configured in js" do
      let(:_options) { {:serializer =>%q(function (object, prefix) { return "foo=bar"; })} }

      it "uses JS serializer" do
        evaljs("Routes.configure({serializer: function (object, prefix) { return 'bar=baz'; }})")
        expectjs(%q(Routes.inboxes_path({a: 1}))).to eql("/inboxes?bar=baz")
      end
    end
  end

  context "when exclude is specified" do

    let(:_options) { {:exclude => /^admin_/} }

    it "should exclude specified routes from file" do
      expectjs("Routes.admin_users_path").to be_nil
    end

    it "should not exclude routes not under specified pattern" do
      expectjs("Routes.inboxes_path()").not_to be_nil
    end

    context "for rails engine" do
      let(:_options) { {:exclude => /^blog_app_posts/} }

      it "should exclude specified engine route" do
        expectjs("Routes.blog_app_posts_path").to be_nil
      end
    end
  end

  context "when include is specified" do

    let(:_options) { {:include => /^admin_/} }

    it "should exclude specified routes from file" do
      expectjs("Routes.admin_users_path()").not_to be_nil
    end

    it "should not exclude routes not under specified pattern" do
      expectjs("Routes.inboxes_path").to be_nil
    end

    context "with camel_case option" do
      let(:_options) { {include: /^admin_/, camel_case: true} }

      it "should exclude specified routes from file" do
        expectjs("Routes.adminUsersPath()").not_to be_nil
      end

      it "should not exclude routes not under specified pattern" do
        expectjs("Routes.inboxesPath").to be_nil
      end
    end

    context "for rails engine" do
      let(:_options) { {:include => /^blog_app_posts/} }

      it "should include specified engine route" do
        expectjs("Routes.blog_app_posts_path()").not_to be_nil
      end
    end
  end

  context "when prefix with trailing slash is specified" do

    let(:_options) { {:prefix => "/myprefix/" } }

    it "should render routing with prefix" do
        expectjs("Routes.inbox_path(1)").to eq("/myprefix#{test_routes.inbox_path(1)}")
    end

    it "should render routing with prefix set in JavaScript" do
      evaljs("Routes.configure({prefix: '/newprefix/'})")
      expectjs("Routes.config().prefix").to eq("/newprefix/")
      expectjs("Routes.inbox_path(1)").to eq("/newprefix#{test_routes.inbox_path(1)}")
    end

  end

  context "when prefix with http:// is specified" do

    let(:_options) { {:prefix => "http://localhost:3000" } }

    it "should render routing with prefix" do
      expectjs("Routes.inbox_path(1)").to eq(_options[:prefix] + test_routes.inbox_path(1))
    end
  end

  context "when prefix without trailing slash is specified" do

    let(:_options) { {:prefix => "/myprefix" } }

    it "should render routing with prefix" do
      expectjs("Routes.inbox_path(1)").to eq("/myprefix#{test_routes.inbox_path(1)}")
    end

    it "should render routing with prefix set in JavaScript" do
      evaljs("Routes.configure({prefix: '/newprefix/'})")
      expectjs("Routes.inbox_path(1)").to eq("/newprefix#{test_routes.inbox_path(1)}")
    end

  end

  context "when default format is specified" do
    let(:_options) { {:default_url_options => {format: "json"}} }
    let(:_warnings) { nil }

    if Rails.version >= "5"
      it "should render routing with default_format" do
        expectjs("Routes.inbox_path(1)").to eq(test_routes.inbox_path(1))
      end

      it "should render routing with default_format and zero object" do
        expectjs("Routes.inbox_path(0)").to eq(test_routes.inbox_path(0))
      end
    end

    it "should override default_format when spefified implicitly" do
      expectjs("Routes.inbox_path(1, {format: 'xml'})").to eq(test_routes.inbox_path(1, :format => "xml"))
    end

    it "should override nullify implicitly when specified implicitly" do
      expectjs("Routes.inbox_path(1, {format: null})").to eq(test_routes.inbox_path(1, format: nil))
    end

    it "shouldn't require the format" do
      expectjs("Routes.json_only_path()").to eq(test_routes.json_only_path)
    end
  end

  it "shouldn't include the format when {:format => false} is specified" do
    expectjs("Routes.no_format_path()").to eq(test_routes.no_format_path())
    expectjs("Routes.no_format_path({format: 'json'})").to eq(test_routes.no_format_path(format: 'json'))
  end

  describe "default_url_options" do
    context "with optional route parts" do
      context "provided by the default_url_options" do
        let(:_options) { { :default_url_options => { :optional_id => "12", :format => "json" } } }
        it "should use this options to fill optional parameters" do
          expectjs("Routes.things_path()").to eq(test_routes.things_path(12))
        end
      end

      context "provided inline by the method parameters" do
        let(:options) { { :default_url_options => { :optional_id => "12" } } }
        it "should overwrite the default_url_options" do
          expectjs("Routes.things_path({ optional_id: 34 })").to eq(test_routes.things_path(optional_id: 34))
        end
      end

      context "not provided" do
        let(:_options) { { :default_url_options => { :format => "json" } } }
        it "breaks" do
          expectjs("Routes.foo_all_path()").to eq(test_routes.foo_all_path)
        end
      end
    end

    context "with required route parts" do
      let(:_options) { { :default_url_options => { :inbox_id => "12" } } }
      it "should use this options to fill optional parameters" do
        expectjs("Routes.inbox_messages_path()").to eq(test_routes.inbox_messages_path)
      end
    end

    context "with optional and required route parts" do
      let(:_options) { {:default_url_options => { :optional_id => "12" } } }
      it "should use this options to fill the optional parameters" do
        expectjs("Routes.thing_path(1)").to eq test_routes.thing_path(1, { optional_id: "12" })
      end

      context "when passing options that do not have defaults" do
        it "should use this options to fill the optional parameters" do
          expectjs("Routes.thing_path(1, { format: 'json' })").to eq test_routes.thing_path(1, { optional_id: "12", format: "json" } ) # test_routes.thing_path needs optional_id here to generate the correct route. Not sure why.
        end
      end
    end

    context "when overwritten on JS level" do
        let(:_options) { { :default_url_options => { :format => "json" } } }
      it "uses JS defined value" do
        evaljs("Routes.configure({default_url_options: {format: 'xml'}})")
        expectjs("Routes.inboxes_path()").to eq(test_routes.inboxes_path(format: 'xml'))
      end
    end
  end

  describe "trailing_slash" do
    context "with default option" do
      let(:_options) { Hash.new }
      it "should working in params" do
        expectjs("Routes.inbox_path(1, {trailing_slash: true})").to eq(test_routes.inbox_path(1, :trailing_slash => true))
      end

      it "should working with additional params" do
        expectjs("Routes.inbox_path(1, {trailing_slash: true, test: 'params'})").to eq(test_routes.inbox_path(1, :trailing_slash => true, :test => 'params'))
      end
    end

    context "with default_url_options option" do
      let(:_options) { {:default_url_options => {:trailing_slash => true}} }
      it "should working" do
        expectjs("Routes.inbox_path(1, {test: 'params'})").to eq(test_routes.inbox_path(1, :trailing_slash => true, :test => 'params'))
      end

      it "should remove it by params" do
        expectjs("Routes.inbox_path(1, {trailing_slash: false})").to eq(test_routes.inbox_path(1, trailing_slash: false))
      end
    end

    context "with disabled default_url_options option" do
      let(:_options) { {:default_url_options => {:trailing_slash => false}} }
      it "should not use trailing_slash" do
        expectjs("Routes.inbox_path(1, {test: 'params'})").to eq(test_routes.inbox_path(1, :test => 'params'))
      end

      it "should use it by params" do
        expectjs("Routes.inbox_path(1, {trailing_slash: true})").to eq(test_routes.inbox_path(1, :trailing_slash => true))
      end
    end
  end

  describe "camel_case" do
    context "with default option" do
      let(:_options) { Hash.new }
      it "should use snake case routes" do
        expectjs("Routes.inbox_path(1)").to eq(test_routes.inbox_path(1))
        expectjs("Routes.inboxPath").to be_nil
      end
    end

    context "with true" do
      let(:_options) { { :camel_case => true } }
      it "should generate camel case routes" do
        expectjs("Routes.inbox_path").to be_nil
        expectjs("Routes.inboxPath").not_to be_nil
        expectjs("Routes.inboxPath(1)").to eq(test_routes.inbox_path(1))
        expectjs("Routes.inboxMessagesPath(10)").to eq(test_routes.inbox_messages_path(:inbox_id => 10))
      end
    end
  end

  describe "url_links" do
    context "with default option" do
      let(:_options) { Hash.new }
      it "should generate only path links" do
        expectjs("Routes.inbox_path(1)").to eq(test_routes.inbox_path(1))
        expectjs("Routes.inbox_url").to be_nil
      end
    end

    context "when configuring with default_url_options" do
      context "when only host option is specified" do
        let(:_options) { { :url_links => true, :default_url_options => {:host => "example.com"} } }

        it "uses the specified host, defaults protocol to http, defaults port to 80 (leaving it blank)" do
          expectjs("Routes.inbox_url(1)").to eq("http://example.com#{test_routes.inbox_path(1)}")
        end

        it "does not override protocol when specified in route" do
          expectjs("Routes.new_session_url()").to eq("https://example.com#{test_routes.new_session_path}")
        end

        it "does not override host when specified in route" do
          expectjs("Routes.sso_url()").to eq(test_routes.sso_url)
        end

        it "does not override port when specified in route" do
          expectjs("Routes.portals_url()").to eq("http://example.com:8080#{test_routes.portals_path}")
        end
      end

      context "when default host and protocol are specified" do
        let(:_options) { { :url_links => true, :default_url_options => {:host => "example.com", :protocol => "ftp"} } }

        it "uses the specified protocol and host, defaults port to 80 (leaving it blank)" do
          expectjs("Routes.inbox_url(1)").to eq("ftp://example.com#{test_routes.inbox_path(1)}")
        end

        it "does not override protocol when specified in route" do
          expectjs("Routes.new_session_url()").to eq("https://example.com#{test_routes.new_session_path}")
        end

        it "does not override host when host is specified in route" do
          expectjs("Routes.sso_url()").to eq("ftp://sso.example.com#{test_routes.sso_path}")
        end

        it "does not override port when specified in route" do
          expectjs("Routes.portals_url()").to eq("ftp://example.com:8080#{test_routes.portals_path}")
        end
      end

      context "when default host and port are specified" do
        let(:_options) { { :url_links => true, :default_url_options => {:host => "example.com", :port => 3000} } }

        it "uses the specified host and port, defaults protocol to http" do
          expectjs("Routes.inbox_url(1)").to eq("http://example.com:3000#{test_routes.inbox_path(1)}")
        end

        it "does not override protocol when specified in route" do
          expectjs("Routes.new_session_url()").to eq("https://example.com:3000#{test_routes.new_session_path}")
        end

        it "does not override host, protocol, or port when host is specified in route" do
          expectjs("Routes.sso_url()").to eq("http://sso.example.com:3000" + test_routes.sso_path)
        end

        it "does not override parts when specified in route" do
          expectjs("Routes.secret_root_url()").to eq(test_routes.secret_root_url)
        end
      end

      context "with camel_case option" do
        let(:_options) { { :camel_case => true, :url_links => true, :default_url_options => {:host => "example.com"} } }
        it "should generate path and url links" do
          expectjs("Routes.inboxUrl(1)").to eq("http://example.com#{test_routes.inbox_path(1)}")
        end
      end

      context "with prefix option" do
        let(:_options) { { :prefix => "/api", :url_links => true, :default_url_options => {:host => 'example.com'} } }
        it "should generate path and url links" do
          expectjs("Routes.inbox_url(1)").to eq("http://example.com/api#{test_routes.inbox_path(1)}")
        end
      end

      context "with compact option" do
        let(:_options) { { :compact => true, :url_links => true, :default_url_options => {:host => 'example.com'} } }
        it "does not affect url helpers" do
          expectjs("Routes.inbox_url(1)").to eq("http://example.com#{test_routes.inbox_path(1)}")
        end
      end
    end

    context 'when window.location is present' do
      let(:current_protocol) { 'http:' } # window.location.protocol includes the colon character
      let(:current_hostname) { 'current.example.com' }
      let(:current_port){ '' } # an empty string means port 80
      let(:current_host) do
        host = "#{current_hostname}"
        host += ":#{current_port}" unless current_port == ''
        host
      end

      let(:_presetup) do
        location =  {
          protocol: current_protocol,
          hostname: current_hostname,
          port: current_port,
          host: current_host,
        }
        [
          "const window = this;",
          "window.location = #{ActiveSupport::JSON.encode(location)};",
        ].join("\n")
      end

      context "without specifying a default host" do
        let(:_options) { { :url_links => true } }

        it "uses the current host" do
          expectjs("Routes.inbox_path").not_to be_nil
          expectjs("Routes.inbox_url").not_to be_nil
          expectjs("Routes.inbox_url(1)").to eq("http://current.example.com#{test_routes.inbox_path(1)}")
          expectjs("Routes.inbox_url(1, { test_key: \"test_val\" })").to eq("http://current.example.com#{test_routes.inbox_path(1, :test_key => "test_val")}")
          expectjs("Routes.new_session_url()").to eq("https://current.example.com#{test_routes.new_session_path}")
        end

        it "doesn't use current when specified in the route" do
          expectjs("Routes.sso_url()").to eq(test_routes.sso_url)
        end

        it "uses host option as an argument" do
          expectjs("Routes.secret_root_url({host: 'another.com'})").to eq(test_routes.secret_root_url(host: 'another.com'))
        end

        it "uses port option as an argument" do
          expectjs("Routes.secret_root_url({host: 'localhost', port: 8080})").to eq(test_routes.secret_root_url(host: 'localhost', port: 8080))
        end

        it "uses protocol option as an argument" do
          expectjs("Routes.secret_root_url({host: 'localhost', protocol: 'https'})").to eq(test_routes.secret_root_url(protocol: 'https', host: 'localhost'))
        end

        it "uses subdomain option as an argument" do
          expectjs("Routes.secret_root_url({subdomain: 'custom'})").to eq(test_routes.secret_root_url(subdomain: 'custom'))
        end
      end
    end

    context 'when window.location is not present' do
      context 'without specifying a default host' do
        let(:_options) { { url_links: true } }

        it 'generates path' do
          expectjs("Routes.inbox_url(1)").to eq test_routes.inbox_path(1)
          expectjs("Routes.new_session_url()").to eq test_routes.new_session_path
        end
      end
    end
  end

  describe "when the compact mode is enabled" do
    let(:_options) { { :compact => true } }
    it "removes _path suffix from path helpers" do
      expectjs("Routes.inbox_path").to be_nil
      expectjs("Routes.inboxes()").to eq(test_routes.inboxes_path())
      expectjs("Routes.inbox(2)").to eq(test_routes.inbox_path(2))
    end

    context "with url_links option" do
      around(:each) do |example|
        ActiveSupport::Deprecation.silence do
          example.run
        end
      end

      let(:_options) { { :compact => true, :url_links => true, default_url_options: {host: 'localhost'} } }
      it "should not strip urls" do
        expectjs("Routes.inbox(1)").to eq(test_routes.inbox_path(1))
        expectjs("Routes.inbox_url(1)").to eq("http://localhost#{test_routes.inbox_path(1)}")
      end
    end
  end

  describe "special_options_key" do
    let(:_options) { { special_options_key: :__options__ } }
    it "can be redefined" do
      expect {
        expectjs("Routes.inbox_message_path({inbox_id: 1, id: 2, _options: true})").to eq("")
      }.to raise_error(js_error_class)
      expectjs("Routes.inbox_message_path({inbox_id: 1, id: 2, __options__: true})").to eq(test_routes.inbox_message_path(inbox_id: 1, id: 2))
    end
  end

  describe "when application is specified" do
    let(:_options) { {:application => BlogEngine::Engine} }

    it "should include specified engine route" do
      expectjs("Routes.posts_path()").not_to be_nil
    end
  end

  describe "documentation option" do
    let(:_options) { {documentation: false} }

    it "disables documentation generation" do
      expect(generated_js).not_to include("@param")
      expect(generated_js).not_to include("@returns")
    end
  end
end
