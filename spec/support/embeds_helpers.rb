module EmbedsHelpers
  def stub_head_request(url, status_code = 200)
    stub_request(:head, url)
      .with(
        headers: {
          Accept: "*/*",
          "User-Agent": "#{Settings::Community.community_name} (#{URL.url})"
        },
      ).to_return(status: status_code, body: "", headers: {})
  end
end
