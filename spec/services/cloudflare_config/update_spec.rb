require "rails_helper"
require "open3"

RSpec.describe CloudflareConfig::Update, type: :service do
  let(:account_id) { "cf_account_123" }
  let(:api_token) { "cf_token_456" }
  let(:worker_name) { "forem-edge" }
  let(:endpoint) { "https://api.cloudflare.com/client/v4/accounts/#{account_id}/workers/scripts/#{worker_name}" }
  let(:worker_path) { described_class::WORKER_SCRIPT_PATH }
  let(:local_script) { worker_path.read }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return(api_token)
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_ACCOUNT_ID").and_return(account_id)
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_WORKER_NAME").and_return(worker_name)
  end

  describe ".call" do
    it "does not upload when the remote Worker script matches config/cloudflare/worker.js" do
      get_response = instance_double(HTTParty::Response, code: 200, success?: true, body: local_script)
      allow(HTTParty).to receive(:get).with(
        endpoint,
        headers: hash_including("Authorization" => "Bearer #{api_token}"),
      ).and_return(get_response)
      allow(HTTParty).to receive(:put)

      expect(described_class.call).to be_nil
      expect(HTTParty).not_to have_received(:put)
    end

    it "uploads config/cloudflare/worker.js and logs stats when the remote Worker differs" do
      get_response = instance_double(HTTParty::Response, code: 200, success?: true, body: "// outdated worker")
      put_response = instance_double(HTTParty::Response, code: 200, success?: true, body: '{"success":true}')
      allow(HTTParty).to receive_messages(get: get_response, put: put_response)
      allow(ForemStatsClient).to receive(:increment)
      allow(Rails.logger).to receive(:info)

      expect(described_class.call).to be true

      expect(HTTParty).to have_received(:put).with(
        endpoint,
        headers: hash_including(
          "Authorization" => "Bearer #{api_token}",
          "Content-Type" => "application/javascript+module",
        ),
        body: local_script,
      )
      expect(ForemStatsClient).to have_received(:increment).with(
        "cloudflare.update",
        tags: ["worker_name:forem-edge", "configs_updated:Worker"],
      )
      expect(Rails.logger).to have_received(:info).with("Cloudflare Worker forem-edge updated.")
    end

    it "uploads config/cloudflare/worker.js when the Worker does not yet exist (404)" do
      get_response = instance_double(HTTParty::Response, code: 404, success?: false, body: "Not Found")
      put_response = instance_double(HTTParty::Response, code: 200, success?: true, body: '{"success":true}')
      allow(HTTParty).to receive_messages(get: get_response, put: put_response)

      expect(described_class.call).to be true
      expect(HTTParty).to have_received(:put)
    end
  end

  describe "static parity with config/fastly/snippets/*.vcl" do
    it "includes every allowed query parameter from safe_params_list.vcl" do
      vcl = Rails.root.join("config/fastly/snippets/safe_params_list.vcl").read
      vcl_params = vcl[/\^\(([^)]+)\)\$/, 1].split("|").uniq.sort

      worker_params_block = local_script[/export const SAFE_PARAMS = Object\.freeze\(\[(.*?)\]\);/m, 1]
      worker_params = worker_params_block.scan(/"([^"]+)"/).flatten.uniq.sort

      expect(worker_params).to eq(vcl_params)
    end

    it "includes every active geofencing country code from client_geolocation.vcl" do
      vcl = Rails.root.join("config/fastly/snippets/client_geolocation.vcl").read
      vcl_regions = vcl.scan(/"([A-Z]{2})":\s*"([A-Z]{2})"/).to_h

      worker_regions_block = local_script[
        /export const DEFAULT_ACTIVE_GEOFENCING_REGIONS = Object\.freeze\(\{(.*?)\}\);/m, 1
      ]
      worker_regions = worker_regions_block.scan(/([A-Z]{2}):\s*"([A-Z]{2})"/).to_h

      expect(worker_regions).to eq(vcl_regions)
    end

    it "includes every exact bad bot User-Agent from bad_bot_detection.vcl" do
      vcl = Rails.root.join("config/fastly/snippets/bad_bot_detection.vcl").read
      vcl_exact_bots = vcl.scan(/req\.http\.user-agent == "([^"]+)"/).flatten.reject { |ua| ua == "Ruby" }.uniq.sort

      worker_bots_block = local_script[/export const BAD_BOT_EXACT_USER_AGENTS = Object\.freeze\(\[(.*?)\]\);/m, 1]
      worker_exact_bots = worker_bots_block.scan(/"([^"]+)"/).flatten.map { |s| s.gsub('\u0040', "@") }.uniq.sort

      expect(worker_exact_bots).to eq(vcl_exact_bots)
    end
  end

  describe "runtime execution of config/cloudflare/worker.js" do
    it "replicates all 5 Fastly VCL snippets and Surrogate header translations" do
      node_test_script = <<~JS
        import assert from "node:assert/strict";
        import worker, {
          isBadBot,
          filterSafeParams,
          resolveGeolocation,
          resolveHostAndAuthHeaders,
          applyEdgeResponseHeaders,
          secureIsEqual,
        } from #{worker_path.to_s.to_json};

        // 1. bad_bot_detection.vcl parity
        assert.equal(isBadBot("", "/"), true);
        assert.equal(isBadBot("AhrefsBot/7.0", "/"), true);
        assert.equal(isBadBot("bytespider", "/"), true);
        assert.equal(isBadBot("Mozilla/5.0 (Win64; x64; rv:62.0) Gecko/20100101 Firefox/62.0", "/"), true);
        assert.equal(isBadBot("Ruby", "/articles"), true);
        assert.equal(isBadBot("Ruby", "/api/articles"), false);
        assert.equal(isBadBot("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36", "/"), false);

        // 2. safe_params_list.vcl parity
        const filtered = filterSafeParams(
          "https://dev.to/ben/post?page=2&utm_source=twitter&i=i&fbclid=123&sort=latest",
          new Headers(),
        );
        assert.equal(filtered.search, "?page=2&i=i&sort=latest");

        // Bypass query param stripping on /search/, /admin/, /ahoy/, /bulk_show, and authenticated /api
        const searchUrl = filterSafeParams("https://dev.to/search/feed_content?custom_param=1", new Headers());
        assert.equal(searchUrl.search, "?custom_param=1");

        const apiAuthedUrl = filterSafeParams(
          "https://dev.to/api/articles?custom_param=1",
          new Headers({ "api-key": "secret" }),
        );
        assert.equal(apiAuthedUrl.search, "?custom_param=1");

        const apiUnauthedUrl = filterSafeParams(
          "https://dev.to/api/articles?custom_param=1&page=3",
          new Headers(),
        );
        assert.equal(apiUnauthedUrl.search, "?page=3");

        // 3. client_geolocation.vcl parity
        assert.deepEqual(resolveGeolocation({ country: "US", regionCode: "NY" }), {
          clientGeo: "US-NY",
          cacheableClientGeo: "US",
        });
        assert.deepEqual(resolveGeolocation({ country: "SE", regionCode: "AB" }), {
          clientGeo: "SE-AB",
          cacheableClientGeo: "",
        });
        assert.deepEqual(resolveGeolocation({ country: "**" }), {
          clientGeo: null,
          cacheableClientGeo: null,
        });

        // 4. check_for_remember_user_token_in_cookie_to_set_header.vcl parity
        assert.equal(secureIsEqual("secret123", "secret123"), true);
        assert.equal(secureIsEqual("secret123", "secret124"), false);

        const loggedInPrimary = resolveHostAndAuthHeaders(
          "https://dev.to/",
          new Headers({ Host: "dev.to", Cookie: "remember_user_token=abc" }),
          { CLOUDFLARE_SECRET: "shared_secret" },
        );
        assert.equal(loggedInPrimary.xLoggedIn, "logged-in");
        assert.equal(loggedInPrimary.reqHost, "dev.to");
        assert.equal(loggedInPrimary.upstreamHost, "dev.to");
        assert.equal(loggedInPrimary.isPrimaryHost, true);

        const customDomainWithSecret = resolveHostAndAuthHeaders(
          "https://fallback.forem.com/",
          new Headers({
            Host: "fallback.forem.com",
            "X-Forem-Original-Host": "Community.Example.com",
            "X-Forem-Edge-Secret": "shared_secret",
          }),
          { CLOUDFLARE_SECRET: "shared_secret", ORIGIN_HOST: "practicaldev.herokuapp.com" },
        );
        assert.equal(customDomainWithSecret.xLoggedIn, "logged-out");
        assert.equal(customDomainWithSecret.reqHost, "community.example.com");
        assert.equal(customDomainWithSecret.upstreamHost, "practicaldev.herokuapp.com");
        assert.equal(customDomainWithSecret.isPrimaryHost, false);

        // 5. Response header translation & stale_while_revalidate_controls.vcl parity
        const primaryRespHeaders = applyEdgeResponseHeaders(
          new Headers({
            "Cache-Control": "public, no-cache",
            "Surrogate-Control": "max-age=86400, stale-if-error=26400",
            "Surrogate-Key": "articles/1 users/2",
            Vary: "Accept-Encoding, X-Req-Host",
          }),
          { reqHost: "dev.to", isPrimaryHost: true, pathname: "/", search: "?i=i", status: 200 },
        );
        assert.equal(primaryRespHeaders.get("Vary"), "Accept-Encoding, X-Loggedin");
        assert.equal(primaryRespHeaders.get("Cache-Tag"), "articles/1,users/2");
        assert.equal(
          primaryRespHeaders.get("CDN-Cache-Control"),
          "max-age=86400, stale-if-error=26400, stale-while-revalidate=60",
        );
        assert.equal(primaryRespHeaders.has("Surrogate-Control"), false);
        assert.equal(primaryRespHeaders.has("Surrogate-Key"), false);

        // Custom domain keeps X-Req-Host in Vary
        const customRespHeaders = applyEdgeResponseHeaders(
          new Headers({ "Surrogate-Control": "max-age=60" }),
          { reqHost: "custom.example.com", isPrimaryHost: false, pathname: "/post", search: "", status: 200 },
        );
        assert.equal(customRespHeaders.get("Vary"), "X-Loggedin, X-Req-Host");

        // Error caching: 30s on non-API >= 400 responses, never on /api
        const errorHtmlHeaders = applyEdgeResponseHeaders(new Headers(), {
          reqHost: "dev.to",
          isPrimaryHost: true,
          pathname: "/missing",
          search: "",
          status: 404,
        });
        assert.equal(errorHtmlHeaders.get("CDN-Cache-Control"), "max-age=30");

        const errorApiHeaders = applyEdgeResponseHeaders(new Headers(), {
          reqHost: "dev.to",
          isPrimaryHost: true,
          pathname: "/api/articles",
          search: "",
          status: 429,
        });
        assert.equal(errorApiHeaders.get("CDN-Cache-Control"), null);

        // End-to-end Worker fetch test
        const botReq = new Request("https://dev.to/", { headers: { "User-Agent": "AhrefsBot" } });
        const botRes = await worker.fetch(botReq, {});
        assert.equal(botRes.status, 403);
      JS

      stdout, stderr, status = Open3.capture3("node", "--input-type=module", "-e", node_test_script)
      expect(status.success?).to be(true), "Node worker test failed:\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    end
  end
end
