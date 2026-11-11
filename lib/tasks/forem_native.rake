# rubocop:disable Metrics/BlockLength
namespace :forem_native do
  desc "Benchmark only transcript HTML highlighting/marker substitutions (throughput and allocations)"
  task benchmark_transcript: :environment do
    unless ForemNative::Native.respond_to?(:postprocess_transcript_html)
      raise "Missing native transcript symbol; rebuild with `bundle exec rake forem_native:compile` before benchmarking"
    end

    require "benchmark/ips"
    require "memory_profiler"

    # The original three substitutions, retained as the benchmark oracle.
    legacy = lambda do |html|
      html = html.gsub(%r{<pre><code class="(\w+)">(.*?)</code></pre>}m) do
        lang = Regexp.last_match(1)
        code = CGI.unescapeHTML(Regexp.last_match(2))
        begin
          highlighted = ForemNative.syntax_highlight_html(code, lang)
          raise StandardError, "syntax highlight unavailable" if highlighted.nil?

          %(<pre class="highlight #{lang}"><code>#{highlighted}</code></pre>)
        rescue StandardError
          %(<pre class="highlight"><code>#{CGI.escapeHTML(code)}</code></pre>)
        end
      end
      html = html.gsub(%r{<pre><code>(.*?)</code></pre>}m) do
        %(<pre class="highlight"><code>#{Regexp.last_match(1)}</code></pre>)
      end
      html.gsub("[REDACTED]", '<span class="agent-session-redacted">[REDACTED]</span>')
    end
    native = ->(html) { AgentSessionRenderers::MarkdownRenderer.highlight_code_blocks(html, redact: true) }
    code_output = "command output\n" * 10
    workloads = {
      "dense (60 untagged blocks, 120 markers)" =>
        "<p>Transcript 日本語 🚀 [REDACTED]</p>\n" \
        "<pre><code>value &amp; data\r\n[REDACTED]\n#{code_output}</code></pre>\n" * 60,
      "prose (0 blocks, 0 markers)" =>
        "ordinary transcript prose " * (14_976 / 26)
    }

    workloads.each do |label, sample|
      raise "Transcript benchmark parity failure (#{label})" unless native.call(sample) == legacy.call(sample)

      puts "Transcript HTML helper [#{label}]: #{sample.bytesize} bytes"
      Benchmark.ips do |x|
        x.config(warmup: 0.5, time: 1.5)
        x.report("Legacy") { legacy.call(sample) }
        x.report("ForemNative") { native.call(sample) }
        x.compare!
      end
      { "Legacy" => legacy, "ForemNative" => native }.each do |name, implementation|
        report = MemoryProfiler.report { 10.times { implementation.call(sample) } }
        puts "#{name} (10 calls): #{report.total_allocated} objects; #{report.total_allocated_memsize} bytes"
      end
    end
  end

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
  task benchmark: %i[
    environment benchmark_extractors benchmark_comment_tree benchmark_story_cards benchmark_image_ops
  ] do
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

    puts "\n=== Feed Scoring, UserActivity & Analytics Heatmap Pipeline Benchmark ==="
    tag_struct = Struct.new(:name, :points)
    followed_tags = %w[ruby rust javascript webdev ai career devops postgres].each_with_index.map do |name, idx|
      tag_struct.new(name, (idx + 1) * 1.5)
    end
    user_bench = Struct.new(
      :id, :cached_following_users_ids, :cached_following_organizations_ids, :decorate, :setting
    ).new(
      42, (1..25).to_a, (1..10).to_a,
      Struct.new(:cached_followed_tags).new(followed_tags),
      Struct.new(:experience_level, :feed_ai_preference).new(5, "minimize_ai")
    )
    bench_article_class = Struct.new(
      :id, :user_id, :organization_id, :cached_tag_list, :cached_label_list,
      :experience_level_rating, :comments_count, :ai_disclosure_level, :subforem_id
    ) do
      def organization_id? = !organization_id.nil? && organization_id != 0
      def decorate = Struct.new(:cached_tag_list_array).new((cached_tag_list || "").split(", "))
    end
    bench_articles = Array.new(35) do |idx|
      bench_article_class.new(
        idx + 1, (idx % 30) + 1, idx.even? ? (idx % 12) + 1 : nil,
        "ruby, rust, webdev, tag#{idx % 5}", ["label_#{idx % 6}", "featured"],
        (idx % 9) + 1, idx * 2, %w[none some_ai fully_autonomous][idx % 3], (idx % 5) + 1
      )
    end
    score_calc = Articles::Feeds::ArticleScoreCalculatorForUser.new(user: user_bench)
    exp_feed_bench = Articles::Feeds::LargeForemExperimental.new(user: user_bench)
    exp_feed_bench.instance_variable_set(:@article_score_applicator, score_calc)
    end_date_bench = Date.new(2026, 10, 27)
    start_date_bench = end_date_bench - 364
    heatmap_svc = UserActivityHeatmapService.new(user_bench, end_date: end_date_bench, days: 365)
    art_by_day = (0...60).to_h { |i| [(start_date_bench + (i * 6)).iso8601, (i % 4) + 1] }
    com_by_day = (0...120).to_h { |i| [(start_date_bench + (i * 3)).iso8601, (i % 7) + 1] }
    react_by_day = (0...180).to_h { |i| [(start_date_bench + (i * 2)).iso8601, (i % 10) + 1] }
    recent_views_store = Array.new(100) { |i| [i + 1, "2026-10-27T12:00:00Z", (i % 60) + 5] }
    recent_sub_ids = Array.new(30) { |i| (i % 8) + 1 }
    followed_sub_ids = [2, 5, 7, 9]
    discoverable_sub_ids = (1..15).to_a

    legacy_scoring_heatmap_pipeline = lambda do
      bench_articles.each do |a|
        score_calc.score_followed_user(a) + score_calc.score_followed_organization(a) +
          score_calc.__send__(:legacy_score_followed_tags, a) +
          score_calc.__send__(:legacy_score_experience_level, a, 5) +
          score_calc.score_comments(a) + score_calc.__send__(:legacy_score_ai_disclosure, a)
      end
      recent_views_store.filter_map { |id, _ts, secs| id if secs > 29 }
      heatmap_svc.__send__(:legacy_build_payload, art_by_day, com_by_day, react_by_day)
      scores = Hash.new(0)
      recent_sub_ids.each { |id| scores[id] += 1 }
      followed_sub_ids.each { |id| scores[id] += 10 }
      act_ids = scores.keys.sort { |a, b| scores[b] <=> scores[a] }
      act_ids + (discoverable_sub_ids - act_ids)
    end
    native_scoring_heatmap_pipeline = lambda do
      bench_articles.each { |a| exp_feed_bench.score_single_article(a) }
      ForemNative.filter_tracked_article_ids(recent_views_store, 29)
      ForemNative.build_activity_heatmap_payload(
        start_date_bench.iso8601, end_date_bench.iso8601, art_by_day, com_by_day, react_by_day
      )
      ForemNative.order_subforem_ids(recent_sub_ids, followed_sub_ids, discoverable_sub_ids)
    end
    sh_ruby_mem = MemoryProfiler.report { 10.times { legacy_scoring_heatmap_pipeline.call } }
    sh_rust_mem = MemoryProfiler.report { 10.times { native_scoring_heatmap_pipeline.call } }
    puts "Scoring + Heatmap Pipeline Ruby Legacy allocations (10 runs): " \
         "#{sh_ruby_mem.total_allocated} objects (#{sh_ruby_mem.total_allocated_memsize} bytes)"
    puts "Scoring + Heatmap Pipeline Rust Magnus allocations (10 runs): " \
         "#{sh_rust_mem.total_allocated} objects (#{sh_rust_mem.total_allocated_memsize} bytes)"
    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (Feed Scoring + Heatmap pipeline)") { legacy_scoring_heatmap_pipeline.call }
      x.report("Rust Magnus (Feed Scoring + Heatmap pipeline)") { native_scoring_heatmap_pipeline.call }
      x.compare!
    end

    puts "\n=== RSS Feed Import Pipeline Benchmark ==="
    rss_items = Array.new(60) do |idx|
      "<item><title>Post #{idx}</title><link>https://blog.example.com/posts/#{idx}</link>" \
        "<description><![CDATA[<p>Paragraph #{idx}</p>]]></description></item>"
    end.join("\n")
    sample_rss_xml = "<?xml version=\"1.0\"?><rss version=\"2.0\"><channel>#{rss_items}</channel></rss>"
    sample_feed_html = "<p>Intro</p>\n\n<div><h2>Section</h2><p>Body text</p></div>" * 8
    sample_feed_md = "Intro\n```\n\n```\nHello&nbsp;world\u00A0![img](/a/b.png) " \
                     "<img src=\"rel.jpg\"> {% youtube dQw4w9WgXcQ\\_1 %}\n" * 6
    sample_feed_tags = ["Ruby on Rails", "web-dev", "sidekiq-perf", "rust", "extra"]
    sample_feed_author = "Jane Developer <jane+rss@example.com>"
    sample_feed_err = "Failed at /Users/dev/forem/app/services/feeds/import.rb:120:in `call'"

    legacy_rss_pipeline = lambda do
      sample_rss_xml.scan(%r{</item>}i)
      block_count = sample_feed_html.scan(/<\s*(p|div|h[1-6]|ul|ol|li|blockquote|pre|table|section|figure)[\s>]/i).size
      _is_html = block_count > sample_feed_html.scan(/\n\s*\n/).size
      cleaned = sample_feed_md
        .gsub("```\n\n```", "")
        .gsub(/&nbsp;|\u00A0/, " ")
        .gsub(/\{%\syoutube\s(.{11,18})\s%\}/) { |match| match.gsub("\\_", "_") }
      cleaned
        .gsub(%r{(<img\s[^>]*?src=["'])(?!https?://)([^"']+)(["'])}, '\1https://blog.example.com/\2\3')
        .gsub(%r{(!\[[^\]]*\]\()(?!https?://)([^)]+)(\))}, '\1https://blog.example.com\2\3')
      sample_feed_tags.first(4).map { |t| t.gsub(/[^[:alnum:]]/, "").slice(0, 20) }.join(",")
      sample_feed_author[/[\w.+-]+@[\w.-]+\.\w+/]
      sample_feed_author.sub(/<[^>]+>/, "").strip
      sample_feed_err.gsub(%r{/[\w/.-]+\.rb:\d+}, "[path]").truncate(500)
    end

    native_rss_pipeline = lambda do
      ForemNative.truncate_feed_xml_items(sample_rss_xml, 25)
      ForemNative.feed_html_content(sample_feed_html)
      cleaned = ForemNative.postprocess_feed_markdown(sample_feed_md)
      ForemNative.resolve_feed_markdown_images(
        cleaned, "https://blog.example.com", "https://blog.example.com/posts/1"
      )
      ForemNative.format_feed_tags(sample_feed_tags)
      ForemNative.extract_feed_author(sample_feed_author)
      ForemNative.sanitize_feed_error(sample_feed_err)
    end

    rss_ruby_mem = MemoryProfiler.report { 10.times { legacy_rss_pipeline.call } }
    rss_rust_mem = MemoryProfiler.report { 10.times { native_rss_pipeline.call } }
    puts "RSS Feed Import Ruby Legacy allocations (10 runs): " \
         "#{rss_ruby_mem.total_allocated} objects (#{rss_ruby_mem.total_allocated_memsize} bytes)"
    puts "RSS Feed Import Rust Magnus allocations (10 runs): " \
         "#{rss_rust_mem.total_allocated} objects (#{rss_rust_mem.total_allocated_memsize} bytes)"
    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (RSS Feed Import pipeline)") { legacy_rss_pipeline.call }
      x.report("Rust Magnus (RSS Feed Import pipeline)") { native_rss_pipeline.call }
      x.compare!
    end

    puts "\n=== ApplicationMetalController & BillboardEvent Pipeline Benchmark ==="
    metal_real_raw = SecureRandom.random_bytes(32)
    metal_encoded_real = Base64.urlsafe_encode64(metal_real_raw, padding: false)
    metal_global_token = OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA256"), metal_real_raw, "!real_csrf_token")
    metal_otp = SecureRandom.random_bytes(32)
    metal_xored = metal_global_token.bytes.each_with_index.map { |b, i| (b ^ metal_otp.getbyte(i)).chr }.join
    metal_masked_token = Base64.urlsafe_encode64(metal_otp + metal_xored, padding: false)
    metal_secret = Rails.application.secret_key_base
    metal_now = Time.current.utc
    metal_jwt = JWT.encode({ "user_id" => 42, "exp" => metal_now.to_i + 3600 }, metal_secret, "HS256")
    metal_billboard = Billboard.new(id: 555)
    metal_insert_attrs = {
      billboard: metal_billboard,
      category: "impression",
      context_type: "home",
      user_id: 42,
      article_id: 1001,
      geolocation: "US-NY",
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
    }
    metal_raw_origins = "https://embed.example.com, https://partner.example.org"
    metal_uuid = "550e8400-e29b-41d4-a716-446655440000"

    metal_controller = Class.new(ApplicationMetalController) do
      attr_accessor :encoded_real_token

      def request
        @request ||= Struct.new(:env, :path, :request_method).new(
          { ActionController::RequestForgeryProtection::CSRF_TOKEN => encoded_real_token },
          "/bb_tabulations",
          "POST",
        )
      end
    end.new
    metal_controller.encoded_real_token = metal_encoded_real

    legacy_metal_pipeline = lambda do
      ActionController::RequestForgeryProtection.instance_method(:valid_authenticity_token?)
        .bind_call(metal_controller, {}, metal_masked_token)
      metal_controller.__send__(:legacy_decode_auth_token, metal_jwt)
      BillboardEvent.__send__(
        :legacy_add_impression_seconds_sql,
        id: "12345", user_id: 42, now: metal_now, seconds: 10, throttle: 9.seconds,
      )
      BillboardEvent.__send__(:legacy_create_with_async_commit_sql, metal_insert_attrs, now: metal_now)
      metal_raw_origins.split(",").map(&:strip).reject(&:empty?).include?("https://partner.example.org")
      Feeds::RecordConfigVisit::UUID_PATTERN.match?(metal_uuid)
      Digest::SHA256.digest("feed_events:42").unpack1("q>")
    end

    native_metal_pipeline = lambda do
      ForemNative.verify_authenticity_token(metal_masked_token, metal_encoded_real)
      ForemNative.verify_hs256_jwt(metal_jwt, metal_secret, metal_now.to_i)
      BillboardEvent.build_add_impression_seconds_sql(
        id: "12345", user_id: 42, now: metal_now, seconds: 10, throttle: 9.seconds,
      )
      BillboardEvent.build_create_with_async_commit_sql(metal_insert_attrs, now: metal_now)
      ForemNative.origin_in_comma_list("https://partner.example.org", metal_raw_origins)
      ForemNative.valid_uuid(metal_uuid)
      ForemNative.feed_events_advisory_lock_key(42)
    end

    metal_ruby_mem = MemoryProfiler.report { 10.times { legacy_metal_pipeline.call } }
    metal_rust_mem = MemoryProfiler.report { 10.times { native_metal_pipeline.call } }
    puts "Metal Pipeline Ruby Legacy allocations (10 runs): " \
         "#{metal_ruby_mem.total_allocated} objects (#{metal_ruby_mem.total_allocated_memsize} bytes)"
    puts "Metal Pipeline Rust Magnus allocations (10 runs): " \
         "#{metal_rust_mem.total_allocated} objects (#{metal_rust_mem.total_allocated_memsize} bytes)"
    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (ApplicationMetalController pipeline)") { legacy_metal_pipeline.call }
      x.report("Rust Magnus (ApplicationMetalController pipeline)") { native_metal_pipeline.call }
      x.compare!
    end

    puts "\n=== Phase 2 MetalTelemetryFastPath & Origin/Referrer Pipeline Benchmark ==="
    metal_json_body =
      '{"billboard_event":{"billboard_id":555,"category":"impression","context_type":"home","article_id":1001}}'
    metal_referrer = "https://www.google.com/search?q=ruby+rust+magnus"
    pv_sample = PageView.new(referrer: metal_referrer)
    origin_harness = Class.new do
      include ValidRequest

      def request
        @request ||= Struct.new(:referer, :origin, :base_url, :host, :port).new(
          "https://dev.to/ben/post",
          "https://dev.to",
          "https://dev.to",
          "dev.to",
          443,
        )
      end
    end.new

    legacy_phase2_pipeline = lambda do
      origin_harness.__send__(:legacy_valid_request_origin?)
      pv_sample.__send__(:legacy_extract_domain_and_path)
      parsed_json = JSON.parse(metal_json_body)["billboard_event"]
      BillboardEvent.__send__(
        :legacy_create_with_async_commit_sql,
        {
          billboard: metal_billboard,
          category: parsed_json["category"],
          context_type: parsed_json["context_type"],
          user_id: 42,
          article_id: parsed_json["article_id"],
          geolocation: "US-NY",
          user_agent: "Mozilla/5.0"
        },
        now: metal_now,
      )
    end

    native_phase2_pipeline = lambda do
      ForemNative.match_metal_telemetry_route("POST", "/bb_tabulations")
      origin_harness.__send__(:evaluate_request_origin)
      pv_sample.__send__(:extract_domain_and_path)
      ForemNative.billboard_event_create_from_json_sql(
        metal_json_body, 42, "US-NY", "Mozilla/5.0", false, metal_now
      )
    end

    phase2_ruby_mem = MemoryProfiler.report { 10.times { legacy_phase2_pipeline.call } }
    phase2_rust_mem = MemoryProfiler.report { 10.times { native_phase2_pipeline.call } }
    puts "Phase 2 Metal FastPath Ruby Legacy allocations (10 runs): " \
         "#{phase2_ruby_mem.total_allocated} objects (#{phase2_ruby_mem.total_allocated_memsize} bytes)"
    puts "Phase 2 Metal FastPath Rust Magnus allocations (10 runs): " \
         "#{phase2_rust_mem.total_allocated} objects (#{phase2_rust_mem.total_allocated_memsize} bytes)"
    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (Phase 2 Metal Origin + Referrer + JSON SQL)") { legacy_phase2_pipeline.call }
      x.report("Rust Magnus (Phase 2 Metal Origin + Referrer + JSON SQL)") { native_phase2_pipeline.call }
      x.compare!
    end

    puts "\n=== Tier 1 Metal FastPath: GA4 Fallback JSON + FeedEvents Batch Validation Benchmark ==="
    ga_json_body = JSON.generate(
      {
        "path" => "/ben/rewriting-rails-hot-paths-in-rust-42",
        "user_language" => "en-US",
        "referrer" => "https://www.google.com/search?q=forem+rust+magnus",
        "user_agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "viewport_size" => "900x1440",
        "screen_resolution" => "1080x1920",
        "document_title" => "Rewriting Rails Hot Paths in Rust - DEV Community",
        "document_encoding" => "UTF-8",
        "document_path" => "/ben/rewriting-rails-hot-paths-in-rust-42"
      },
    )
    feed_batch = Array.new(20) do |idx|
      {
        "article_id" => 10_000 + idx,
        "article_position" => idx + 1,
        "category" => idx.even? ? "impression" : "click",
        "context_type" => "home",
        "user_id" => 42,
        "feed_config_id" => 7,
        "event_id" => format("550e8400-e29b-41d4-a716-44665544%04x", idx)
      }
    end
    bulk_upsert_bench = FeedEvents::BulkUpsert.new(feed_batch)

    legacy_tier1_pipeline = lambda do
      parsed = JSON.parse(ga_json_body)
      ref = parsed["referrer"]
      {
        "page_title" => parsed["document_title"],
        "page_location" => parsed["document_path"],
        "page_path" => parsed["path"],
        "user_id" => 42,
        "user_language" => parsed["user_language"],
        "referrer" => ref && !ref.start_with?("https://dev.to") ? ref : nil,
        "user_agent" => parsed["user_agent"],
        "viewport_size" => parsed["viewport_size"],
        "screen_resolution" => parsed["screen_resolution"],
        "document_encoding" => parsed["document_encoding"],
        "data_source" => "web"
      }
      bulk_upsert_bench.__send__(:legacy_valid_events, feed_batch).map do |event|
        {
          article_position: event[:article_position],
          category: event[:category],
          context_type: event[:context_type],
          article_id: event[:article_id],
          user_id: event[:user_id],
          feed_config_id: event[:feed_config_id],
          counts_for: event[:counts_for],
          event_id: event[:event_id]
        }
      end
    end

    native_tier1_pipeline = lambda do
      ForemNative.match_metal_telemetry_route("POST", "/fallback_activity_recorder")
      ForemNative.match_metal_telemetry_route("POST", "/feed_events")
      ForemNative.match_metal_telemetry_route("POST", "/feed_config_visits")
      ForemNative.extract_ga_event_params(ga_json_body, "https://dev.to", 42)
      ForemNative.validate_and_normalize_feed_events(feed_batch)
    end

    tier1_ruby_mem = MemoryProfiler.report { 10.times { legacy_tier1_pipeline.call } }
    tier1_rust_mem = MemoryProfiler.report { 10.times { native_tier1_pipeline.call } }
    puts "Tier 1 Metal FastPath Ruby Legacy allocations (10 runs): " \
         "#{tier1_ruby_mem.total_allocated} objects (#{tier1_ruby_mem.total_allocated_memsize} bytes)"
    puts "Tier 1 Metal FastPath Rust Magnus allocations (10 runs): " \
         "#{tier1_rust_mem.total_allocated} objects (#{tier1_rust_mem.total_allocated_memsize} bytes)"
    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (GA4 JSON + 20x FeedEvent.new.valid?)") { legacy_tier1_pipeline.call }
      x.report("Rust Magnus (GA4 JSON + 20x FeedEvent batch kernel)") { native_tier1_pipeline.call }
      x.compare!
    end

    puts "\n=== Tier 2 AuthPass + AsyncInfo + BulkFollow Pipeline Benchmark ==="
    jwt_secret = Rails.application.secret_key_base
    jwt_exp = 1_793_727_000
    encoded_real_csrf = Base64.urlsafe_encode64("R" * 32, padding: false)
    csrf_pad = "P" * 32
    sample_origin = "https://Blog.MyOrg.com:8443/auth_pass/iframe?passed_domain=test"
    sample_user_json = {
      id: 42,
      name: "Ben Halpern",
      username: "ben",
      trusted: true,
      admin: true
    }.to_json
    follow_ids = (1..25).to_a
    follow_fwd = Array.new(25, &:even?)
    follow_rev = Array.new(25) { |idx| (idx % 3).zero? }
    auth_pass_ctrl = AuthPassController.new
    follows_ctrl = FollowsController.new

    legacy_tier2_pipeline = lambda do
      t = JWT.encode({ user_id: 42, exp: jwt_exp }, jwt_secret)
      raw_real = Base64.urlsafe_decode64(encoded_real_csrf)
      global_tok = OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA256"), raw_real, "!real_csrf_token")
      xored = csrf_pad.bytes.zip(global_tok.bytes).map { |a, b| (a ^ b).chr }.join
      masked = Base64.urlsafe_encode64(csrf_pad + xored, padding: false)
      orig = auth_pass_ctrl.__send__(:legacy_parse_origin_host_and_csp, sample_origin)
      base_json = {
        broadcast: nil,
        param: :authenticity_token,
        token: masked,
        user: sample_user_json,
        client_geolocation: "US-NY",
        default_email_optin_allowed: true,
        creator: true
      }.to_json
      follow_json = follows_ctrl
        .__send__(:legacy_resolve_bulk_follow, 1, true, follow_ids, follow_fwd, follow_rev)
        .to_json
      [t, orig, base_json, follow_json]
    end

    native_tier2_pipeline = lambda do
      t = ForemNative.encode_hs256_jwt(42, jwt_exp, jwt_secret)
      masked = ForemNative.mask_authenticity_token(encoded_real_csrf, csrf_pad)
      orig = ForemNative.parse_auth_pass_origin(sample_origin)
      base_json = ForemNative.build_base_data_json(
        broadcast: nil,
        param: "authenticity_token",
        token: masked,
        user: sample_user_json,
        client_geolocation: "US-NY",
        default_email_optin_allowed: true,
        creator: true,
      )
      follow_json = ForemNative.resolve_bulk_follow_json(1, true, follow_ids, follow_fwd, follow_rev)
      [t, orig, base_json, follow_json]
    end

    raise "Tier 2 pipeline output mismatch!" unless legacy_tier2_pipeline.call == native_tier2_pipeline.call

    tier2_ruby_mem = MemoryProfiler.report { 100.times { legacy_tier2_pipeline.call } }
    tier2_rust_mem = MemoryProfiler.report { 100.times { native_tier2_pipeline.call } }
    puts "Tier 2 Pipeline Ruby allocations (100 runs): #{tier2_ruby_mem.total_allocated} objects " \
         "(#{tier2_ruby_mem.total_allocated_memsize} bytes)"
    puts "Tier 2 Pipeline Rust allocations (100 runs): #{tier2_rust_mem.total_allocated} objects " \
         "(#{tier2_rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (JWT.encode + CSRF mask + URI.parse + BaseData + 25x BulkFollow)") do
        legacy_tier2_pipeline.call
      end
      x.report("Rust Magnus (JWT.encode + CSRF mask + Origin + BaseData + 25x BulkFollow)") do
        native_tier2_pipeline.call
      end
      x.compare!
    end

    puts "\n=== Tier 3 Billboards (FilteredAdsQuery + Weighted Selection + Geolocation) Benchmark ==="
    sample_ua = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/125.0 Mobile Safari/537.36"
    sample_geos = %w[US CA-ON CA-QC GB DE FR]
    sample_tags = %w[javascript webdev beginners programming tutorial react python ai]
    sample_roles = %w[trusted tag_moderator base_subscriber]
    sample_base_sql = 'SELECT "display_ads".* FROM "display_ads" WHERE "display_ads"."approved" = TRUE'

    legacy_tier3_pipeline = lambda do
      geo_cov = Geolocation.__send__(:legacy_code_covered_by?, "ca-on", sample_geos)
      country = "US-NY".split("-").first
      country = nil unless country&.match?(/\A[A-Z]{2}\z/)
      rel_sql = Billboards::FilteredAdsQuery.new(
        area: "feed_first",
        user_signed_in: true,
        user_id: 42,
        user_tags: sample_tags,
        role_names: sample_roles,
        user_agent: sample_ua,
        cookies_allowed: true,
        subforem_id: 1,
      ).__send__(:legacy_call).to_sql
      weighted_sql = ActiveRecord::Base.sanitize_sql_array(
        [
          "WITH base AS (#{sample_base_sql}), weighted AS (SELECT id FROM base) SELECT * FROM base WHERE 1 >= ?",
          0.42,
        ],
      )
      [geo_cov, country, rel_sql, weighted_sql]
    end

    native_tier3_pipeline = lambda do
      geo_cov = ForemNative.geolocation_code_covered_by?("ca-on", sample_geos)
      country = ForemNative.extract_viewer_country("US-NY")
      rel_sql = Billboards::FilteredAdsQuery.new(
        area: "feed_first",
        user_signed_in: true,
        user_id: 42,
        user_tags: sample_tags,
        role_names: sample_roles,
        user_agent: sample_ua,
        cookies_allowed: true,
        subforem_id: 1,
      ).call.to_sql
      weighted_sql = ForemNative.build_billboard_weighted_random_sql(sample_base_sql, 99, 1000, 0.42)
      [geo_cov, country, rel_sql, weighted_sql]
    end

    tier3_ruby_mem = MemoryProfiler.report { 100.times { legacy_tier3_pipeline.call } }
    tier3_rust_mem = MemoryProfiler.report { 100.times { native_tier3_pipeline.call } }
    puts "Tier 3 Pipeline Ruby allocations (100 runs): #{tier3_ruby_mem.total_allocated} objects " \
         "(#{tier3_ruby_mem.total_allocated_memsize} bytes)"
    puts "Tier 3 Pipeline Rust allocations (100 runs): #{tier3_rust_mem.total_allocated} objects " \
         "(#{tier3_rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (18x Relation#where/#or + Geolocation + UA regex)") { legacy_tier3_pipeline.call }
      x.report("Rust Magnus (Single-pass FilteredAdsQuery + Geolocation + UA)") { native_tier3_pipeline.call }
      x.compare!
    end
  end

  desc "Compare Markdown extractors and tag cleanup with their legacy Ruby calculations"
  task benchmark_extractors: :environment do
    require "benchmark/ips"
    require "memory_profiler"

    markdown = <<~MD * 30
      A paragraph with [a link](https://example.com/page).
      {% user synthetic_user %}
      {% embed https://example.com/post extra %}
      Inline `https://example.com/ignored` and fenced code:
      ```ruby
      {% tag ignored %}
      ```
      ![alt](https://example.com/image.png)
      <img src="https://example.com/photo.jpg">
    MD
    excluded = "https://synthetic-bucket.s3.amazonaws.com"
    tags = "Ruby, Rails, w o r d, Optimización, Καλημέρα, Français"
    cases = {
      extract_liquid_embed_tags: [
        -> { LiquidEmbedExtractor.legacy_extract_tags(markdown) },
        -> { ForemNative.extract_liquid_embed_tags(markdown) },
      ],
      extract_markdown_webpage_urls: [
        -> { WebpageExtractor.__send__(:legacy_extract, markdown) },
        -> { ForemNative.extract_markdown_webpage_urls(markdown) },
      ],
      extract_markdown_and_html_image_urls: [
        -> { Articles::EnrichImageAttributes.__send__(:legacy_extract_image_urls, markdown, excluded) },
        -> { ForemNative.extract_markdown_and_html_image_urls(markdown, excluded) },
      ],
      clean_tag_list: [
        -> { ActsAsTaggableOn::TagParser.new(tags).__send__(:legacy_clean, tags) },
        -> { ForemNative.clean_tag_list(tags) },
      ]
    }

    puts "\n=== Markdown Extractors (#{markdown.bytesize} bytes) and Tag Cleanup ==="
    cases.each do |name, (legacy, native)|
      raise "#{name} differs from Ruby" unless legacy.call == native.call

      [[:Ruby, legacy], [:Rust, native]].each do |label, calculation|
        memory = MemoryProfiler.report { 100.times { calculation.call } }
        puts "#{name} #{label} allocations (100 runs): " \
             "#{memory.total_allocated} objects (#{memory.total_allocated_memsize} bytes)"
      end
      Benchmark.ips do |x|
        x.config(time: 2, warmup: 1)
        x.report("#{name} Ruby", &legacy)
        x.report("#{name} Rust", &native)
        x.compare!
      end
    end
  end

  desc "Benchmark Comment-Tree HTML Renderer (50-comment nested discussion tree)"
  task benchmark_comment_tree: :environment do
    require "benchmark/ips"
    require "memory_profiler"

    URL.define_singleton_method(:protocol) { "https://" }
    URL.define_singleton_method(:domain) { |*| "dev.to" }
    URL.define_singleton_method(:dev_port) { nil }
    InlineSvg::IdGenerator::Randomness.define_singleton_method(:call) { "fixed" }

    controller = ArticlesController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new
    view = controller.view_context
    view.define_singleton_method(:user_signed_in?) { false }

    now = Time.current
    users = Array.new(8) do |i|
      u = User.new(
        id: 100 + i,
        name: "Developer #{i} & Co",
        username: "dev_user_#{i}",
        email: "dev#{i}@example.com",
        created_at: now - (i + 1).years,
      )
      u.setting = Users::Setting.new(
        brand_color1: i.even? ? "#234567" : "",
        display_email_on_profile: i.zero?,
      )
      u.profile = Profile.new(
        summary: "Building high-throughput systems with Ruby & Rust (##{i})",
        location: i.even? ? "New York, NY" : "",
        data: {},
      )
      u.define_singleton_method(:cached_base_subscriber?) { i == 1 }
      u.define_singleton_method(:cached_community_leader?) { i == 2 }
      u.define_singleton_method(:profile_image_url_for) do |length: 50|
        "https://dev.to/uploads/user/#{id}_#{length}.png"
      end
      u
    end

    article = Article.new(
      id: 5000,
      user_id: users.first.id,
      slug: "rust-comment-tree-renderer-5000",
      path: "/dev_user_0/rust-comment-tree-renderer-5000",
      cached_tag_list: "rust, ruby, performance",
    )
    article.user = users.first
    article.association(:organization).loaded!

    build_comment = lambda do |id, user, ancestry, score: 5, reactions: 2, edited: false, ai: :not_disclosed|
      c = Comment.new(
        id: id,
        user_id: user.id,
        commentable_id: article.id,
        commentable_type: "Article",
        ancestry: ancestry,
        id_code: id.to_s(26).tr("0-9a-p", "0-9a-p"),
        processed_html: "<p>This is comment ##{id} discussing <code>ForemNative.render_comment_tree</code> " \
                        "and zero-copy Magnus slices.</p>",
        score: score,
        public_reactions_count: reactions,
        created_at: now - id.minutes,
        edited_at: edited ? (now - 1.minute) : nil,
        ai_disclosure_level: ai,
      )
      c.user = user
      c.association(:commentable).target = article
      c
    end

    tree = {}
    comment_id = 1000
    10.times do |root_idx|
      root = build_comment.call(
        comment_id += 1,
        users[root_idx % users.size],
        nil,
        score: 15,
        reactions: root_idx % 4,
        ai: (root_idx.zero? ? :some_ai : :not_disclosed),
      )
      c1_map = {}
      tree[root] = c1_map

      2.times do |c1_idx|
        c1 = build_comment.call(
          comment_id += 1,
          users[(root_idx + c1_idx + 1) % users.size],
          root.id.to_s,
          edited: c1_idx.odd?,
        )
        c2_map = {}
        c1_map[c1] = c2_map

        c2 = build_comment.call(
          comment_id += 1,
          users[(root_idx + c1_idx + 2) % users.size],
          "#{root.id}/#{c1.id}",
        )
        c2_map[c2] = {}
      end
    end

    view.instance_variable_set(:@article, article)
    view.instance_variable_set(:@discussion_lock, false)
    view.instance_variable_set(:@root_comment, nil)
    view.instance_variable_set(:@comments_to_show_count, 50)

    legacy_run = lambda do
      view.instance_variable_set(:@current_comment_index, 0)
      view.instance_variable_set(:@shown_billboard, false)
      view.__send__(:legacy_nested_comments, tree: tree, commentable: article, is_view_root: true, is_admin: false)
    end

    native_run = lambda do
      view.instance_variable_set(:@current_comment_index, 0)
      view.instance_variable_set(:@shown_billboard, false)
      view.__send__(:native_nested_comments, tree: tree, commentable: article, is_view_root: true, is_admin: false)
    end

    # Warm up static icon/translation context and verify parity before profiling
    legacy_sample = legacy_run.call
    native_sample = native_run.call
    raise "Comment tree benchmark parity failure (native returned nil)" if native_sample.nil?
    raise "Comment tree benchmark parity failure (HTML mismatch)" unless native_sample == legacy_sample

    puts "\n=== Comment-Tree HTML Renderer (50 nested comments across 10 threads, #{native_sample.bytesize} bytes) ==="

    ruby_mem = MemoryProfiler.report { legacy_run.call }
    rust_mem = MemoryProfiler.report { native_run.call }
    puts "nested_comments (50 comments) Ruby Legacy allocations (1 render): " \
         "#{ruby_mem.total_allocated} objects (#{ruby_mem.total_allocated_memsize} bytes)"
    puts "nested_comments (50 comments) Rust Magnus allocations (1 render): " \
         "#{rust_mem.total_allocated} objects (#{rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (50-comment ERB partial tree)") { legacy_run.call }
      x.report("Rust Magnus (ForemNative.render_comment_tree)") { native_run.call }
      x.compare!
    end
  end

  desc "Benchmark Story-Card & Tag-Pill HTML rendering engine (60-story feed + tag links)"
  task benchmark_story_cards: :environment do
    unless ForemNative::Native.respond_to?(:render_story_cards) && ForemNative::Native.respond_to?(:render_tag_link)
      raise "Missing native story_card symbols; rebuild with " \
            "`bundle exec rake forem_native:compile` before benchmarking"
    end

    require "benchmark/ips"
    require "memory_profiler"

    InlineSvg::IdGenerator::Randomness.define_singleton_method(:call) { "benchfixed" }
    Settings::General.define_singleton_method(:app_domain) { "dev.local" } if Settings::General.app_domain.blank?

    controller = StoriesController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new
    view = controller.view_context
    view.define_singleton_method(:user_signed_in?) { true }
    view.define_singleton_method(:feed_style_preference) { "basic" }

    tag_defs = [
      ["javascript", "#f7df1e", "#000000"],
      ["webdev", "#562765", "#ffffff"],
      ["beginners", "#008335", "#ffffff"],
      ["programming", "#890606", "#ffffff"],
      ["tutorial", "#FEFFA5", "#b30047"],
      ["ai", "#F59E0B", "#000000"],
      ["rust", "#dea584", "#000000"],
      ["ruby", "#cc342d", "#ffffff"],
      ["discuss", "#1ad643", "#ffffff"],
      ["devops", "#06b900", "#ffffff"],
    ]
    preloaded_colors = view.__send__(:preloaded_tag_colors)
    tag_defs.each do |t_name, bg_hex, text_hex|
      preloaded_colors[t_name] = { background: bg_hex, color: text_hex }
    end
    tag_names_only = tag_defs.map(&:first)

    legacy_tag_batch = lambda do
      tag_names_only.each do |t_name|
        view.__send__(:legacy_render_tag_link, t_name, filled: false, monochrome: true)
      end
    end
    native_tag_batch = lambda do
      tag_names_only.each do |t_name|
        view.__send__(:native_render_tag_link, t_name, filled: false, monochrome: true)
      end
    end

    tag_names_only.each do |t_name|
      l_pill = view.__send__(:legacy_render_tag_link, t_name, filled: false, monochrome: true)
      n_pill = view.__send__(:native_render_tag_link, t_name, filled: false, monochrome: true)
      raise "render_tag_link benchmark parity failure for #{t_name}" unless n_pill == l_pill
    end

    puts "\n=== Tag-Pill HTML Renderer (`ApplicationHelper#render_tag_link`, 10 pills per call) ==="
    tag_ruby_mem = MemoryProfiler.report { legacy_tag_batch.call }
    tag_rust_mem = MemoryProfiler.report { native_tag_batch.call }
    puts "render_tag_link (10 pills) Ruby Legacy allocations: " \
         "#{tag_ruby_mem.total_allocated} objects (#{tag_ruby_mem.total_allocated_memsize} bytes)"
    puts "render_tag_link (10 pills) Rust Magnus allocations: " \
         "#{tag_rust_mem.total_allocated} objects (#{tag_rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (10x link_to + Color::CompareHex)") { legacy_tag_batch.call }
      x.report("Rust Magnus (10x ForemNative.render_tag_link)") { native_tag_batch.call }
      x.compare!
    end

    now = Time.utc(2026, 11, 10, 15, 0, 0)
    cached_users = (0...15).map do |i|
      Articles::CachedEntity.new(
        "Author #{i} \"Systems\" & Co",
        "author_#{i}",
        "author_#{i}",
        "https://dev.to/uploads/user/avatar_#{i}_90.png",
        "https://dev.to/uploads/user/avatar_#{i}.png",
        (i % 4).zero?,
        (i % 7).zero?,
      )
    end
    cached_orgs = (0...4).map do |i|
      Articles::CachedEntity.new(
        "Org #{i} & <Team>",
        "org_slug_#{i}",
        "org_slug_#{i}",
        "https://dev.to/uploads/org/logo_#{i}_90.png",
        "https://dev.to/uploads/org/logo_#{i}.png",
        false,
        false,
      )
    end

    stories = (0...60).map do |idx|
      tags_slice = (0...4).map { |k| tag_names_only[(idx + k) % tag_names_only.size] }.uniq
      has_org = (idx % 3).zero?
      art = Article.new(
        id: 10_000 + idx,
        user_id: 200 + (idx % cached_users.size),
        organization_id: has_org ? (500 + (idx % cached_orgs.size)) : nil,
        title: "High-Throughput Rust View Rendering ##{idx}: Zero-Copy Slices & Safety",
        slug: "high-throughput-rust-view-rendering-#{idx}-#{10_000 + idx}",
        path: "/author_#{idx % cached_users.size}/high-throughput-rust-view-rendering-#{idx}-#{10_000 + idx}",
        type_of: (idx % 15 == 14 ? "status" : "full_post"),
        published: true,
        published_at: now - (idx * 25).minutes,
        main_image: idx.zero? ? "https://s3.amazonaws.com/bucket/featured-cover.png" : nil,
        main_image_height: 420,
        main_image_background_hex_color: "#2b3a4a",
        cached_tag_list: tags_slice.join(", "),
        public_reactions_count: idx % 5,
        comments_count: idx % 8,
        reading_time: 1 + (idx % 9),
        favorited_by_user_id: (idx % 10).zero? ? 999 : nil,
      )
      art.cached_user = cached_users[idx % cached_users.size]
      art.cached_organization = has_org ? cached_orgs[idx % cached_orgs.size] : nil
      art.processed_html = "<p>Quick status update ##{idx} from production.</p>" if art.type_of == "status"
      art.association(:context_notes).target = []
      art.association(:organization).loaded!
      art.instance_variable_set(
        :@preloaded_reaction_counts_for_reactable,
        if art.public_reactions_count.positive?
          [{ category: "like", count: art.public_reactions_count }, { category: "unicorn", count: 1 }]
        else
          []
        end,
      )
      art.decorate
    end

    viewer = User.new(id: 99_999, username: "viewer_user", name: "Viewer")
    view.instance_variable_set(:@user, viewer)
    RequestStore.store[:user_signed_in] = true

    featured_fn = ->(s) { s.id == 10_000 }
    legacy_feed_run = lambda do
      view.__send__(:legacy_render_story_cards, stories, featured_for: featured_fn, is_home_feed: true)
    end
    native_feed_run = lambda do
      view.__send__(:native_render_story_cards, stories, featured_for: featured_fn, is_home_feed: true)
    end

    legacy_feed_html = legacy_feed_run.call
    native_feed_html = native_feed_run.call
    raise "Story cards benchmark parity failure (native returned nil)" if native_feed_html.nil?
    raise "Story cards benchmark parity failure (HTML mismatch)" unless native_feed_html == legacy_feed_html

    puts "\n=== Story-Card Feed HTML Renderer (60-story feed + ~224 tag pills, #{native_feed_html.bytesize} bytes) ==="
    feed_ruby_mem = MemoryProfiler.report { legacy_feed_run.call }
    feed_rust_mem = MemoryProfiler.report { native_feed_run.call }
    puts "render_story_cards (60 stories) Ruby Legacy allocations (1 render): " \
         "#{feed_ruby_mem.total_allocated} objects (#{feed_ruby_mem.total_allocated_memsize} bytes)"
    puts "render_story_cards (60 stories) Rust Magnus allocations (1 render): " \
         "#{feed_rust_mem.total_allocated} objects (#{feed_rust_mem.total_allocated_memsize} bytes)"

    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report("Ruby Legacy (60x articles/_single_story ERB)") { legacy_feed_run.call }
      x.report("Rust Magnus (ForemNative.render_story_cards)") { native_feed_run.call }
      x.compare!
    end
  end

  desc "Benchmark pure-Rust image manipulation & avatar rendering kernels (forem_core::image_ops & avatar)"
  task benchmark_image_ops: :environment do
    require "benchmark/ips"
    require "exifr/jpeg"
    require "memory_profiler"
    require "open3"
    require "tempfile"

    avatar_traits = Images::ProfileImageGenerator.__send__(:select_traits, Random.new(42))
    gif_bytes = Rails.root.join("spec/fixtures/files/high_frame_count.gif").binread
    gps_jpg_path = Rails.root.join("spec/fixtures/files/image_gps_data.jpg").to_s
    gps_jpg_bytes = File.binread(gps_jpg_path)
    png_path = Rails.root.join("spec/fixtures/files/800x600.png").to_s
    png_bytes = File.binread(png_path)
    svg_path = Rails.root.join("app/assets/images/forem-icon.svg").to_s
    svg_bytes = File.binread(svg_path)
    social_template_path = Rails.root.join("app/assets/images/social_template.png").to_s
    social_template_bytes = File.binread(social_template_path)
    svg_font_path = BaseUploader::DEFAULT_SVG_FONT_PATH

    # Benchmark-only pure-Ruby legacy reference oracles for container inspection & JPEG EXIF stripping
    legacy_gif_inspect = lambda do |bytes|
      pos = 13
      packed = bytes.getbyte(10)
      pos += 3 * (1 << ((packed & 0x07) + 1)) if (packed & 0x80) != 0
      frames = 0
      len = bytes.bytesize
      while pos < len
        introducer = bytes.getbyte(pos)
        pos += 1
        case introducer
        when 0x3B then break
        when 0x21
          pos += 1
          while pos < len && (sub_len = bytes.getbyte(pos)).positive?
            pos += 1 + sub_len
          end
          pos += 1
        when 0x2C
          frames += 1
          local_packed = bytes.getbyte(pos + 8)
          pos += 9
          pos += 3 * (1 << ((local_packed & 0x07) + 1)) if local_packed && (local_packed & 0x80) != 0
          pos += 1
          while pos < len && (sub_len = bytes.getbyte(pos)).positive?
            pos += 1 + sub_len
          end
          pos += 1
        else
          break
        end
      end
      frames
    end

    legacy_jpeg_strip = lambda do |bytes|
      io = StringIO.new(bytes)
      _orient = EXIFR::JPEG.new(io).orientation&.to_i || 1
      out = +"\xFF\xD8".b
      pos = 2
      len = bytes.bytesize
      while pos + 1 < len && bytes.getbyte(pos) == 0xFF
        marker = bytes.getbyte(pos + 1)
        pos += 2
        next if marker == 0xFF

        if marker == 0xD9
          out << "\xFF\xD9".b
          break
        end
        if marker == 0xDA
          out << "\xFF\xDA".b << bytes.byteslice(pos, len - pos)
          break
        end
        seg_len = bytes.byteslice(pos, 2).unpack1("n")
        drop = (0xE1..0xEF).cover?(marker) || marker == 0xFE
        out << "\xFF".b << [marker].pack("C") << bytes.byteslice(pos, seg_len) unless drop
        pos += seg_len
      end
      out
    end

    puts "\n=== Paired Ruby Reference vs. Rust Magnus (`forem_core::image_ops`) ==="
    [
      [
        "GIF Frame Inspection (high_frame_count.gif)",
        -> { legacy_gif_inspect.call(gif_bytes) },
        -> { ForemNative.image_inspect(gif_bytes)[:frame_count] },
      ],
      [
        "JPEG EXIF Inspection + Strip (image_gps_data.jpg)",
        -> { legacy_jpeg_strip.call(gps_jpg_bytes) },
        -> { ForemNative.image_strip_and_auto_orient(gps_jpg_bytes) },
      ],
    ].each do |title, ruby_fn, rust_fn|
      ruby_fn.call
      rust_fn.call
      ruby_mem = MemoryProfiler.report { 10.times { ruby_fn.call } }
      rust_mem = MemoryProfiler.report { 10.times { rust_fn.call } }
      puts "\n-- #{title} --"
      puts "Ruby Legacy allocations (10 calls): #{ruby_mem.total_allocated} objects " \
           "(#{ruby_mem.total_allocated_memsize} bytes)"
      puts "Rust Magnus allocations (10 calls): #{rust_mem.total_allocated} objects " \
           "(#{rust_mem.total_allocated_memsize} bytes)"
      Benchmark.ips do |x|
        x.config(time: 1.5, warmup: 0.5)
        x.report("Ruby Legacy (#{title})") { ruby_fn.call }
        x.report("Rust Magnus (#{title})") { rust_fn.call }
        x.compare!
      end
    end

    # Optional paired ImageMagick CLI subprocess comparison when `magick` or `convert` is installed locally
    im_cmd = if system("magick", "-version", out: File::NULL, err: File::NULL)
               ["magick"]
             elsif system("convert", "-version", out: File::NULL, err: File::NULL)
               ["convert"]
             end
    if im_cmd
      puts "\n=== Paired ImageMagick CLI Subprocess vs. Rust Magnus (`resize_to_fill`) ==="
      im_resize_fn = lambda do
        Tempfile.create(["im_bench", ".png"]) do |tmp|
          system(*im_cmd, png_path, "-resize", "128x128^", "-gravity", "Center", "-extent", "128x128", tmp.path,
                 out: File::NULL, err: File::NULL)
          File.binread(tmp.path)
        end
      end
      rust_resize_fn = -> { ForemNative.image_resize_to_fill(png_bytes, 128, 128) }
      im_mem = MemoryProfiler.report { 5.times { im_resize_fn.call } }
      rust_mem = MemoryProfiler.report { 5.times { rust_resize_fn.call } }
      puts "ImageMagick CLI allocations (5 calls): #{im_mem.total_allocated} objects " \
           "(#{im_mem.total_allocated_memsize} bytes)"
      puts "Rust Magnus allocations     (5 calls): #{rust_mem.total_allocated} objects " \
           "(#{rust_mem.total_allocated_memsize} bytes)"
      Benchmark.ips do |x|
        x.config(time: 1.5, warmup: 0.5)
        x.report("ImageMagick CLI (800x600 -> 128x128)") { im_resize_fn.call }
        x.report("Rust Magnus     (800x600 -> 128x128)") { rust_resize_fn.call }
        x.compare!
      end
    end

    ops = {
      "render_profile_image_png (400x400 mascot)" =>
        -> { ForemNative.render_profile_image_png(avatar_traits) },
      "image_resize_to_fill (800x600 -> 128x128 PNG)" =>
        -> { ForemNative.image_resize_to_fill(png_bytes, 128, 128) },
      "image_convert_to_png (SVG -> PNG)" =>
        -> { ForemNative.image_convert_to_png(svg_bytes, font_path: svg_font_path, reject_blank: true) },
      "subforem_social_image_png (1000x500 composite)" =>
        -> { ForemNative.subforem_social_image_png(png_bytes, social_template_bytes, custom_background: false) }
    }

    puts "\n=== Pure-Rust Image Manipulation & Avatar Rendering (`forem_core::image_ops` & `avatar`) ==="
    ops.each do |label, fn|
      fn.call # warm up
      mem = MemoryProfiler.report { 10.times { fn.call } }
      puts "#{label} Rust Magnus allocations (10 calls): " \
           "#{mem.total_allocated} objects (#{mem.total_allocated_memsize} bytes)"
    end

    Benchmark.ips do |x|
      x.config(time: 1.5, warmup: 0.5)
      ops.each { |label, fn| x.report(label, &fn) }
    end
  end
end
# rubocop:enable Metrics/BlockLength
