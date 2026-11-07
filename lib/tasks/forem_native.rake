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
          lexer = Rouge::Lexer.find(lang) || Rouge::Lexers::PlainText.new
          highlighted = Rouge::Formatters::HTML.new.format(lexer.lex(code))
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
  task benchmark: %i[environment benchmark_extractors] do
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
end
# rubocop:enable Metrics/BlockLength
