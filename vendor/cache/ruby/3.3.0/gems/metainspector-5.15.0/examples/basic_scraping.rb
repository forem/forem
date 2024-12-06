# A basic MetaInspector example for scraping a page
#
# Usage example:
#
#   ruby basic_scraping.rb jaimeiniesta.com

require '../lib/metainspector'
puts "Using MetaInspector #{MetaInspector::VERSION}"

# Get the starting URL
url = ARGV[0] || (puts "Enter an url"; gets.strip)

page = MetaInspector.new(url)

puts "\nScraping #{page.url} returned these results:"
puts "\nTITLE: #{page.title}"
puts "META DESCRIPTION: #{page.meta['description']}"
puts "META KEYWORDS: #{page.meta['keywords']}"

puts "\n#{page.links.internal.size} internal links found..."
page.links.internal.each do |link|
  puts " ==> #{link}"
end

puts "\n#{page.links.external.size} external links found..."
page.links.external.each do |link|
  puts " ==> #{link}"
end

puts "\n#{page.links.non_http.size} non-http links found..."
page.links.non_http.each do |link|
  puts " ==> #{link}"
end

puts "\nto_hash..."
puts page.to_hash
