module EdgeCache
  class BustOrganization < Buster
    def self.call(organization, slug)
      return unless organization && slug

      buster = EdgeCache::Buster.new

      buster.bust("/#{slug}")

      begin
        organization.articles.find_each do |article|
          buster.bust(article.path)
        end
      rescue StandardError => e
        Rails.logger.error("Tag issue: #{e}")
      end
    end
  end
end
