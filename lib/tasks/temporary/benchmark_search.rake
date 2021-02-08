# rubocop:disable Metrics/BlockLength
namespace :search do
  task benchmark: :environment do
    require "benchmark"

    # Struggling with too many iterations because ES keeps throwing "failed to get urandom" errors
    # on my macOS Catalina installation
    N = 3 # rubocop:disable Lint/ConstantDefinitionInBlock

    ActiveRecord::Base.logger = nil

    puts "Setup: #{Article.count} articles..."
    puts "Setup: #{Comment.count} comments..."
    puts "Setup: #{Listing.count} listings..."
    puts "Setup: #{Tag.count} tags..."
    puts "Setup: #{User.count} users..."

    feed_query = Comment.order(Arel.sql("RANDOM()")).take.body_markdown.split.sample
    listing_category_query = Listing.find_each.map(&:category).uniq.sample
    listing_query = Listing.order(Arel.sql("RANDOM()")).take.body_markdown.split.sample
    listing_tag_query = Listing.find_each.map(&:tag_list).flatten.uniq.sample
    tag = Tag.order(Arel.sql("RANDOM()")).take.name
    tag_query = tag.first(2)
    user = User.order(Arel.sql("RANDOM()")).take
    username = user.username

    # build a readinglist
    articles = Article.where.not(user: user).order(Arel.sql("RANDOM()")).first(3)
    articles.each do |article|
      user.reactions.readinglist.create!(user: user, reactable: article, category: :readinglist)
    end
    readinglist_query = articles.first.title.first(5).strip
    readinglist_tag_query = articles.map(&:tag_list).flatten.uniq.sample

    puts
    Benchmark.bm("Search Username - ES".length + 1) do |x|
      x.report("Search Username - ES") do
        N.times { Search::User.search_usernames(username) }
      end
      x.report("Search Username - PG") do
        N.times { Search::Postgres::UserUsername.search_documents(username) }
      end
    end

    puts
    Benchmark.bm("Search User - ES".length + 1) do |x|
      x.report("Search User - ES") do
        N.times { Search::User.search_documents(params: { search_fields: username }) }
      end
      x.report("Search User - PG") do
        N.times { Search::Postgres::User.search_documents(term: username) }
      end
    end

    puts
    Benchmark.bm("Search Tag - ES".length + 1) do |x|
      x.report("Search Tag - ES") do
        N.times { Search::Tag.search_documents("name:#{tag_query}* AND supported:true") }
      end
      x.report("Search Tag - PG") do
        N.times { Search::Postgres::Tag.search_documents("#{tag_query}*") }
      end
    end

    puts
    Benchmark.bm("Search ReadingList - ES".length + 1) do |x|
      x.report("Search ReadingList - ES") do
        N.times { Search::ReadingList.search_documents(params: { search_fields: readinglist_query }, user: user) }
      end
      x.report("Search ReadingList - PG") do
        N.times { Search::Postgres::ReadingList.search_documents(user, term: readinglist_query) }
      end
    end
    Benchmark.bm("Filter ReadingList by Tag - ES".length + 1) do |x|
      x.report("Filter ReadingList by Tag - ES") do
        N.times { Search::ReadingList.search_documents(params: { tag_names: [readinglist_tag_query] }, user: user) }
      end
      x.report("Filter ReadingList by Tag - PG") do
        N.times { Search::Postgres::ReadingList.search_documents(user, tags: [readinglist_tag_query]) }
      end
    end

    puts
    Benchmark.bm("Search Listing - ES".length + 1) do |x|
      x.report("Search Listing - ES") do
        N.times { Search::Listing.search_documents(params: { listing_search: listing_query }) }
      end
      x.report("Search Listing - PG") do
        N.times { Search::Postgres::Listing.search_documents(term: listing_query) }
      end
    end
    Benchmark.bm("Filter Listing by Category - ES".length + 1) do |x|
      x.report("Filter Listing by Category - ES") do
        N.times { Search::Listing.search_documents(params: { category: listing_category_query }) }
      end
      x.report("Filter Listing by Category - PG") do
        N.times { Search::Postgres::Listing.search_documents(category: listing_category_query) }
      end
    end
    Benchmark.bm("Filter Listing by Tag - ES".length + 1) do |x|
      x.report("Filter Listing by Tag - ES") do
        N.times { Search::Listing.search_documents(params: { tags: [listing_tag_query] }) }
      end
      x.report("Filter Listing by Tag - PG") do
        N.times { Search::Postgres::Listing.search_documents(tags: [listing_tag_query]) }
      end
    end

    puts
    Benchmark.bm("Search Feed - ES".length + 1) do |x|
      x.report("Search Feed - ES") do
        N.times { Search::FeedContent.search_documents(params: { search_fields: feed_query }) }
      end
      x.report("Search Feed - PG") do
        N.times { Search::Postgres::Listing.search_documents(term: feed_query) }
      end
    end
    Benchmark.bm("Homepage Feed - ES".length + 1) do |x|
      x.report("Homepage Feed - ES") do
        N.times do
          Search::FeedContent.search_documents(params: { sort_by: "hotness_score", sort_direction: "desc",
                                                         class_name: "Article" })
        end
      end
      x.report("Homepage Feed - PG") do
        N.times do
          Search::Postgres::Feed.search_documents(sort_by: :hotness_score, sort_direction: :desc, class_name: "Article")
        end
      end
    end
    Benchmark.bm("Homepage Feed - Week - ES".length + 1) do |x|
      published_at = { gte: 1.week.ago.rfc3339 }

      x.report("Homepage Feed - Week - ES") do
        N.times do
          Search::FeedContent.search_documents(params: { sort_by: "hotness_score", sort_direction: "desc",
                                                         class_name: "Article", published_at: published_at })
        end
      end
      x.report("Homepage Feed - Week - PG") do
        N.times do
          Search::Postgres::Feed.search_documents(sort_by: :hotness_score, sort_direction: :desc, class_name: "Article",
                                                  published_at: published_at)
        end
      end
    end
    Benchmark.bm("Homepage Feed - Latest - ES".length + 1) do |x|
      x.report("Homepage Feed - Latest - ES") do
        N.times do
          Search::FeedContent.search_documents(params: { sort_by: "published_at", sort_direction: "desc",
                                                         class_name: "Article" })
        end
      end
      x.report("Homepage Feed - Latest - PG") do
        N.times do
          Search::Postgres::Feed.search_documents(sort_by: :published_at, sort_direction: :desc, class_name: "Article")
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
