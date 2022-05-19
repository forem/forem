module EmbedsHelpers
  def stub_network_request(url:, method: :head, status_code: 200)
    stub_request(method, url)
      .with(
        headers: {
          Accept: "*/*",
          "User-Agent": "#{Settings::Community.community_name} (#{URL.url})"
        },
      ).to_return(status: status_code, body: "", headers: {})
  end

  def stub_metainspector_request(url, status_code = 200)
    stub_request(:get, url)
      .with(
        headers: {
          Accept: "*/*",
          "Accept-Encoding": "identity",
          "User-Agent": "MetaInspector/5.12.0 (+https://github.com/jaimeiniesta/metainspector)"
        },
      ).to_return(status: status_code, body: "", headers: {})
  end
end
