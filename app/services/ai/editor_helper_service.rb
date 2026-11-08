module Ai
  class EditorHelperService
    include Ai::CommunityContext

    VERSION = "2.0".freeze

    GUIDE_CACHE_KEY = "ai:editor_helper:guide_with_mechanics_v4".freeze
    MAX_HISTORY_MESSAGES = 20
    MAX_TITLE_NON_SPACE_LENGTH = 128
    MAX_TAG_COUNT = 4
    MAX_TAG_LENGTH = 30
    MAX_BODY_BYTESIZE = 800.kilobytes
    MAX_CTA_LABEL_LENGTH = 128

    ALLOWED_FRONTMATTER_KEYS = %w[
      title published tags tag_list cached_tag_list description
      canonical_url cover_image main_image series collection_id
      published_at date id user_id organization_id
      ai_disclosure_level ai_assisted ai_generated
    ].freeze

    COMMON_FRONTMATTER_TYPOS = {
      "image" => "cover_image",
      "banner" => "cover_image",
      "header_image" => "cover_image",
      "thumbnail" => "cover_image",
      "category" => "tags",
      "categories" => "tags",
      "draft" => "published (use `published: false` for drafts)",
      "canonical" => "canonical_url",
      "summary" => "description",
      "excerpt" => "description"
    }.freeze

    LIQUID_BLOCK_TAGS = %w[
      card details spoiler collapsible cta katex
      row col features feature quotes quote offer slides
    ].freeze

    LIQUID_SELF_CLOSING_TAGS = %w[
      embed link post user tag organization comment podcast event
      agent_session feed slide youtube vimeo github gist twitter tweet
      codepen codesandbox stackblitz jsfiddle jsitor replit glitch
      reddit medium spotify soundcloud loom asciinema slideshare
      speakerdeck instagram wikipedia stackoverflow stackexchange
      bandcamp blogcast dotnetfiddle kotlin nexttech
    ].freeze

    LEGACY_PROVIDER_TAGS = %w[
      youtube vimeo github gist twitter tweet codepen codesandbox
      stackblitz jsfiddle jsitor replit glitch reddit medium spotify
      soundcloud loom asciinema slideshare speakerdeck instagram
      wikipedia stackoverflow stackexchange
    ].freeze

    ADMIN_ONLY_TAGS = %w[poll user_subscription].freeze
    BAD_XSS_REGEX = %r{(?:src=["']data:|data:text/html)}i
    GUIDE_H3_REGEX = %r{<%=?\s*render\s+partial:\s*"pages/editor_guide_h3"[^%]*?(?:title|text):\s*"([^"]+)"[^%]*%>}
    FEATURE_ICONS_ERB_REGEX = /<%=\s*safe_join\(FeatureTag::ICONS\.map.*?%>/m

    def initialize(user, history: [], article_state: nil)
      @user = user
      @history = normalize_history(history)
      @article_state = normalize_article_state(article_state)
      @ai_client = Ai::Base.new(
        model: Ai::FunctionConfig.gemini_model_for(:editor_helper),
        wrapper: self,
        affected_user: user,
      )
    end

    def generate_response(user_message)
      @history << { role: "user", text: user_message.to_s }

      response = @ai_client.call(prompt)

      @history << { role: "assistant", text: response.to_s }
      { response: response, history: @history }
    end

    private

    def prompt
      final_guide_text = cached_guide_with_mechanics
      advisement_context = build_advisement_context
      article_context = build_article_context
      community_name = resolve_community_name(subforem_id: RequestStore.store[:subforem_id])

      <<~PROMPT
        You are an insightful technical editor assistant for the #{community_name} community.
        Your goal is to help the user format, write, troubleshoot, and structure their article with complete accuracy.

        Here is the official #{community_name} Editor Guide and Platform Reference:
        #{final_guide_text}

        #{advisement_context}#{article_context}Current Conversation History:
        #{formatted_history}

        Guidelines:
        - Be encouraging, helpful, and technically grounded.
        - NEVER give unsolicited advice on what subjects to write about or how to structure the story itself UNLESS the user explicitly asks for feedback on their content strategy, or their writing is overwhelmingly non-sensical.
        - Answer formatting, UI navigation, publishing, and structural queries natively based on the official guidelines and reference above.
        - When the user asks what is wrong with their post, why an error occurred, why something is not rendering or publishing, or asks you to check/review their draft, carefully inspect the "Current Article State" and "Article Diagnostics & Detected Issues" sections and provide specific, line-referenced, actionable fixes.
        - Tailor UI instructions to the user's active Editor Version (`v2` Rich + Markdown UI controls and ⚙️ Post Options menu vs. `v1` Basic Markdown YAML frontmatter).
        - Use markdown for formatting your own responses. Provide fenced code blocks when giving markdown examples, frontmatter snippets, or Liquid tags.
        - Prefer global embeds as instructions (i.e. {% embed https://github... %}) over platform-specific tags (like {% github ... %}), if possible in the context.
        - Do not assume you understand how embeds work beyond instructions as given.
        - Use the Current Article State to inform your response ONLY if it is relevant to the user's question.
      PROMPT
    end

    def cached_guide_with_mechanics
      Rails.cache.fetch(GUIDE_CACHE_KEY, expires_in: 12.hours) do
        guide_path = Rails.root.join("app/views/pages/_editor_guide_text.en.html.erb")
        url_embeds_path = Rails.root.join("app/views/pages/_supported_url_embeds_list.en.html.erb")
        nonurl_embeds_path = Rails.root.join("app/views/pages/_supported_nonurl_embeds_list.en.html.erb")

        clean_guide = format_guide_html(File.read(guide_path))
        clean_url_embeds = format_url_embeds_html(File.read(url_embeds_path))
        clean_nonurl_embeds = format_nonurl_embeds_html(File.read(nonurl_embeds_path))

        <<~GUIDE
          #{platform_mechanics_reference}

          #{editor_ui_and_modes_reference}

          #{markdown_and_liquid_reference}

          #{validation_and_troubleshooting_reference}

          #{clean_guide}

          Supported URL Embeds:
          #{clean_url_embeds}

          Supported Non-URL (Block) Embeds:
          #{clean_nonurl_embeds}
        GUIDE
      end
    end

    def format_guide_html(raw_guide)
      with_headings = raw_guide
        .gsub(%r{<style[^>]*>.*?</style>}m, "")
        .gsub(GUIDE_H3_REGEX, "\n### \\1\n")
        .gsub(%r{<%=?\s*"(<a[^>]+></a>)"\s*%>}, "ANCHOR_EXAMPLE_PLACEHOLDER")
        .gsub(/<%=\s*community_name\s*%>/, Settings::Community.community_name.to_s)
        .gsub(/<%=.*?%>/m, "")
        .gsub(/<%.*?%>/m, "")
        .gsub(/<pre[^>]*>/, "\n```\n")
        .gsub("</pre>", "\n```\n")
        .gsub(/<code[^>]*>/, "`")
        .gsub("</code>", "`")

      sanitized_guide = ForemNative.full_sanitize(with_headings) ||
        ActionView::Base.full_sanitizer.sanitize(with_headings)
      CGI.unescapeHTML(sanitized_guide)
        .gsub("ANCHOR_EXAMPLE_PLACEHOLDER", '`<a name="chapter-1"></a>`')
        .gsub(/[ \t]+/, " ")
        .gsub(/\n{3,}/, "\n\n")
        .strip
    end

    def format_url_embeds_html(raw_url_embeds)
      raw_url_embeds
        .gsub(/<%=\s*community_name\s*%>/, Settings::Community.community_name.to_s)
        .gsub(/<%=.*?%>/, "")
        .gsub(/<%.*?%>/, "")
        .gsub(/<ul[^>]*>/, "\n")
        .gsub("</ul>", "\n")
        .gsub(/<li[^>]*>/, "- ")
        .gsub("</li>", "\n")
        .gsub(/<h4[^>]*>/, "\n### ")
        .gsub("</h4>", "\n")
        .gsub(/<p[^>]*>/, "\n")
        .gsub("</p>", "\n")
        .gsub(%r{<br\s*/?>}, "\n")
        .gsub(/<[^>]+>/, "")
        .gsub(/\n\s*\n\s*\n+/, "\n\n").strip
    end

    def format_nonurl_embeds_html(raw_nonurl_embeds)
      formatted_icons = FeatureTag::ICONS.map { |icon_name| "<code>#{icon_name}</code>" }.join(", ")
      raw_nonurl_embeds
        .gsub(FEATURE_ICONS_ERB_REGEX, formatted_icons)
        .gsub(/<%=\s*community_name\s*%>/, Settings::Community.community_name.to_s)
        .gsub(/<%=.*?%>/, "")
        .gsub(/<%.*?%>/, "")
        .gsub(/<h4[^>]*>/, "\n### ")
        .gsub("</h4>", "\n")
        .gsub(/<p[^>]*>/, "\n")
        .gsub("</p>", "\n")
        .gsub(%r{<br\s*/?>}, "\n")
        .gsub(/<pre[^>]*>/, "\n```\n")
        .gsub("</pre>", "\n```\n")
        .gsub(/<code[^>]*>/, "`")
        .gsub("</code>", "`")
        .gsub(/<[^>]+>/, "")
        .gsub("&amp;", "&")
        .gsub(/\n\s*\n\s*\n+/, "\n\n").strip
    end

    def platform_mechanics_reference
      <<~MECHANICS
        Platform Mechanics Overview:
        - Editor Versions & Formatting Toolbar: Both Editor versions—Rich + Markdown (v2, with dedicated UI fields for Title, Tags, and Cover Image) and Basic Markdown (v1, using Jekyll-style YAML front matter)—include the Markdown formatting toolbar above the body field with formatting actions, keyboard shortcuts, inline image upload, and Agent Session upload. Users can switch between Rich + Markdown and Basic Markdown in Settings > Customization.
        - Basic Markdown (v1) Front Matter Fields: Between triple-dashed lines (---), v1 supports title, published (true/false), description, tags (up to 4 comma-separated tags), canonical_url, cover_image, series, published_at, and ai_disclosure_level (not_disclosed, no_ai, some_ai, or fully_autonomous).
        - Tags: Tags are the primary organizational mechanism on the platform. Adding relevant tags enables the engine to correctly route the post to users following those specific subjects via their chronological or curated feed algorithms. The limit is four tags per post. Each tag must be alphanumeric only (a-z, 0-9, up to 30 characters, with no hyphens, underscores, spaces, or symbols like `#` or `+`). Tag aliases (such as `js` -> `javascript`) resolve automatically on save, and some tags carry custom submission templates or moderation guidelines.
        - Titles & Markdown: Catchy, plain-language titles historically perform better. The platform engine relies strictly on standard Markdown semantics alongside special Liquid embed blocks. Avoiding extremely dense text blocks while leveraging Markdown headers actively assists readability logic. Titles have a maximum limit of 128 non-whitespace characters.
        - Feature Liquid Tag Icons: Supported icon names for {% feature title="..." icon="..." %} are: #{FeatureTag::ICONS.join(', ')} (or any emoji).
        - Feed Personalization: Forem utilizes a heavily personalized algorithm where interactions (reads, reactions) actively shape future feed displays. Pushing engaging content inherently improves the likelihood of circulating upward in audience feeds. Clear, compelling titles and strong opening paragraphs improve click-through and completion rates, whereas deceptive clickbait or low-effort boilerplate degrades reader trust and feed distribution.
        - Organizations: Users can establish or join Organizations which act as unified brands. An author can elect to publish an article under their Organization domain, aggregating followers implicitly toward the organizational brand rather than solely the personal account.
        - Following Accounts: The Follow mechanic serves to anchor a baseline connection. When users publish content, their followers are dramatically more likely to be exposed to it initially on their dashboard, establishing a core audience burst. Activity distributions heavily favor connected follow graphs.
        - Series & Multi-Part Posts: Authors can group sequential posts into a named Series. Every article in a series renders an interactive table-of-contents widget linking all installments in order.
        - Co-Authors: Posts published under an Organization can credit organization members as co-authors. Personal posts can invite up to 4 followers as co-authors; invitees must follow the primary author and accept the co-author invitation before appearing on the byline.
        - AI Disclosure: Authors can disclose how AI was used in creating their post via three disclosure levels: `no_ai` (Hand Written), `some_ai` (AI Assisted), or `fully_autonomous` (AI Generated).
      MECHANICS
    end

    def editor_ui_and_modes_reference
      <<~EDITOR_UI
        Editor Modes & Interface Reference:
        1. Two Editor Modes (`v2` vs `v1`):
           - Rich + Markdown Editor (`v2`, default): Uses dedicated UI inputs at the top for Cover Image, Cover Video, Title, and Tags, and a bottom action bar with AI Disclosure and a Post Options (⚙️) modal for Canonical URL, Scheduling, Series, and Co-Authors. Do NOT place `---` YAML frontmatter inside the `v2` body textarea.
           - Basic Markdown Editor (`v1`): Uses a single raw Markdown textarea beginning with a Jekyll-style `---` YAML frontmatter block at the very top of the document, paired with the same Markdown formatting toolbar above the body field and the bottom action bar.
           - Switching Modes: Users can switch between "Rich + Markdown" and "Basic markdown" anytime in `Settings -> Customization -> Editor version`.

        2. Editor UI Controls & Locations:
           - Header Bar:
             - Account / Organization Switcher dropdown (top-left, next to page title): Switch between publishing under your Personal profile or an Organization you belong to.
             - Edit / Preview Tabs: Toggle between writing and live preview (Keyboard shortcut: `Cmd + Shift + P` on macOS, `Ctrl + Shift + P` on Windows/Linux).
           - Top Metadata Area (`v2` Rich + Markdown mode):
             - "Add a cover image": Upload a banner image (optimal dimensions `1000x420` pixels, max 25MB). When AI features are enabled, a "🍌 Generate Image" button is also available to generate a cover image from your title.
             - "Add a cover video": Attach a cover video URL instead of a cover image (mutually exclusive with cover image). Only YouTube (`youtube.com/watch?v=...` or `youtu.be/...`), Mux (`player.mux.com/...`), and Twitch (`twitch.tv/videos/...`) URLs are supported.
             - Post Title input: Renders as the article's `<h1>` heading (max 128 non-whitespace characters).
             - Tags field: Add up to 4 tags from the autocomplete dropdown or type new alphanumeric tags.
           - Editor Formatting Toolbar (present in both `v2` and `v1` modes above the body field):
             - Inline buttons for Bold, Italic, Link, Ordered List, Unordered List, Heading, Quote, Inline Code, Code Block, Embed (`{% embed ... %}`), Upload Image, Upload Agent Session (`/agent_sessions/new`), and Help (`?`) guide drawer toggle on smaller viewports (on desktop viewports, contextual help appears in the right-hand sidebar as you focus on Title, Tags, or Body).
             - Smart Paste & Drag-and-Drop: You can drag-and-drop or paste images directly from your clipboard into the body to upload them automatically. Selecting text and pasting a URL turns the selection into `[selected text](url)`. Pasting a bare embeddable URL offers to wrap it in `{% embed url %}`.
           - Bottom Action Bar:
             - Primary button: "Publish" (or "Schedule" when a future publish timestamp is set, or "Save changes" when editing an already-published article).
             - "Save draft" button: Saves an unpublished draft. Saved drafts and scheduled posts provide a secret shareable preview URL (`?preview=...`) at the top of the preview/draft page.
             - AI Disclosure button: Opens the AI Disclosure modal (`Hand Written`, `Assisted`, or `AI Generated`).
             - Post Options (⚙️ cog/hexagon icon button): Opens the Post Options modal containing:
               * Canonical URL: Set `https://...` if cross-posting an article originally published elsewhere (no spaces allowed; must be unique across published posts).
               * Schedule Publication: Pick a future date and time (in your local browser timezone) to auto-publish. Scheduled posts can be reverted to draft before publication. Once a post has been published in the past, its publication date is immutable.
               * Series: Choose an existing series or type a new series name.
               * Co-Authors: Select organization co-authors (for org posts) or invite up to 4 followers (for personal posts).
               * Danger Zone (shown when editing a published post): Contains "Unpublish post" to revert a live post back to a draft.
               * Active options display as clickable summary pills (`⏰ Scheduled`, `🔗 Canonical`, `📚 Series`) in the bottom bar.

        3. Basic Markdown (`v1`) Frontmatter Specification:
           - Must appear at the very top of the body wrapped in triple dashes (`---`):
             ```yaml
             ---
             title: "Your Post Title"
             published: false
             description: "A concise summary of the post"
             tags: javascript, webdev, beginners
             canonical_url: https://example.com/original-post
             cover_image: https://direct-url-to-image.jpg
             series: My Series Name
             published_at: "2026-05-01 11:18 +0000"
             ai_disclosure_level: some_ai
             ---
             ```
           - YAML Quoting Rule: Any `title`, `description`, or `series` value containing a colon (`:`), `#`, or quotes MUST be wrapped in double quotes `"..."` with any internal double quotes escaped with a backslash.
           - Valid `ai_disclosure_level` values: `not_disclosed`, `no_ai`, `some_ai`, `fully_autonomous` (or boolean shortcuts `ai_assisted: true`, `ai_generated: true`).
      EDITOR_UI
    end

    def markdown_and_liquid_reference
      <<~MARKDOWN_LIQUID
        Markdown, HTML & Liquid Embed Reference:
        1. Markdown & Code Blocks:
           - Fenced Code Blocks: Use triple backticks with a language identifier (e.g. ```javascript, ```ruby, ```python, ```go, ```rust, ```bash, ```html, ```css, ```sql, ```json, ```yaml, ```diff). Always close every ``` block.
           - Mermaid Diagrams: Use ```mermaid fenced code blocks to render flowcharts, sequence diagrams, state diagrams, ER diagrams, class diagrams, etc.
           - GitHub-Style Callout Alerts: Start a blockquote with `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, or `[!CAUTION]` on the first line:
             ```markdown
             > [!NOTE]
             > Important context or callout text here.
             ```
           - Tables: Standard GitHub-Flavored Markdown tables. Escape literal pipe characters inside cells with a backslash (`\\|`).
           - Footnotes: Use `[^1]` inline and `[^1]: Footnote definition` at the bottom of the post.
           - Headings & Accessibility: The article title is the page's `<h1>`. Start body headings at `##` (`<h2>`) and do not skip heading levels (e.g. go `##` -> `###` -> `####`, never `##` -> `####`).
           - Images & Captions:
             * Always replace default `![Image description](...)` with meaningful alt text for screen readers (the renderer strips the literal placeholder `"Image description"` to empty alt text).
             * Place `<figcaption>Caption text</figcaption>` immediately after an image to automatically wrap both in a `<figure>`.
             * When placing an image between items in a numbered list (`1.`, `2.`, `3.`), indent the image line by 4 spaces so the list numbering does not reset to `1`.
           - Allowed Inline HTML: `<kbd>`, `<sub>`, `<sup>`, `<mark>`, `<abbr>`, `<details>` / `<summary>`, `<figure>` / `<figcaption>`, `<picture>` / `<source>`, `<video>` (autoplays muted & looped like a GIF), `<ruby>` / `<rt>` / `<rp>`, and `<a name="anchor-name"></a>`. Data URIs (`src="data:..."` or `data:text/html`) are blocked for security.
           - Mentions: `@username` links to the user profile and notifies them on publish (maximum #{Settings::RateLimit.mention_creation} mentions per article).
           - Escaping Liquid Syntax: Liquid tags inside inline backticks `` `{% ... %}` `` or fenced code blocks are escaped automatically. To display literal `{% ... %}` or `{{ ... }}` in normal prose outside code blocks, wrap it in `{% raw %}...{% endraw %}`.

        2. Complete Liquid Tags Reference:
           - Universal URL Embed (`{% embed URL %}`):
             * Preferred syntax for embedding any external or community URL: `{% embed https://... %}`.
             * Supported services include: YouTube, GitHub (repositories, issues, pull requests, discussions, gists), X/Twitter, Bluesky, CodePen, CodeSandbox, StackBlitz, JSFiddle, JSitor, LiveCodes, Replit, Glitch, Hugging Face Spaces, Bolt.new, Lovable, Warp Terminal, Netlify, Google Cloud Run, Asciinema, Loom, Descript, Mux, Vimeo, Twitch, Reddit, Stack Overflow / Stack Exchange, Medium, Wikipedia, Spotify, SoundCloud, Bandcamp, Blogcast, SlideShare, Speaker Deck, Instagram, Kotlin Playground, DotNetFiddle, Next Tech, and community articles/comments/podcasts/events.
           - Community Entity Cards (Self-Closing Tags — DO NOT add `end...` tags):
             * `{% link https://... %}` or `{% post https://... %}` — Embeds a community article card.
             * `{% user username %}` — Embeds a user profile card.
             * `{% tag tagname %}` — Embeds a tag card.
             * `{% organization org_slug %}` — Embeds an organization card.
             * `{% comment comment_id_or_url %}` — Embeds a comment card.
             * `{% podcast https://... %}` — Embeds a podcast episode player.
             * `{% event event_slug %}` — Embeds an event card.
             * `{% agent_session ID %}` (optional named slice `{% agent_session ID planning %}` or message range `{% agent_session ID 0..10 %}`) — Embeds an interactive AI coding agent session transcript.
             * `{% feed org=slug tag=name tags=a,b limit=8 sort=recent|reactions|comments|score min_reactions=5 min_comments=2 since=30d|YYYY-MM-DD %}` — Embeds a dynamic article feed (requires at least one of `org=`, `tag=`, or `tags=`; `limit` is 1-30, default 8).
           - Layout & Interactive Block Tags (MUST be closed with matching `{% end<tag> %}`):
             * Card container:
               ```markdown
               {% card %}
               Markdown content inside a highlighted card.
               {% endcard %}
               ```
             * Collapsible details / spoiler (`details`, `spoiler`, or `collapsible`):
               ```markdown
               {% details Click to expand %}
               Hidden or supplementary markdown content.
               {% enddetails %}
               ```
             * Call-to-Action button (`cta` — requires `http://` or `https://` URL; plain-text label max 128 chars):
               ```markdown
               {% cta https://example.com %}Check out the demo{% endcta %}
               ```
             * KaTeX Math (`katex` and `katex inline`):
               ```markdown
               {% katex %}
               c = \\pm\\sqrt{a^2 + b^2}
               {% endkatex %}
               Inline math: {% katex inline %}E = mc^2{% endkatex %}
               ```
             * Multi-Column Grid (`row` and `col` with optional `span=1..4` and `background=default|subtle`):
               ```markdown
               {% row %}
               {% col span=2 background=subtle %}
               Left column content
               {% endcol %}
               {% col span=2 %}
               Right column content
               {% endcol %}
               {% endrow %}
               ```
             * Feature Grid (`features` and `feature` — `title="..."` is required on each `feature`; optional `icon="..."` supports any emoji or one of: #{FeatureTag::ICONS.join(', ')}):
               ```markdown
               {% features %}
               {% feature title="Fast Setup" icon="lightning" %}
               Ready in minutes.
               {% endfeature %}
               {% endfeatures %}
               ```
             * Structured Quotes / Testimonials (`quote` and optional `quotes` wrapper — `author="..."` is required on each `quote`; optional `role=`, `image=`, `rating=1..5`, `source=`, `link=`):
               ```markdown
               {% quotes %}
               {% quote author="Jane Doe" role="Staff Engineer" rating=5 %}
               This workflow saved our team hours every week.
               {% endquote %}
               {% endquotes %}
               ```
             * Promotional Offer Banner (`offer` — optional `link="https://..."` and `button="Button Text"`):
               ```markdown
               {% offer link="https://example.com" button="Get Started" %}
               Special community launch offer!
               {% endoffer %}
               ```
             * Image/Video Gallery or Carousel (`slides` block with self-closing `{% slide ... %}` items inside — each `slide` requires at least one of `image=`, `video=`, or `link=`, with optional `title=` and `alt=`; `slides` accepts `mode="default"` or `mode="carousel"`):
               ```markdown
               {% slides mode="carousel" %}
               {% slide image="https://example.com/one.png" title="Step 1" alt="First screen" %}
               {% slide image="https://example.com/two.png" title="Step 2" alt="Second screen" %}
               {% endslides %}
               ```
      MARKDOWN_LIQUID
    end

    def validation_and_troubleshooting_reference
      <<~TROUBLESHOOTING
        Validation Rules & Common Error Troubleshooting:
        - "Title can't be blank" / "Title is too long": Title is required and cannot exceed 128 non-whitespace characters. In `v1` mode, ensure `title:` is present inside the top `---` frontmatter block and properly quoted if it contains a colon `:`.
        - Tag validation errors ("contains non-alphanumeric characters", "is too long", "exceeds maximum of 4 tags"):
          * Maximum 4 tags per post.
          * Tags cannot contain hyphens (`-`), underscores (`_`), dots (`.`), spaces, `#`, `+`, or any punctuation (e.g. use `reactnative` instead of `react-native`, `csharp` instead of `c#`, `cpp` instead of `c++`, `nodejs` instead of `node.js`).
          * Maximum 30 characters per tag.
        - "Invalid frontmatter" / YAML syntax errors: Caused by unquoted colons (`:`) or unescaped double quotes (`"`) in frontmatter values, or mismatched `---` delimiters. Wrap text values in `"..."`.
        - "Liquid error" / Unknown tag / Unclosed block tag:
          * Every block tag (`card`, `details`, `spoiler`, `collapsible`, `cta`, `katex`, `row`, `col`, `features`, `feature`, `quotes`, `quote`, `offer`, `slides`) MUST have a matching `{% end<tag> %}`.
          * Self-closing tags (`embed`, `link`, `user`, `tag`, `organization`, `comment`, `podcast`, `event`, `agent_session`, `feed`, `slide`) must NOT have an `{% end... %}` tag.
          * If writing tutorial text showing Liquid or template syntax (like Jinja, Nunjucks, Vue/Handlebars `{{ variable }}`, or GitHub Actions `${{ ... }}`), wrap it in backticks, a fenced code block, or `{% raw %}...{% endraw %}`.
        - "Body markdown contains invalid characters": Usually triggered by `data:` URLs (`src="data:image/..."` or `data:text/html`) pasted into the body. Upload images using the toolbar's Upload Image button or drag-and-drop instead of base64 data URIs.
        - "Canonical URL has already been taken" / "is invalid": Canonical URL must be a valid `http://` or `https://` URL with no spaces, and cannot duplicate another published article's `canonical_url`.
        - "Video source URL must be from a permitted source": Cover videos only accept YouTube, Mux (`player.mux.com`), or Twitch (`twitch.tv/videos/`) URLs.
        - Accessibility Suggestions in Preview:
          * Avoid `#` (Level 1 headings) in the body because the post title is already `<h1>`; use `##` (`<h2>`) for main sections.
          * Do not skip heading levels (e.g., jumping from `##` directly to `####`).
          * Replace default `![Image description](...)` or empty `![](...)` with descriptive alt text.
      TROUBLESHOOTING
    end

    def build_advisement_context
      expanded_spec = resolve_content_advisement_spec(subforem_id: RequestStore.store[:subforem_id])
      return "" if expanded_spec.blank?

      <<~ADVISEMENT
        The platform explicitly specifies the following about ideal content:
        #{expanded_spec}

      ADVISEMENT
    end

    def build_article_context
      return "" if @article_state.blank?

      metadata_lines = build_metadata_lines
      diagnostics = analyze_article_state
      diagnostics_block = if diagnostics.any?
                            diagnostics.map { |item| "- #{item}" }.join("\n")
                          else
                            "- No syntax, validation, or accessibility errors detected in the current draft."
                          end

      <<~CONTEXT
        Current Article State:
        Title: #{@article_state[:title]}
        #{metadata_lines}Body:
        #{@article_state[:body]}

        Article Diagnostics & Detected Issues:
        #{diagnostics_block}

      CONTEXT
    end

    def build_metadata_lines
      version = detected_editor_version
      version_label = version == "v1" ? "v1 (Basic Markdown with frontmatter)" : "v2 (Rich + Markdown UI)"
      lines = ["Editor Version: #{version_label}"]

      append_tab_and_tag_metadata(lines)
      append_optional_field_metadata(lines)

      "#{lines.join("\n")}\n"
    end

    def append_tab_and_tag_metadata(lines)
      if @article_state.key?(:preview_showing)
        tab = @article_state[:preview_showing] ? "Preview" : "Edit"
        lines << "Active Editor Tab: #{tab}"
      end

      tags = extract_tags_list
      return unless @article_state.key?(:tags) || @article_state.key?(:tag_list) || tags.any?

      lines << "Tags: #{tags.any? ? tags.join(', ') : '(none)'}"
    end

    def append_optional_field_metadata(lines)
      {
        canonical_url: "Canonical URL",
        series: "Series",
        main_image: "Cover Image",
        video_source_url: "Cover Video URL"
      }.each do |key, label|
        lines << "#{label}: #{@article_state[key]}" if @article_state[key].present?
      end

      schedule = "#{@article_state[:published_at_date]} #{@article_state[:published_at_time]}".strip
      lines << "Scheduled Publish Time: #{schedule}" if schedule.present?

      disclosure = @article_state[:ai_disclosure_level]
      return if disclosure.blank? || disclosure == "not_disclosed"

      lines << "AI Disclosure Level: #{disclosure}"
    end

    def analyze_article_state
      issues = []
      body = @article_state[:body].to_s
      version = detected_editor_version

      collect_client_reported_errors(issues)
      frontmatter_data, markdown_body, body_line_offset = analyze_frontmatter(body, version, issues)
      analyze_title(frontmatter_data, issues)
      analyze_tags(frontmatter_data, issues)
      analyze_metadata_options(frontmatter_data, body, issues)
      analyze_liquid_tags(markdown_body, body_line_offset, issues)
      analyze_markdown_and_accessibility(markdown_body, body_line_offset, issues)

      issues
    rescue StandardError => e
      Rails.logger.warn("Ai::EditorHelperService diagnostic error: #{e.message}")
      issues
    end

    def collect_client_reported_errors(issues)
      extract_error_strings(@article_state[:errors]).each do |err|
        issues << "[Active UI Error Banner] #{err}"
      end

      Array(@article_state[:markdown_lint_errors]).each do |lint|
        next unless lint.is_a?(Hash) || lint.respond_to?(:[])

        line = lint[:lineNumber] || lint["lineNumber"]
        desc = lint[:ruleDescription] || lint["ruleDescription"]
        detail = lint[:errorDetail] || lint["errorDetail"]
        msg = [desc, detail].compact.join(" ")
        issues << "[Preview Accessibility Notice#{line ? " - Line #{line}" : ''}] #{msg}" if msg.present?
      end
    end

    def extract_error_strings(raw_errors)
      return [] if raw_errors.blank?

      case raw_errors
      when String
        [raw_errors.strip].compact_blank
      when Array
        raw_errors.flat_map { |item| extract_error_strings(item) }
      when Hash, ActionController::Parameters
        extract_hash_error_strings(raw_errors)
      else
        []
      end
    end

    def extract_hash_error_strings(raw_errors)
      hash = raw_errors.respond_to?(:to_unsafe_h) ? raw_errors.to_unsafe_h : raw_errors.to_h
      nested = hash["errors"] || hash[:errors] || hash["error"] || hash[:error]
      return extract_error_strings(nested) if nested.present?

      hash.map { |k, v| "#{k}: #{Array(v).join(', ')}" }
    end

    def analyze_frontmatter(body, version, issues)
      frontmatter_data = {}
      stripped = body.lstrip
      leading_blank_lines = body.lines.take_while { |l| l.strip.empty? }.count

      unless stripped.start_with?("---")
        if version == "v1" && body.strip.present?
          issues << "[Frontmatter Error] Editor is in Basic Markdown (v1) mode, " \
                    "but the post body does not start with a `---` YAML frontmatter block."
        end
        return [frontmatter_data, body, 0]
      end

      match = stripped.match(/\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\z/m)
      unless match
        issues << "[Frontmatter Error] Opening `---` YAML frontmatter delimiter found at the top of the body, " \
                  "but the closing `---` delimiter is missing or malformed."
        return [frontmatter_data, body, 0]
      end

      raw_yaml = match[1]
      remaining_body = match[2].to_s
      line_offset = leading_blank_lines + raw_yaml.lines.count + 2

      if version == "v2"
        issues << "[Editor Mode Warning] YAML frontmatter (`--- ... ---`) was detected inside the post body " \
                  "while using the Rich + Markdown (v2) editor. In v2 mode, set your title, tags, cover image, " \
                  "canonical URL, series, and schedule using the editor UI fields and the ⚙️ Post Options button " \
                  "at the bottom (or switch to the Basic Markdown v1 editor in Settings -> Customization)."
      end

      parse_frontmatter_yaml(raw_yaml, frontmatter_data, issues)
      [frontmatter_data, remaining_body, line_offset]
    end

    def parse_frontmatter_yaml(raw_yaml, frontmatter_data, issues)
      parsed = YAML.safe_load(raw_yaml, permitted_classes: [Date, Time])
      if parsed.is_a?(Hash)
        parsed.each { |k, v| frontmatter_data[k.to_s] = v }
        validate_frontmatter_keys_and_values(frontmatter_data, issues)
      elsif parsed.present?
        issues << "[Frontmatter Error] Frontmatter block must be a YAML key-value mapping (e.g. `title: \"My Post\"`)."
      end
    rescue Psych::SyntaxError => e
      issues << "[Frontmatter YAML Syntax Error] Invalid YAML in frontmatter (#{e.message.strip}). " \
                "Ensure values containing colons (`:`) or special characters are wrapped in double quotes " \
                "`\"...\"` with internal quotes escaped as `\\\"`."
      extract_fallback_frontmatter_keys(raw_yaml, frontmatter_data)
    end

    def extract_fallback_frontmatter_keys(raw_yaml, frontmatter_data)
      raw_yaml.each_line do |line|
        next unless (match = line.chomp.match(/\A\s*([a-zA-Z0-9_]+)\s*:\s*(.*)\z/))

        key = match[1]
        value = match[2].strip.gsub(/\A["']|["']\z/, "")
        frontmatter_data[key] = value if value.present?
      end
    end

    def validate_frontmatter_keys_and_values(frontmatter_data, issues)
      frontmatter_data.each_key do |key|
        next if ALLOWED_FRONTMATTER_KEYS.include?(key)

        suggestion = COMMON_FRONTMATTER_TYPOS[key]
        supported = ALLOWED_FRONTMATTER_KEYS.first(10).join(", ")
        hint = suggestion ? " Did you mean `#{suggestion}`?" : " Supported keys: #{supported}."
        issues << "[Frontmatter Warning] Unrecognized frontmatter key `#{key}:`.#{hint}"
      end

      disclosure = frontmatter_data["ai_disclosure_level"]
      if disclosure.present? && !AiDisclosable::AI_DISCLOSURE_LEVELS.key?(disclosure.to_s)
        valid_levels = AiDisclosable::AI_DISCLOSURE_LEVELS.keys.join(", ")
        issues << "[Frontmatter Error] Invalid `ai_disclosure_level: #{disclosure}`. Must be one of: #{valid_levels}."
      end

      cover = frontmatter_data["cover_image"] || frontmatter_data["main_image"]
      return unless cover.present? && !cover.to_s.match?(%r{\Ahttps?://\S+\z}i)

      issues << "[Frontmatter Error] `cover_image` must be a valid direct `http://` or `https://` URL " \
                "(got `#{cover}`)."
    end

    def analyze_title(frontmatter_data, issues)
      effective_title = @article_state[:title].presence || frontmatter_data["title"].to_s
      if effective_title.blank?
        issues << "[Validation Warning] Title is blank. A title is required to save or publish the article."
        return
      end

      non_space_length = effective_title.gsub(/\p{Space}+/u, "").length
      return unless non_space_length > MAX_TITLE_NON_SPACE_LENGTH

      issues << "[Validation Error] Title exceeds the maximum limit of #{MAX_TITLE_NON_SPACE_LENGTH} " \
                "non-whitespace characters (currently #{non_space_length} non-whitespace characters)."
    end

    def analyze_tags(frontmatter_data, issues)
      tags = extract_tags_list(frontmatter_data)
      return if tags.empty?

      if tags.size > MAX_TAG_COUNT
        issues << "[Tag Validation Error] #{tags.size} tags are selected (`#{tags.join(', ')}`), " \
                  "exceeding the maximum of #{MAX_TAG_COUNT} tags per article."
      end

      valid_tag_names = []
      tags.each do |tag|
        if tag.length > MAX_TAG_LENGTH
          issues << "[Tag Validation Error] Tag `#{tag}` is #{tag.length} characters long, " \
                    "exceeding the #{MAX_TAG_LENGTH}-character limit."
        elsif !tag.match?(/\A[[:alnum:]]+\z/i)
          suggested = tag.gsub(/[^[:alnum:]]/, "").downcase
          suggestion_text = suggested.present? ? " Use `#{suggested}` instead." : ""
          issues << "[Tag Validation Error] Tag `#{tag}` contains invalid characters. Tags only allow " \
                    "alphanumeric characters (letters and numbers, no hyphens `-`, underscores `_`, dots `.`, " \
                    "spaces, or symbols).#{suggestion_text}"
        else
          valid_tag_names << tag.downcase
        end
      end

      append_tag_database_context(valid_tag_names, issues) if valid_tag_names.any?
    end

    def append_tag_database_context(tag_names, issues)
      Tag.where(name: tag_names.uniq).find_each do |tag_record|
        if tag_record.alias_for.present?
          issues << "[Tag Note] Tag `##{tag_record.name}` is an alias and will automatically resolve " \
                    "to `##{tag_record.alias_for}`."
        end
        if tag_record.moderation_instructions.present?
          issues << "[Tag Guideline for ##{tag_record.name}] #{tag_record.moderation_instructions.squish}"
        elsif tag_record.short_summary.present?
          issues << "[Tag Context for ##{tag_record.name}] #{tag_record.short_summary.squish}"
        end
      end
    end

    def analyze_metadata_options(frontmatter_data, body, issues)
      canonical_url = (@article_state[:canonical_url].presence || frontmatter_data["canonical_url"]).to_s.strip
      validate_canonical_url(canonical_url, issues) if canonical_url.present?

      video_url = @article_state[:video_source_url].to_s.strip
      if video_url.present? && !Article.permitted_video_source_url?(video_url)
        issues << "[Validation Error] Cover video URL `#{video_url}` is not from a supported provider. " \
                  "Only YouTube (`youtube.com/watch?v=...` or `youtu.be/...`), Mux (`player.mux.com/...`), " \
                  "and Twitch (`twitch.tv/videos/...`) URLs are permitted."
      end

      if body.bytesize > MAX_BODY_BYTESIZE
        issues << "[Validation Error] Article body exceeds the maximum allowed size of 800 KB."
      end

      body_without_code = mask_code_blocks_preserving_lines(body)
      if body_without_code.match?(BAD_XSS_REGEX)
        issues << "[Security Validation Error] Body contains a `data:` URI (`src=\"data:...\"` or `data:text/html`), " \
                  "which is blocked by security filters and will fail validation with 'contains invalid characters'. " \
                  "Upload images via the editor toolbar or drag-and-drop instead."
      end

      mentions = body_without_code.scan(/(?:^|[^\w@])@([a-zA-Z0-9_]+)/).flatten.map(&:downcase).uniq
      max_mentions = Settings::RateLimit.mention_creation
      return unless mentions.size > max_mentions

      mention_list = mentions.map { |m| "@#{m}" }.join(", ")
      issues << "[Validation Error] Article contains #{mentions.size} unique `@username` mentions " \
                "(#{mention_list}), exceeding the maximum limit of #{max_mentions} mentions per post."
    end

    def validate_canonical_url(canonical_url, issues)
      if canonical_url.match?(/\s/) || !canonical_url.match?(%r{\Ahttps?://\S+\z}i)
        issues << "[Validation Error] Canonical URL `#{canonical_url}` is invalid. " \
                  "It must start with `http://` or `https://` and contain no spaces."
        return
      end

      scope = Article.where(published: true, canonical_url: canonical_url)
      article_id = @article_state[:id]
      scope = scope.where.not(id: article_id) if article_id.present?
      return unless scope.exists?

      issues << "[Validation Error] Canonical URL `#{canonical_url}` has already been taken " \
                "by another published article on the platform."
    end

    def analyze_liquid_tags(markdown_body, line_offset, issues)
      return if markdown_body.blank?

      masked = mask_code_blocks_preserving_lines(markdown_body)
      masked = mask_raw_liquid_blocks(masked, line_offset, issues)

      open_blocks = []

      masked.lines.each_with_index do |line, idx|
        line_num = idx + 1 + line_offset

        line.scan(/\{\{-?\s*(.*?)\s*-?\}\}/) do |match|
          expr = match.first.to_s.strip
          issues << "[Liquid Syntax Warning - Line #{line_num}] Unescaped Liquid variable expression " \
                    "`{{ #{expr} }}` outside of a code block will be evaluated by Liquid and render as blank text. " \
                    "Wrap it in backticks `` `{{ #{expr} }}` ``, a fenced code block, or `{% raw %}...{% endraw %}`."
        end

        line.scan(/\{%-?\s*([a-zA-Z0-9_]+)(.*?)-?%\}/) do |tag_name, raw_args|
          process_liquid_tag_token(
            tag_name.downcase,
            raw_args.to_s.strip,
            line_num,
            open_blocks,
            issues,
          )
        end
      end

      open_blocks.each do |entry|
        issues << "[Liquid Syntax Error - Line #{entry[:line]}] Unclosed `{% #{entry[:tag]} %}` block tag " \
                  "(missing matching `{% end#{entry[:tag]} %}`)."
      end
    end

    def mask_raw_liquid_blocks(text, line_offset, issues)
      open_raw_line = nil
      in_raw = false
      result_lines = text.lines.map.with_index do |line, idx|
        line_num = idx + 1 + line_offset
        if !in_raw && line.match?(/\{%-?\s*raw\s*-?%\}/)
          if line.match?(/\{%-?\s*raw\s*-?%\}.*?\{%-?\s*endraw\s*-?%\}/)
            line.gsub(/\{%-?\s*raw\s*-?%\}.*?\{%-?\s*endraw\s*-?%\}/, "")
          else
            in_raw = true
            open_raw_line = line_num
            ""
          end
        elsif in_raw && line.match?(/\{%-?\s*endraw\s*-?%\}/)
          in_raw = false
          open_raw_line = nil
          ""
        elsif in_raw
          ""
        else
          line
        end
      end

      if in_raw && open_raw_line
        issues << "[Liquid Syntax Error - Line #{open_raw_line}] Unclosed `{% raw %}` tag (missing `{% endraw %}`)."
      end

      result_lines.join("\n")
    end

    def process_liquid_tag_token(tag_name, args, line_num, open_blocks, issues)
      if tag_name.start_with?("end")
        handle_closing_liquid_tag(tag_name, line_num, open_blocks, issues)
        return
      end

      if LIQUID_BLOCK_TAGS.include?(tag_name)
        open_blocks << { tag: tag_name, line: line_num }
      end

      if Liquid::Template.tags[tag_name].nil?
        issues << "[Liquid Syntax Error - Line #{line_num}] Unknown Liquid tag `{% #{tag_name} %}` " \
                  "is not supported on this platform. If this is code/template syntax meant to be displayed " \
                  "literally, wrap it in backticks or a fenced code block."
        return
      end

      validate_specific_liquid_tag(tag_name, args, line_num, open_blocks, issues)
    end

    def handle_closing_liquid_tag(tag_name, line_num, open_blocks, issues)
      base_tag = tag_name.delete_prefix("end")
      if LIQUID_SELF_CLOSING_TAGS.include?(base_tag)
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% #{tag_name} %}` is invalid because " \
                  "`{% #{base_tag} %}` is a single self-closing tag and does not use a closing tag."
        return
      end

      matching_index = open_blocks.rindex { |item| item[:tag] == base_tag }
      if matching_index
        open_blocks.delete_at(matching_index)
      else
        issues << "[Liquid Syntax Error - Line #{line_num}] Stray closing tag `{% #{tag_name} %}` " \
                  "found without a matching opening `{% #{base_tag} %}` tag."
      end
    end

    def validate_specific_liquid_tag(tag_name, args, line_num, open_blocks, issues)
      if ADMIN_ONLY_TAGS.include?(tag_name) && !admin_user?
        issues << "[Liquid Permission Error - Line #{line_num}] `{% #{tag_name} %}` " \
                  "is restricted to platform administrators and will fail to render."
        return
      end

      case tag_name
      when "embed", "link", "post", "podcast"
        validate_url_liquid_tag(tag_name, args, line_num, issues)
      when "cta"
        validate_cta_tag(args, line_num, issues)
      when "feed"
        validate_feed_tag(args, line_num, issues)
      when "feature"
        validate_feature_tag(args, line_num, issues)
      when "quote"
        validate_quote_tag(args, line_num, issues)
      when "offer"
        validate_offer_tag(args, line_num, issues)
      when "slides"
        validate_slides_tag(args, line_num, issues)
      when "slide"
        validate_slide_tag(args, line_num, open_blocks, issues)
      when "col"
        validate_col_tag(args, line_num, open_blocks, issues)
      when "agent_session", *LEGACY_PROVIDER_TAGS
        validate_nonblank_argument_tag(tag_name, args, line_num, issues)
      end
    end

    def validate_cta_tag(args, line_num, issues)
      return if args.present? && args.match?(%r{\Ahttps?://\S+\z}i)

      issues << "[Liquid Syntax Error - Line #{line_num}] `{% cta %}` requires a valid `http://` or `https://` URL " \
                "(e.g. `{% cta https://example.com %}Button Text{% endcta %}`)."
    end

    def validate_feature_tag(args, line_num, issues)
      unless args.match?(/\btitle\s*=\s*(?:"[^"]+"|'[^']+'|\S+)/)
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% feature %}` requires a `title=\"...\"` attribute."
      end

      icon_match = args.match(/\bicon\s*=\s*(?:"([^"]*)"|'([^']*)'|(\S+))/)
      return unless icon_match

      icon = (icon_match[1] || icon_match[2] || icon_match[3]).to_s
      return if icon.blank? || !icon.match?(FeatureTag::ICON_NAME_REGEXP)
      return if FeatureTag::LEGACY_ICON_ALIASES.key?(icon) || FeatureTag.renderable_icon?(icon)

      issues << "[Liquid Syntax Error - Line #{line_num}] `{% feature %}` has unsupported `icon=\"#{icon}\"`. " \
                "Supported icon names are: #{FeatureTag::ICONS.join(', ')} (or any emoji)."
    end

    def validate_quote_tag(args, line_num, issues)
      unless args.match?(/\bauthor\s*=\s*(?:"[^"]+"|'[^']+'|\S+)/)
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% quote %}` requires an `author=\"...\"` attribute."
      end

      if (rating_match = args.match(/\brating\s*=\s*["']?(\S+?)["']?(?:\s|\z)/))
        rating_str = rating_match[1]
        unless rating_str.match?(/\A\d+\z/) && QuoteTag::VALID_RATINGS.include?(rating_str.to_i)
          issues << "[Liquid Syntax Error - Line #{line_num}] `{% quote %}` `rating` must be between 1 and 5 " \
                    "(got `#{rating_str}`)."
        end
      end

      validate_optional_url_attributes("quote", args, %w[link image], line_num, issues)
    end

    def validate_offer_tag(args, line_num, issues)
      validate_optional_url_attributes("offer", args, %w[link], line_num, issues)
    end

    def validate_slides_tag(args, line_num, issues)
      mode_match = args.match(/\bmode\s*=\s*["']?(\S+?)["']?(?:\s|\z)/)
      return unless mode_match && SlidesTag::VALID_MODES.exclude?(mode_match[1])

      issues << "[Liquid Syntax Error - Line #{line_num}] `{% slides %}` `mode` must be `default` or `carousel` " \
                "(got `#{mode_match[1]}`)."
    end

    def validate_optional_url_attributes(tag_name, args, attr_names, line_num, issues)
      attr_names.each do |attr|
        match = args.match(/\b#{attr}\s*=\s*(?:"([^"]*)"|'([^']*)'|(\S+))/)
        next unless match

        url = (match[1] || match[2] || match[3]).to_s
        next if url.blank? || url.match?(%r{\Ahttps?://\S+\z}i)

        issues << "[Liquid Syntax Error - Line #{line_num}] `{% #{tag_name} %}` `#{attr}` must be a valid " \
                  "`http://` or `https://` URL (got `#{url}`)."
      end
    end

    def validate_nonblank_argument_tag(tag_name, args, line_num, issues)
      return if args.present?

      issues << "[Liquid Syntax Error - Line #{line_num}] `{% #{tag_name} %}` " \
                "is missing its URL or identifier argument."
    end

    def validate_url_liquid_tag(tag_name, args, line_num, issues)
      if args.blank?
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% #{tag_name} %}` is missing a URL argument."
      elsif tag_name == "embed" && !args.match?(%r{\Ahttps?://\S+}i)
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% embed #{args} %}` " \
                  "requires a full `http://` or `https://` URL."
      end
    end

    def validate_feed_tag(args, line_num, issues)
      unless args.match?(/\b(?:org|tag|tags)\s*=/)
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% feed %}` requires at least one filter attribute: " \
                  "`org=slug`, `tag=name`, or `tags=tag1,tag2`."
      end

      sort_match = args.match(/\bsort\s*=\s*["']?([a-zA-Z_]+)["']?/)
      if sort_match && FeedTag::VALID_SORTS.exclude?(sort_match[1])
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% feed %}` has invalid `sort=#{sort_match[1]}` " \
                  "(supported values: `recent`, `reactions`, `comments`, `score`)."
      end

      limit_match = args.match(/\blimit\s*=\s*["']?(\S+?)["']?(?:\s|\z)/)
      return unless limit_match

      limit_val = Integer(limit_match[1], exception: false)
      return if limit_val && (1..FeedTag::MAX_LIMIT).cover?(limit_val)

      issues << "[Liquid Syntax Error - Line #{line_num}] `{% feed %}` `limit` must be between 1 and " \
                "#{FeedTag::MAX_LIMIT} (got `#{limit_match[1]}`)."
    end

    def validate_slide_tag(args, line_num, open_blocks, issues)
      unless open_blocks.any? { |b| b[:tag] == "slides" }
        issues << "[Liquid Syntax Error - Line #{line_num}] `{% slide %}` must be placed inside " \
                  "a `{% slides %}...{% endslides %}` block."
      end
      if args.match?(/\b(?:image|video|link)\s*=\s*(?:"[^"]+"|'[^']+'|\S+)/)
        validate_optional_url_attributes("slide", args, %w[image video link], line_num, issues)
        return
      end

      issues << "[Liquid Syntax Error - Line #{line_num}] `{% slide %}` requires at least one of " \
                "`image=\"https://...\"`, `video=\"https://...\"`, or `link=\"https://...\"`."
    end

    def validate_col_tag(args, line_num, open_blocks, issues)
      unless open_blocks.any? { |b| b[:tag] == "row" }
        issues << "[Liquid Syntax Warning - Line #{line_num}] `{% col %}` should be nested inside " \
                  "a `{% row %}...{% endrow %}` block."
      end
      span_match = args.match(/\bspan\s*=\s*["']?(\S+?)["']?(?:\s|\z)/)
      return unless span_match && !(1..4).cover?(span_match[1].to_i)

      issues << "[Liquid Syntax Error - Line #{line_num}] `{% col %}` `span` must be between 1 and 4 " \
                "(got `#{span_match[1]}`)."
    end

    def analyze_markdown_and_accessibility(markdown_body, line_offset, issues)
      return if markdown_body.blank?

      in_fence = false
      fence_marker = nil
      fence_open_line = nil
      unlabeled_fence_lines = []
      last_heading_level = 0
      in_numbered_list = false

      markdown_body.lines.each_with_index do |line_with_newline, idx|
        raw_line = line_with_newline.chomp
        line_num = idx + 1 + line_offset
        stripped = raw_line.strip

        if !in_fence && (fence_match = raw_line.match(/\A\s*(`{3,}|~{3,})(.*)\z/))
          in_fence = true
          fence_marker = fence_match[1][0] * fence_match[1].length
          fence_open_line = line_num
          unlabeled_fence_lines << line_num if fence_match[2].strip.empty?
          next
        elsif in_fence && raw_line.match?(/\A\s*#{Regexp.escape(fence_marker[0])}{#{fence_marker.length},}\s*\z/)
          in_fence = false
          fence_marker = nil
          fence_open_line = nil
          next
        elsif in_fence
          next
        end

        in_numbered_list = check_numbered_list_image_indentation(raw_line, stripped, line_num, in_numbered_list, issues)
        last_heading_level = check_line_headings_and_accessibility(
          raw_line, stripped, line_num, last_heading_level, issues
        )
      end

      if in_fence && fence_open_line
        issues << "[Markdown Syntax Error - Line #{fence_open_line}] Unclosed fenced code block " \
                  "(`#{fence_marker}` opened on line #{fence_open_line} is missing a closing `#{fence_marker}`), " \
                  "causing everything after line #{fence_open_line} to render as raw code."
      end

      return if unlabeled_fence_lines.empty?

      lines_label = unlabeled_fence_lines.first(5).join(", ")
      issues << "[Formatting Tip - Line #{lines_label}] Fenced code block (` ``` `) has no language identifier " \
                "(e.g. ```` ```javascript ```` or ```` ```bash ````). Adding a language name ensures immediate, " \
                "accurate syntax highlighting."
    end

    def check_numbered_list_image_indentation(raw_line, stripped, line_num, in_numbered_list, issues)
      return true if raw_line.match?(/\A\s*\d+\.\s+\S/)
      return in_numbered_list if stripped.empty?

      if in_numbered_list && raw_line.match?(/\A!\[[^\]]*\]\([^)]+\)/)
        issues << "[Formatting Tip - Line #{line_num}] Unindented image inside a numbered list will reset the " \
                  "following list item's number back to `1.`. Indent the image line by 4 spaces " \
                  "to keep list numbering continuous."
        return true
      end

      raw_line.start_with?("  ", "\t") ? in_numbered_list : false
    end

    def check_line_headings_and_accessibility(raw_line, stripped, line_num, last_heading_level, issues)
      line_without_inline_code = raw_line.gsub(/`[^`]*`/, "")

      if (heading_match = raw_line.match(/\A\s*(\#{1,6})\s+\S/))
        level = heading_match[1].length
        if level == 1
          issues << "[Accessibility Warning - Line #{line_num}] Level 1 heading (`# `) used in the body. " \
                    "Because the post title is already the page's `<h1>`, use `##` (`<h2>`) " \
                    "for top-level body sections."
        elsif last_heading_level.positive? && level > last_heading_level + 1
          expected_hashes = "#" * (last_heading_level + 1)
          issues << "[Accessibility Warning - Line #{line_num}] Heading level jumped from " \
                    "`<h#{last_heading_level}>` to `<h#{level}>` (`#{'#' * level}`). Increment headings " \
                    "by one level at a time (`#{expected_hashes}`) for screen reader navigation."
        end
        last_heading_level = level
      end

      check_line_images_and_links(line_without_inline_code, stripped, line_num, issues)
      last_heading_level
    end

    def check_line_images_and_links(line_without_inline_code, stripped, line_num, issues)
      if line_without_inline_code.match?(/!\[\s*image description\s*\]\([^)]+\)/i)
        issues << "[Accessibility Warning - Line #{line_num}] Image uses the default " \
                  "`![Image description](...)` placeholder, which is stripped on render. " \
                  "Replace `Image description` with descriptive alt text."
      elsif line_without_inline_code.match?(/!\[\s*\]\([^)]+\)/)
        issues << "[Accessibility Warning - Line #{line_num}] Image has empty alt text `![](...)`. " \
                  "Add descriptive alt text inside `[...]` for screen readers."
      end

      if line_without_inline_code.match?(%r{!?\[[^\]]+\]\s+\(https?://[^)]+\)})
        issues << "[Markdown Syntax Warning - Line #{line_num}] Space detected between `]` and `(` " \
                  "in `[text] (url)`, which prevents Markdown from rendering the link or image. " \
                  "Remove the space: `[text](url)`."
      end

      return unless stripped.present? && line_without_inline_code.match?(%r{(?<!!)\([^)\n]+\)\[https?://[^\]]+\]})

      issues << "[Markdown Syntax Warning - Line #{line_num}] Reversed link syntax `(text)[url]` detected. " \
                "Standard Markdown links use square brackets for text followed by parentheses for the URL: " \
                "`[text](url)`."
    end

    def mask_code_blocks_preserving_lines(text)
      in_fence = false
      fence_char = nil
      fence_len = 0

      text.lines.map do |raw_line|
        line = raw_line.chomp
        if !in_fence && (m = line.match(/\A\s*(`{3,}|~{3,})/))
          in_fence = true
          fence_char = m[1][0]
          fence_len = m[1].length
          "\n"
        elsif in_fence && line.match?(/\A\s*#{Regexp.escape(fence_char)}{#{fence_len},}\s*\z/)
          in_fence = false
          "\n"
        elsif in_fence
          "\n"
        else
          "#{line.gsub(/`[^`]*`/, '')}\n"
        end
      end.join
    end

    def detected_editor_version
      explicit = @article_state[:version].to_s.strip
      return explicit if %w[v1 v2].include?(explicit)
      return "v1" if @user&.setting&.editor_version == "v1"

      "v2"
    end

    def extract_tags_list(frontmatter_data = {})
      raw_tags = @article_state[:tags].presence ||
        @article_state[:tag_list].presence ||
        frontmatter_data["tags"] ||
        frontmatter_data["tag_list"]

      case raw_tags
      when Array
        raw_tags.map { |t| t.to_s.strip }.compact_blank
      when String
        raw_tags.split(/[,\s]+/).map(&:strip).compact_blank
      else
        []
      end
    end

    def admin_user?
      return false unless @user

      @user.respond_to?(:admin?) && (@user.admin? || @user.super_admin?)
    end

    def normalize_history(raw_history)
      Array(raw_history).filter_map do |entry|
        next unless entry.is_a?(Hash) || entry.respond_to?(:[])

        role = (entry[:role] || entry["role"]).to_s.strip
        text = (entry[:text] || entry["text"]).to_s
        next if role.blank? && text.blank?

        { role: role.presence || "user", text: text }
      end
    end

    def formatted_history
      @history.last(MAX_HISTORY_MESSAGES).map { |m| "#{m[:role].to_s.capitalize}: #{m[:text]}" }.join("\n")
    end

    def normalize_article_state(raw_state)
      return if raw_state.blank?

      hash = if raw_state.respond_to?(:to_unsafe_h)
               raw_state.to_unsafe_h
             elsif raw_state.respond_to?(:to_h)
               raw_state.to_h
             else
               {}
             end

      hash.with_indifferent_access
    end
  end
end
