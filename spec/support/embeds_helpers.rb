module EmbedsHelpers
  def stub_request_head(url, status_code = 200)
    stub_request(:head, url)
      .with(
        headers: {
          Accept: "*/*",
          "User-Agent": "Ruby"
        },
      ).to_return(status: status_code, body: "", headers: {})
  end
end
