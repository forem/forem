require "capybara/cuprite"

# In Ferrum 0.14, `Page.frameStoppedLoading` sets `@event` before calling
# `document_node_id` (`DOM.getDocument`), and `DOM.documentUpdated` (e.g. from
# InstantClick or injected iframes) invalidates the CDP document root without
# re-fetching it. When `DOM.requestNode` is called before `DOM.getDocument`,
# Chrome returns `nodeId: 0` and `DOM.describeNode` raises `Ferrum::NodeNotFoundError`.
module FerrumRequestNodeDocumentRefresh
  private

  def handle_response(response)
    if response.is_a?(Hash) && response["type"] == "object" && response["subtype"] == "node"
      object_id = response["objectId"]
      node_id = @page.command("DOM.requestNode", objectId: object_id)["nodeId"]
      if node_id.zero?
        @page.document_node_id
        node_id = @page.command("DOM.requestNode", objectId: object_id)["nodeId"]
      end
      description = @page.command("DOM.describeNode", nodeId: node_id)["node"]
      return Ferrum::Node.new(self, @page.target_id, node_id, description)
    end

    super
  end
end

Ferrum::Frame.prepend(FerrumRequestNodeDocumentRefresh)

REMOTE_CHROME_URL = ENV.fetch("CHROME_URL", nil)
REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
  if REMOTE_CHROME_URL
    URI.parse(REMOTE_CHROME_URL).then do |uri|
      [uri.host, uri.port]
    end
  end

remote_chrome =
  begin
    if REMOTE_CHROME_URL.nil?
      false
    else
      Socket.tcp(REMOTE_CHROME_HOST, REMOTE_CHROME_PORT, connect_timeout: 1).close
      true
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
    false
  end

remote_options = remote_chrome ? { url: REMOTE_CHROME_URL } : {}

Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    browser_options: {},
    process_timeout: 60,
    timeout: 15,
    pending_connection_errors: false,
    inspector: true,
    headless: !ENV["HEADLESS"].in?(%w[n 0 no false]), **remote_options
  )
end
