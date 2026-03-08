module Organizations
  class VerifyLinkback
    Result = Struct.new(:success?, :error, keyword_init: true)

    def self.call(organization)
      new(organization).call
    end

    def initialize(organization)
      @organization = organization
    end

    def call
      return fail!("No verification URL provided") if organization.verification_url.blank?
      return fail!("Organization has no website URL") if organization.url.blank?

      org_url = normalize_url(organization.url)
      verification_url = organization.verification_url

      unless same_domain?(verification_url, org_url)
        return fail!("Verification URL must be on the same domain as your website URL")
      end

      response = HTTParty.get(
        verification_url,
        timeout: 15,
        headers: { "User-Agent" => "Forem Organization Verification Bot" },
        follow_redirects: true,
      )

      unless response.success?
        return fail!("Could not reach the verification URL (HTTP #{response.code})")
      end

      doc = Nokogiri::HTML(response.body)
      org_path = organization.path
      forem_url = URL.url

      found = doc.css("a[href]").any? do |link|
        href = link["href"].to_s.strip
        matches_org_page?(href, forem_url, org_path)
      end

      if found
        organization.update_columns(verified: true, verified_at: Time.current,
                                    verification_status: "success", verification_error: nil)
        Result.new("success?": true, error: nil)
      else
        fail!("No link to your organization page was found on the verification URL")
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError => e
      fail!("Could not connect to the verification URL: #{e.message}")
    rescue StandardError => e
      fail!("Verification failed: #{e.message}")
    end

    private

    attr_reader :organization

    def fail!(message)
      organization.update_columns(verification_status: "failed", verification_error: message)
      Result.new("success?": false, error: message)
    end

    def normalize_url(url)
      url = "https://#{url}" unless url.match?(%r{\Ahttps?://}i)
      url
    end

    def same_domain?(url1, url2)
      host1 = URI.parse(normalize_url(url1)).host&.downcase&.sub(/\Awww\./, "")
      host2 = URI.parse(normalize_url(url2)).host&.downcase&.sub(/\Awww\./, "")
      return false if host1.blank? || host2.blank?

      host1 == host2 || host1.end_with?(".#{host2}") || host2.end_with?(".#{host1}")
    rescue URI::InvalidURIError
      false
    end

    def matches_org_page?(href, forem_url, org_path)
      # Check for full URL match (e.g., https://dev.to/myorg)
      return true if href.downcase.start_with?("#{forem_url}#{org_path}".downcase)

      # Check for path-only match (e.g., /myorg)
      return true if href.downcase == org_path.downcase

      false
    end
  end
end
