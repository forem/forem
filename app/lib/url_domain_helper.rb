module UrlDomainHelper
  module_function

  def normalize_url(url)
    return url if url.match?(%r{\Ahttps?://}i)
    return "" if url.match?(/\A[a-z][a-z0-9+.-]*:/i)

    "https://#{url}"
  end

  def extract_host(url)
    URI.parse(normalize_url(url)).host&.downcase&.sub(/\Awww\./, "")
  rescue URI::InvalidURIError
    nil
  end

  def same_domain?(url1, url2)
    host1 = extract_host(url1)
    host2 = extract_host(url2)
    return false if host1.blank? || host2.blank?

    host1 == host2 || host1.end_with?(".#{host2}") || host2.end_with?(".#{host1}")
  end
end
