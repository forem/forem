module EdgeCache
  class BustOrganization < Bust
    def self.call(organization, slug)
      return unless organization && slug

      bust("/#{slug}")

      begin
        organization.articles.find_each do |article|
          bust(article.path)
        end
      rescue StandardError => e
        Rails.logger.error("Tag issue: #{e}")
      end
    end
  end
end
