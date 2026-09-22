# Cloudflare for SaaS serves organization custom domains.
#
# An organization points its domain (e.g. blog.example.com) at the CNAME target
# below. Cloudflare issues the certificate for that hostname and forwards traffic
# to the Forem edge. See docs/custom_domains.md for the Cloudflare and Fastly setup.
module CloudflareSaas
  CNAME_TARGET_PREFIX = "cname".freeze

  def self.enabled?
    ApplicationConfig["CLOUDFLARE_SAAS_API_TOKEN"].present? &&
      ApplicationConfig["CLOUDFLARE_SAAS_ZONE_ID"].present?
  end

  # The hostname organizations point their custom domain at with a CNAME record.
  # It is the Cloudflare for SaaS fallback origin, e.g. cname.dev.to.
  def self.cname_target
    ApplicationConfig["CLOUDFLARE_SAAS_CNAME_TARGET"].presence ||
      "#{CNAME_TARGET_PREFIX}.#{Settings::General.app_domain}"
  end
end
