# A basic spider that will follow internal links, checking broken links
#
# Usage example:
#
#   ruby link_checker.rb example.com

require '../lib/metainspector'
puts "Using MetaInspector #{MetaInspector::VERSION}"

class BrokenLinkChecker

  def initialize(url)
    @url      = url
    @queue    = []
    @visited  = []
    @ok       = []
    @broken   = {}

    check
  end

  def report
    puts "\n#{@broken.size} broken links found."

    @broken.each do |link, from|
      puts "\n#{link} linked from"
      from.each do |origin|
        puts " - #{origin}"
      end
    end
  end

  private

  def check
    # Resolves redirections of initial URL before placing it on the queue
    @queue.push(MetaInspector.new(@url).url)

    process_next_on_queue while @queue.any?
  end

  def process_next_on_queue
    page = MetaInspector.new(@queue.pop)

    page.links.http.each do |link|
      check_status(link, page.url)
    end

    @visited.push(page.url)

    page.links.internal.each do |link|
      @queue.push(link) if should_be_enqueued?(link)
    end

    show_stats
  end

  # Checks the response status of the linked_url and stores it on the ok or broken collections
  def check_status(linked_url, from_url)
    if @broken.keys.include?(linked_url)
      # This was already known to be broken, we add another origin
      @broken[linked_url] << from_url
    else
      if !@ok.include?(linked_url)
        # We still don't know about this link status, so we check it now
        if reachable?(linked_url)
          @ok << linked_url
        else
          @broken[linked_url] = [from_url]
        end
      end
    end
  end

  def should_be_enqueued?(url)
    !(@visited.include?(url) || @broken.include?(url) || @queue.include?(url))
  end

  def show_stats
    puts "#{'%3s' % @visited.size} pages visited, #{'%3s' % @queue.size} pages on queue, #{'%2s' % @broken.size} broken links"
  end

  # A page is reachable if its response status is less than 400
  # In the case of exceptions, like timeouts or server connection errors,
  # we consider it unreachable
  def reachable?(url)
    page = MetaInspector.new(url)

    if page.response.status < 400
      true
    else
      false
    end
  rescue
    false
  end
end

# Get the starting URL
url = ARGV[0] || (puts "Enter a starting url"; gets.strip)

BrokenLinkChecker.new(url).report
