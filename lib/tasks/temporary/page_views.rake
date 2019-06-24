namespace :page_views do
  desc "Update domain and path from page views referrers"
  task update_domain_path: :environment do
    puts "Going to update #{PageView.count} users"

    ActiveRecord::Base.transaction do
      PageView.find_each do |pv|
        parsed_url = Addressable::URI.parse(pv.referrer || '')
        pv.update!(domain: parsed_url.domain, path: parsed_url.path)
      end
    end

    puts "All done now!"
  end
end
