# rubocop:disable Metrics/BlockLength
namespace :db do
  namespace :seed do
    desc <<~DESC
      Seed analytics data (PageViews, Reactions, Comments, Follows) for local development.
      Works on any local DB state — creates missing users, articles, and org articles as needed.

      Usage:
        rails db:seed:analytics                          # auto-detect user, seed all their orgs
        USER_ID=8 rails db:seed:analytics                # specific user, all their orgs
        ORG_ID=2 rails db:seed:analytics                 # auto-detect user, specific org only
        USER_ID=8 ORG_ID=2 rails db:seed:analytics       # specific user, specific org
        DAYS=90 rails db:seed:analytics                  # custom date range (default: 60)

      Re-runnable: reactions and follows skip duplicates, page views and comments accumulate.
    DESC
    task analytics: :environment do
      raise "Seeding production is not allowed!" if Rails.env.production?

      days_back = (ENV["DAYS"] || 60).to_i

      referrer_domains = %w[
        google.com twitter.com github.com reddit.com linkedin.com
        facebook.com dev.to hackernews.com medium.com stackoverflow.com
      ].freeze
      reaction_categories = %w[like readinglist unicorn].freeze
      comment_templates = [
        "Great article, thanks for sharing!",
        "This is really helpful, I learned something new.",
        "Interesting take on this topic.",
        "I've been looking for exactly this kind of content.",
        "Nice writeup! Would love to see a follow-up.",
        "Thanks for the detailed explanation.",
        "Solid post, bookmarked for later.",
        "This helped me solve a problem I was stuck on.",
      ].freeze

      # --- Helper: create a user with Faker ---
      create_seed_user = lambda {
        fname = Faker::Name.unique.first_name
        lname = Faker::Name.unique.last_name
        username = "#{fname}#{lname}#{rand(100..999)}".downcase.gsub(/[^a-z0-9]/, "")
        User.create!(
          name: "#{fname} #{lname}",
          email: "#{username}@seed.local",
          username: username,
          confirmed_at: Time.current,
          registered_at: Time.current,
          registered: true,
          password: "password",
          password_confirmation: "password",
        )
      }

      # --- Resolve target user ---
      user = if ENV["USER_ID"]
               User.find(ENV["USER_ID"])
             else
               User.joins(:articles).merge(Article.published).first ||
                 User.find_by(email: "admin@forem.local") ||
                 User.first
             end

      unless user
        puts "No users found. Creating a seed user..."
        user = create_seed_user.call
        puts "  Created user '#{user.username}' (ID: #{user.id})"
      end

      # --- Ensure enough other users for realistic engagement ---
      other_users = User.where.not(id: user.id).to_a
      needed = 3 - other_users.size
      if needed.positive?
        puts "Only #{other_users.size} other user(s) found. Creating #{needed} more..."
        needed.times do
          new_user = create_seed_user.call
          puts "  Created user '#{new_user.username}' (ID: #{new_user.id})"
          other_users << new_user
        end
      end

      # Ensure all other users have registered_at (required by CalculateReactionPoints)
      other_users.each do |u|
        u.update_column(:registered_at, 6.months.ago) if u.registered_at.nil?
      end

      # --- Helper: ensure articles exist for a user (optionally under an org) ---
      ensure_articles = lambda { |owner, org: nil|
        scope = org ? org.articles.published : owner.articles.published
        return scope if scope.exists?

        label = org ? "org '#{org.name}'" : "user '#{owner.username}'"
        count = org ? 3 : 5
        puts "  No published articles for #{label}. Creating #{count}..."

        members = org ? OrganizationMembership.where(organization_id: org.id).pluck(:user_id) : nil
        members = [owner.id] if members&.empty?

        count.times do |i|
          Article.create!(
            body_markdown: <<~MARKDOWN,
              ---
              title: #{org ? "#{org.name} Update" : "Analytics Article"} #{i + 1}
              published: true
              tags: analytics, seed
              ---

              Sample article created by `rails db:seed:analytics` for local testing.
              #{SecureRandom.hex(16)}
            MARKDOWN
            user_id: members ? members.sample : owner.id,
            organization_id: org&.id,
          )
        end

        org ? org.articles.published.reload : owner.articles.published.reload
      }

      # --- Helper: seed engagement data for a set of articles ---
      seed_engagement = lambda { |target_articles|
        pv_count = 0
        rx_count = 0
        cm_count = 0

        target_articles.each do |article|
          # PageViews
          (0...days_back).each do |days_ago|
            date = days_ago.days.ago
            base = date.on_weekend? ? rand(1..4) : rand(3..10)
            base *= rand(2..4) if rand(10) == 0

            base.times do
              domain = referrer_domains.sample
              PageView.create!(
                article_id: article.id,
                user_id: rand(3) == 0 ? nil : other_users.sample.id,
                counts_for_number_of_views: 1,
                time_tracked_in_seconds: rand(5..120),
                referrer: "https://#{domain}/some/path",
                domain: domain,
                created_at: date - rand(0..86_399).seconds,
              )
              pv_count += 1
            end
          end
          article.update_column(
            :page_views_count, PageView.where(article_id: article.id).sum(:counts_for_number_of_views),
          )

          # Reactions
          other_users.each do |reactor|
            next if rand(10) > 3

            reaction_categories.sample(rand(1..3)).each do |category|
              next if Reaction.exists?(user_id: reactor.id, reactable: article, category: category)

              Reaction.create!(
                user_id: reactor.id, reactable: article, category: category,
                created_at: rand(0...days_back).days.ago - rand(0..86_399).seconds,
              )
              rx_count += 1
            end
          end
          article.sync_reactions_count

          # Comments
          (0...days_back).each do |days_ago|
            next if rand(3) > 0

            comment = Comment.create!(
              user_id: other_users.sample.id,
              commentable: article,
              body_markdown: "#{comment_templates.sample} (#{SecureRandom.hex(4)})",
              created_at: days_ago.days.ago - rand(0..86_399).seconds,
            )
            comment.update_column(:score, rand(1..10))
            cm_count += 1
          end
          article.update_column(:comments_count, article.comments.where("score > 0").count)
        end

        puts "    PageViews: #{pv_count}  Reactions: #{rx_count}  Comments: #{cm_count}"
      }

      # --- Personal analytics ---
      puts
      puts "=== Personal Analytics ==="
      articles = ensure_articles.call(user)
      puts "  User: #{user.username} (ID: #{user.id})"
      puts "  Articles: #{articles.count} | Others: #{other_users.size} | Range: #{days_back}d"
      seed_engagement.call(articles)

      # Follows
      follow_count = 0
      other_users.each do |follower|
        next if Follow.exists?(follower: follower, followable: user)
        next if rand(10) > 6

        Follow.create!(
          follower: follower, followable: user,
          created_at: rand(0...days_back).days.ago - rand(0..86_399).seconds,
        )
        follow_count += 1
      end
      puts "    Follows: #{follow_count}"

      # --- Organization analytics ---
      orgs = if ENV["ORG_ID"]
               [Organization.find(ENV["ORG_ID"])]
             else
               (user.admin_organizations + user.organizations).uniq
             end

      seeded_orgs = []
      if orgs.any?
        orgs.each do |org|
          puts
          puts "=== Org: #{org.name} (ID: #{org.id}) ==="
          org_articles = ensure_articles.call(user, org: org)
          puts "  Articles: #{org_articles.count}"
          seed_engagement.call(org_articles)

          org_follow_count = 0
          other_users.each do |follower|
            next if Follow.exists?(follower: follower, followable: org)
            next if rand(10) > 5

            Follow.create!(
              follower: follower, followable: org,
              created_at: rand(0...days_back).days.ago - rand(0..86_399).seconds,
            )
            org_follow_count += 1
          end
          puts "    Follows: #{org_follow_count}"
          seeded_orgs << org
        end
      else
        puts
        puts "No organizations found for user '#{user.username}'. Skipping org analytics."
        puts "  To seed org data: ORG_ID=<id> rails db:seed:analytics"
      end

      puts
      puts "Done! Dashboard URLs:"
      puts "  /dashboard/analytics"
      seeded_orgs.each { |o| puts "  /dashboard/analytics/org/#{o.id}" }
    end
  end
end
# rubocop:enable Metrics/BlockLength
