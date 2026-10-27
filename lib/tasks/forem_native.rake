# rubocop:disable Metrics/BlockLength
namespace :forem_native do
  desc "Compile the forem_native Rust extension into gems/forem_native/lib/forem_native"
  task compile: :environment do
    require "forem_native"
    abort("Failed to compile forem_native (is `cargo` installed?)") unless ForemNative::Builder.compile!
    ForemNative.load_native!
    puts "Compiled #{ForemNative::Builder.extension_binary_path} (available?: #{ForemNative.available?})"
  end

  desc "Run Rust unit tests and Clippy lints for forem_native"
  task rust_test: :environment do
    require "forem_native"
    Dir.chdir(ForemNative::Builder::GEM_ROOT) do
      sh "cargo test --workspace"
      sh "cargo clippy --workspace --all-targets -- -D warnings"
    end
  end

  desc "Clean compiled Rust artifacts and staged shared libraries"
  task clean: :environment do
    require "forem_native"
    FileUtils.rm_f(ForemNative::Builder.extension_binary_path)
    Dir.chdir(ForemNative::Builder::GEM_ROOT) do
      sh "cargo clean" if ForemNative::Builder.cargo_available?
    end
  end

  desc "Run throughput (benchmark-ips) and allocation (memory_profiler) benchmarks for forem_native"
  task benchmark: :environment do
    require "benchmark/ips"
    require "memory_profiler"

    unless ForemNative.available?
      puts "Compiling forem_native first..."
      Rake::Task["forem_native:compile"].invoke
    end

    sample_markdown = <<~MD * 60
      ---
      title: Rewriting Rails Hot Paths in Rust with Magnus
      published: true
      tags: ruby, rust, performance, rails
      ---

      ## Why In-Process Native Extensions Matter

      In a high-traffic Rails application like Forem, allocation-heavy string transformations
      create thousands of transient Ruby String and Array objects on every article render.
      By moving pure compute into `forem_core` and exposing it via `magnus`, we eliminate
      heap allocations and speed up execution by an order of magnitude! 🚀
    MD

    legacy_ruby_calculate = lambda do |content|
      (content.to_s.split(/\W+/).count / 275.0).ceil
    end

    ruby_mem = MemoryProfiler.report { 10.times { legacy_ruby_calculate.call(sample_markdown) } }
    rust_mem = MemoryProfiler.report { 10.times { ForemNative.calculate_reading_time(sample_markdown) } }

    puts "Sample size: #{sample_markdown.bytesize} bytes (#{ForemNative.split_word_count(sample_markdown)} tokens)"
    puts "Ruby Legacy allocations (10 runs): " \
         "#{ruby_mem.total_allocated} objects (#{ruby_mem.total_allocated_memsize} bytes)"
    puts "Rust Magnus allocations (10 runs): " \
         "#{rust_mem.total_allocated} objects (#{rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby (legacy split + count)") do
        legacy_ruby_calculate.call(sample_markdown)
      end
      x.report("Rust (magnus + forem_core)") do
        ForemNative.calculate_reading_time(sample_markdown)
      end
      x.compare!
    end

    puts "\n=== /stories/feed Custom Feed Pipeline Benchmark (FeedConfig + Articles::Feeds::Custom) ==="
    now = Time.current
    recent_views = Array.new(60) do |i|
      [10_000 + i, (now - (i * 3).hours).utc.iso8601, 45]
    end
    embedding = Array.new(768) { |i| (((i % 20) * 0.05) - 0.5).round(4) }
    tags = Array.new(25) { |i| "tag_#{i}" }
    labels = %w[featured_candidate staff_pick evergreen]
    alltime_users = (1..200).to_a
    recent_users = (201..250).to_a
    alltime_orgs = (1..40).to_a
    recent_orgs = (41..50).to_a
    candidate_articles = (1..35).to_a

    activity_mock = UserActivity.new(
      recently_viewed_articles: recent_views,
      alltime_users: alltime_users,
      recent_users: recent_users,
      alltime_organizations: alltime_orgs,
      recent_organizations: recent_orgs,
      alltime_subforems: [1, 2, 3],
      recent_subforems: [1, 2],
      recent_tags: tags.first(10),
      alltime_tags: tags.last(15),
      recent_labels: labels,
      interest_embedding: embedding,
    )

    setting_mock = Struct.new(:minimize_ai_feed_ai?, :hide_fully_autonomous_feed_ai?).new(true, false)
    user_mock = Struct.new(
      :id,
      :user_activity,
      :cached_following_users_ids,
      :cached_following_organizations_ids,
      :cached_followed_tag_names,
      :cached_languages,
      :setting,
    ).new(1, activity_mock, alltime_users, alltime_orgs, tags, %w[en es], setting_mock)

    feed_config = FeedConfig.new(
      feed_success_weight: 2.5,
      comment_score_weight: 1.5,
      score_weight: 3.0,
      organization_follow_weight: 4.0,
      user_follow_weight: 5.0,
      follow_status_weight: 2.0,
      tag_follow_weight: 6.0,
      subforem_follow_weight: 1.5,
      label_match_weight: 3.5,
      recency_weight: 7.0,
      comment_recency_weight: 4.5,
      lookback_window_weight: 5.5,
      precomputed_selections_weight: 0.0,
      recent_article_suppression_rate: 8.0,
      published_today_weight: 3.0,
      general_past_day_bonus_weight: 2.0,
      recently_active_past_day_bonus_weight: 1.25,
      recent_subforem_weight: 0.75,
      semantic_similarity_weight: 10.0,
      ai_disclosure_matching_weight: 12.0,
      autonomous_ai_penalty_weight: 20.0,
      featured_weight: 4.0,
      favorited_weight: 4.5,
      status_weight: 1.0,
      clickbait_score_weight: 5.0,
      compellingness_score_weight: 6.0,
      language_match_weight: 7.0,
      randomness_weight: 8.0,
      recent_page_views_shuffle_weight: 1.25,
      shuffle_weight: 1.5,
      recent_tag_count_min: 3,
      recent_tag_count_max: 5,
      all_time_tag_count_min: 3,
      all_time_tag_count_max: 5,
    )

    custom_feed = Articles::Feeds::Custom.new(
      user: user_mock,
      number_of_articles: 35,
      page: 1,
      feed_config: feed_config,
    )
    sample_article = Article.new(video_duration_in_seconds: 325)

    legacy_pipeline = lambda do
      FeedConfig.__send__(:legacy_active_user_days, recent_views, 7.days.ago)
      feed_config.__send__(:legacy_score_sql, user_mock)
      custom_feed.__send__(:legacy_calculate_dynamic_shuffle_count, recent_views.first[1], 1.25)
      custom_feed.__send__(:legacy_weighted_shuffle, candidate_articles, 1.5)
      35.times { sample_article.__send__(:legacy_video_duration_in_minutes) }
    end

    native_pipeline = lambda do
      FeedConfig.active_user?(user_mock)
      feed_config.score_sql(user_mock)
      custom_feed.__send__(:calculate_dynamic_shuffle_count)
      custom_feed.__send__(:weighted_shuffle, candidate_articles, 1.5)
      35.times { sample_article.video_duration_in_minutes }
    end

    legacy_pipeline.call
    native_pipeline.call

    feed_ruby_mem = MemoryProfiler.report { 10.times { legacy_pipeline.call } }
    feed_rust_mem = MemoryProfiler.report { 10.times { native_pipeline.call } }

    puts "Feed Pipeline Ruby Legacy allocations (10 runs): " \
         "#{feed_ruby_mem.total_allocated} objects (#{feed_ruby_mem.total_allocated_memsize} bytes)"
    puts "Feed Pipeline Rust Magnus allocations (10 runs): " \
         "#{feed_rust_mem.total_allocated} objects (#{feed_rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (/stories/feed pipeline)") do
        legacy_pipeline.call
      end
      x.report("Rust Magnus (/stories/feed pipeline)") do
        native_pipeline.call
      end
      x.compare!
    end

    puts "\n=== Markdown & Codeblock Processing Pipeline Benchmark (FixAll + Finalize Preprocess + Codeblocks) ==="
    pipeline_markdown = <<~MD * 15
      ---
      title: Deep Dive into Native Rust Pipelines
      description: How fused single-pass kernels eliminate intermediate Ruby allocations
      Published: true
      tags: #ruby #rust #performance #webdev
      ---

      Hello @_dev_team_! Here is a table with escaped pipes:
      | Feature | Status |
      |---|---|
      | Fused FixAll\\|Finalize | Fast\\|Safe |

                      - Deeply nested [Forem Repo](https://github.com/forem/forem)

      ```
      def compute(items)
        items.map(&:to_s)
      end
      ```

      ```ruby
      {% raw %}
      puts "Already labeled codeblock"
      {% endraw %}
      ```

      ```
      const total = items.reduce((a, b) => a + b, 0);
      ```
    MD

    detected_langs = Array.new(30) { |i| i.even? ? "ruby" : "javascript" }
    parser_instance = MarkdownProcessor::Parser.new(pipeline_markdown)
    article_struct = Struct.new(:body_markdown).new(pipeline_markdown)
    detector_instance = Articles::DetectCodeBlockLanguages.new(article_struct)

    fixer_class = MarkdownProcessor::Fixer::FixAll
    legacy_md_pipeline = lambda do
      fixed = fixer_class.__send__(:legacy_add_quotes_to_section, pipeline_markdown, section: "title")
      fixed = fixer_class.__send__(:legacy_add_quotes_to_section, fixed, section: "description")
      fixed = fixer_class.__send__(:legacy_lowercase_published, fixed)
      fixed = fixer_class.__send__(:legacy_convert_new_lines, fixed)
      fixed = fixer_class.__send__(:legacy_split_tags, fixed)
      fixed = fixer_class.__send__(:legacy_underscores_in_usernames, fixed)

      parser_instance.__send__(:legacy_xss_attempt?, fixed)
      preprocessed = parser_instance.__send__(:legacy_convert_deeply_nested_links_to_html, fixed)
      preprocessed = parser_instance.__send__(:legacy_convert_escaped_pipes_outside_codeblocks, preprocessed)
      preprocessed = parser_instance.__send__(:legacy_convert_code_tags_to_triple_backticks, preprocessed)
      parser_instance.__send__(:legacy_escape_liquid_tags_in_codeblock, preprocessed)

      Articles::DetectCodeBlockLanguages.__send__(:legacy_contains_unlabeled_code_blocks?, fixed)
      detector_instance.__send__(:legacy_extract_unlabeled_blocks)
      detector_instance.__send__(:legacy_apply_languages, detected_langs)
    end

    native_md_pipeline = lambda do
      fixed = MarkdownProcessor::Fixer::FixAll.call(pipeline_markdown)
      parser_instance.preprocess_for_finalize(fixed)
      Articles::DetectCodeBlockLanguages.contains_unlabeled_code_blocks?(fixed)
      ForemNative.extract_unlabeled_code_blocks(fixed)
      ForemNative.apply_code_block_languages(fixed, detected_langs)
    end

    legacy_md_pipeline.call
    native_md_pipeline.call

    md_ruby_mem = MemoryProfiler.report { 10.times { legacy_md_pipeline.call } }
    md_rust_mem = MemoryProfiler.report { 10.times { native_md_pipeline.call } }

    puts "Markdown Pipeline Ruby Legacy allocations (10 runs): " \
         "#{md_ruby_mem.total_allocated} objects (#{md_ruby_mem.total_allocated_memsize} bytes)"
    puts "Markdown Pipeline Rust Magnus allocations (10 runs): " \
         "#{md_rust_mem.total_allocated} objects (#{md_rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (Markdown & Codeblock pipeline)") do
        legacy_md_pipeline.call
      end
      x.report("Rust Magnus (Markdown & Codeblock pipeline)") do
        native_md_pipeline.call
      end
      x.compare!
    end
  end
end
# rubocop:enable Metrics/BlockLength
