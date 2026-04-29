require_relative 'config/environment'
org = Organization.find_by(custom_domain: 'custom.org')
puts "Org: #{org.inspect}"
article = Article.last
puts "Article slug: #{article.slug}, Org id: #{article.organization_id}"
