module EmbedsHelpers
  def stub_get_request(url, status_code = 200)
    stub_request(:get, url)
      .with(
        headers: {
          Accept: "*/*",
          "User-Agent": "#{Settings::Community.community_name} (#{URL.url})"
        },
      ).to_return(status: status_code, body: "", headers: {})
  end
end
