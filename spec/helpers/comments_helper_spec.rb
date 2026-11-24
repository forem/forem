require "rails_helper"

RSpec.describe CommentsHelper do
  describe "#commenter_organization_membership" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }
    let(:article) { create(:article, organization: organization) }
    let(:comment) { create(:comment, user: user, commentable: article) }

    context "when commenter is a member of the organization" do
      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
      end

      it "returns the organization name" do
        expect(helper.commenter_organization_membership(comment, article)).to eq(organization.name)
      end
    end

    context "when commenter is an admin of the organization" do
      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
      end

      it "returns the organization name" do
        expect(helper.commenter_organization_membership(comment, article)).to eq(organization.name)
      end
    end

    context "when commenter is not a member of the organization" do
      it "returns nil" do
        expect(helper.commenter_organization_membership(comment, article)).to be_nil
      end
    end

    context "when article has no organization" do
      let(:article) { create(:article, organization: nil) }

      it "returns nil" do
        expect(helper.commenter_organization_membership(comment, article)).to be_nil
      end
    end

    context "when commentable is nil" do
      it "returns nil" do
        expect(helper.commenter_organization_membership(comment, nil)).to be_nil
      end
    end

    context "with preloaded associations" do
      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        create_list(:comment, 3, user: user, commentable: article)
      end

      it "works with preloaded organization_memberships" do
        # Load comments with preloaded associations (like Comments::Tree does)
        loaded_comments = article.comments.includes(user: %i[setting profile organization_memberships],
                                                    commentable: :organization)

        loaded_comments.each do |loaded_comment|
          result = helper.commenter_organization_membership(loaded_comment, article)
          expect(result).to eq(organization.name)
        end
      end
    end
  end

  describe "#article_comment_tree" do
    let(:article) { create(:article) }
    let(:comment) { create(:comment, commentable: article) }
    let(:preloaded_tree) { { comment => {} } }

    before do
      helper.define_singleton_method(:user_signed_in?) { false }
    end

    it "reuses a tree already loaded on the article with the same options" do
      allow(Comments::Tree).to receive(:for_commentable).and_return(preloaded_tree)
      article.comment_tree(limit: 10, order: "top", include_negative: false)

      expect(helper.article_comment_tree(article, 10, "top")).to eq(preloaded_tree)
      expect(Comments::Tree).to have_received(:for_commentable).once
    end

    it "loads a separate tree when the options differ" do
      allow(Comments::Tree).to receive(:for_commentable).and_return(preloaded_tree)
      article.comment_tree(limit: 10, order: "top", include_negative: false)

      helper.article_comment_tree(article, 10, "latest")

      expect(Comments::Tree).to have_received(:for_commentable)
        .with(article, limit: 10, order: "latest", include_negative: false)
      expect(Comments::Tree).to have_received(:for_commentable).twice
    end
  end

  describe "#any_negative_comments?" do
    let(:article) { create(:article) }

    it "returns false without querying comments when the article has no comments" do
      queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql] if payload[:sql].include?('"comments"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(helper.any_negative_comments?(article)).to be(false)
      end

      expect(queries).to be_empty
    end

    it "checks preloaded comments in memory without querying the database" do
      create(:comment, commentable: article, score: -5)
      article.reload
      article.comments.load

      queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql] if payload[:sql].include?('"comments"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(helper.any_negative_comments?(article)).to be(true)
      end

      expect(queries).to be_empty
    end

    it "reuses the negative comment check recorded by Comments::Tree.for_commentable without querying the database" do
      create(:comment, commentable: article, score: -5)
      article.reload
      Comments::Tree.for_commentable(article, include_negative: false)

      queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql] if payload[:sql].include?('"comments"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(helper.any_negative_comments?(article)).to be(true)
        expect(helper.any_negative_comments?(article.decorate)).to be(true)
      end

      expect(queries).to be_empty
    end

    it "queries the database once and memoizes when an unloaded comment has a negative score" do
      create(:comment, commentable: article, score: -5)
      article.reload

      expect(helper.any_negative_comments?(article)).to be(true)
    end

    it "queries the database and returns false when all unloaded comments have non-negative scores" do
      create(:comment, commentable: article, score: 5)
      article.reload

      expect(helper.any_negative_comments?(article)).to be(false)
    end
  end

  describe "#sanitized_text_preview" do
    let(:article_html) do
      paragraph = %(<p>Rust &amp; Ruby <a href="https://dev.to/a?b=1&amp;c=2">link</a> caf&eacute; "it's" 😀</p>\n)
      svg = %(<svg viewBox="0 0 24 24"><title>Enter fullscreen mode</title><path d="M0 0"></path></svg>\n)
      "#{paragraph}<pre><code>a &lt; b</code></pre>\n#{svg}" * 10
    end

    def legacy_preview(html, length)
      helper.truncate(helper.sanitize(html, tags: []), length: length)
    end

    it "matches truncate(sanitize(html, tags: [])) for previews that fit and that are truncated" do
      lengths = [3, 20, 150, 200, 10_000]
      ["", "short <b>text</b>", "<p>a &amp; b</p>", article_html].each do |html|
        lengths.each do |length|
          preview = helper.sanitized_text_preview(html, length: length)

          expect(preview).to eq(legacy_preview(html, length)), "#{html.inspect} length #{length}"
          expect(preview).to be_html_safe
        end
      end
    end

    it "takes the native fast path without parsing the HTML in Ruby" do
      allow(helper).to receive(:sanitize).and_call_original

      expect(helper.sanitized_text_preview(article_html, length: 150)).to include("Rust &amp;amp; Ruby")
      expect(helper).not_to have_received(:sanitize)
    end

    it "falls back to the ActionView helpers for HTML outside the native fast path" do
      allow(helper).to receive(:sanitize).and_call_original

      ["<math><mi>x</mi></math><p>#{'a' * 300}</p>", "<svg><g><svg></g></svg>visible</svg>"].each do |html|
        expect(ForemNative.sanitized_text_preview(html, 150)).to be_nil
        expect(helper.sanitized_text_preview(html, length: 150)).to eq(legacy_preview(html, 150))
      end

      expect(helper.sanitized_text_preview("<svg><g><svg></g></svg>visible</svg>", length: 150)).to eq("visible")
      expect(helper).to have_received(:sanitize).at_least(4).times
    end

    it "renders only text nodes inside an HTML container for fitting and truncated previews" do
      lengths = [15, 150, 10_000]
      samples = [
        "<p><img src=x onerror=alert(1)>Hello &lt;script&gt;alert(1)&lt;/script&gt;</p>",
        "<script>alert('xss')</script><p>\"quoted\" &amp; <b>bold</b></p>",
        article_html,
      ]

      samples.each do |html|
        lengths.each do |length|
          preview = helper.sanitized_text_preview(html, length: length)
          fragment = Nokogiri::HTML5.fragment("<div>#{preview}</div>")
          container = fragment.at_css("div")

          expect(container.children).to all(be_text), "#{html.inspect} length #{length}"
        end
      end
    end

    it "returns nil for nil HTML like truncate(sanitize(nil))" do
      expect(helper.sanitized_text_preview(nil, length: 150)).to be_nil
    end
  end

  describe "#nested_comments" do
    let(:organization) { create(:organization, name: "Forem & Co <Test>") }
    let(:author_user) { create(:user, name: "Alice <Author> & Co") }
    let(:replier_user) { create(:user, name: "Bob \"Replier\" O'Connor") }
    let(:staff_user) { create(:user, name: "Staff User") }
    let(:article) { create(:article, user: author_user, organization: organization, tags: "ama, ruby") }

    before do
      allow(InlineSvg::IdGenerator::Randomness).to receive(:call).and_return("fixed")
      helper.define_singleton_method(:user_signed_in?) { false }

      author_user.setting.update_columns(brand_color1: "#123456", display_email_on_profile: true)
      Profile.find_or_create_by!(user: author_user).update_columns(
        summary: "Hello & welcome <world> " * 12,
        location: "NYC & SF",
      )
      author_user.reload

      replier_user.setting.update_columns(brand_color1: "", display_email_on_profile: false)
      Profile.find_or_create_by!(user: replier_user).update_columns(
        summary: "Short bio",
        location: "",
      )
      create(:organization_membership, user: replier_user, organization: organization, type_of_user: "member")
      replier_user.add_role(:base_subscriber)
      replier_user.add_role(:tag_moderator)
      replier_user.reload

      Profile.find_or_create_by!(user: staff_user)
      staff_user.reload
      allow(User).to receive(:staff_account).and_return(staff_user)
    end

    it "matches legacy_nested_comments byte-for-byte across nested depths, badges, quality markers, and billboards" do
      c1 = create(
        :comment,
        user: author_user,
        commentable: article,
        body_markdown: "Root comment by OP with [link](https://example.com) & special chars",
        score: 10,
        public_reactions_count: 5,
        ai_disclosure_level: :some_ai,
      )
      c2 = create(
        :comment,
        user: replier_user,
        commentable: article,
        parent: c1,
        body_markdown: "Child comment at depth 1",
        score: 2,
        public_reactions_count: 1,
        edited_at: 1.hour.ago,
        favorited_by_user_id: author_user.id,
        ai_disclosure_level: :fully_autonomous,
      )
      c3 = create(
        :comment,
        user: staff_user,
        commentable: article,
        parent: c2,
        body_markdown: "Grandchild comment at depth 2, low quality",
        score: -100,
        public_reactions_count: 0,
        created_at: 2.years.ago,
        ai_disclosure_level: :no_ai,
      )
      c4 = create(
        :comment,
        user: author_user,
        commentable: article,
        parent: c3,
        body_markdown: "Depth 3 comment, hidden by author",
        hidden_by_commentable_user: true,
        score: 0,
      )
      c5 = create(
        :comment,
        user: replier_user,
        commentable: article,
        parent: c4,
        body_markdown: "Depth 4 comment with podcastliquidtag and tweet-embed",
        score: 5,
      )
      c5.update_column(
        :processed_html,
        "<p class=\"podcastliquidtag\">Audio</p><div class=\"tweet-embed\">Tweet</div>" \
        "<img src=\"https://res.cloudinary.com/practicaldev/image/fetch/test.png\">",
      )

      c_deleted_with_child = create(
        :comment,
        user: replier_user,
        commentable: article,
        body_markdown: "Deleted parent",
        deleted: true,
      )
      c_child_of_deleted = create(
        :comment,
        user: author_user,
        commentable: article,
        parent: c_deleted_with_child,
        body_markdown: "Reply to deleted parent",
      )
      c_deleted_leaf = create(
        :comment,
        user: replier_user,
        commentable: article,
        body_markdown: "Deleted leaf",
        deleted: true,
      )
      c_super_low_leaf = create(
        :comment,
        user: replier_user,
        commentable: article,
        body_markdown: "Spam <a href='http://spam.example'>link</a>",
        score: -100,
      )
      extra_roots = Array.new(5) do |idx|
        create(
          :comment,
          user: idx.even? ? author_user : replier_user,
          commentable: article,
          body_markdown: "Extra root comment #{idx}",
          score: idx,
        )
      end

      tree = {
        c1 => { c2 => { c3 => { c4 => { c5 => {} } } } },
        c_deleted_with_child => { c_child_of_deleted => {} },
        c_deleted_leaf => {},
        c_super_low_leaf => {}
      }
      extra_roots.each { |er| tree[er] = {} }

      allow(FeatureFlag).to receive(:enabled?).and_call_original
      allow(FeatureFlag).to receive(:enabled?).with(:community_favorites).and_return(true)

      [false, true].each do |is_admin|
        [false, true].each do |is_view_root|
          [false, true].each do |discussion_lock|
            [nil, c1, c4].each do |root_comment|
              helper.instance_variable_set(:@article, article)
              helper.instance_variable_set(:@discussion_lock, discussion_lock)
              helper.instance_variable_set(:@root_comment, root_comment)
              helper.instance_variable_set(:@comments_to_show_count, 50)

              helper.instance_variable_set(:@current_comment_index, 0)
              helper.instance_variable_set(:@shown_billboard, false)
              native_html = helper.__send__(
                :native_nested_comments,
                tree: tree,
                commentable: article,
                is_view_root: is_view_root,
                is_admin: is_admin,
              )
              native_idx = helper.instance_variable_get(:@current_comment_index)
              native_bb = helper.instance_variable_get(:@shown_billboard)

              helper.instance_variable_set(:@current_comment_index, 0)
              helper.instance_variable_set(:@shown_billboard, false)
              legacy_html = helper.__send__(
                :legacy_nested_comments,
                tree: tree,
                commentable: article,
                is_view_root: is_view_root,
                is_admin: is_admin,
              )
              legacy_idx = helper.instance_variable_get(:@current_comment_index)
              legacy_bb = helper.instance_variable_get(:@shown_billboard)

              expect(native_html).not_to be_nil
              expect(native_html).to be_html_safe
              expect(native_html).to eq(legacy_html),
                                     "HTML mismatch for admin=#{is_admin} root=#{is_view_root} lock=#{discussion_lock}"
              expect(native_idx).to eq(legacy_idx)
              expect(native_bb).to eq(legacy_bb)
            end
          end
        end
      end
    end

    it "renders multiple root threads identically together or separately", :aggregate_failures do
      roots = Array.new(3) { create(:comment, user: author_user, commentable: article) }
      reply = create(:comment, user: replier_user, commentable: article, parent: roots.first)
      tree = { roots[0] => { reply => {} }, roots[1] => {}, roots[2] => {} }
      helper.instance_variable_set(:@article, article)

      [false, true].each do |legacy|
        allow(ForemNative).to receive(:render_comment_tree).and_return(nil) if legacy
        separate = tree.map do |root, children|
          helper.nested_comments(tree: { root => children }, commentable: article, is_view_root: true)
        end.join

        combined = helper.nested_comments(tree: tree, commentable: article, is_view_root: true)

        expect(combined).to eq(separate)
        expect(combined).to be_html_safe
      end
    end

    it "returns an empty html_safe string for an empty comment tree" do
      result = helper.nested_comments(tree: {}, commentable: article, is_view_root: true, is_admin: false)
      expect(result).to eq("")
      expect(result).to be_html_safe
    end

    it "falls back to legacy_nested_comments when ForemNative.render_comment_tree returns nil" do
      comment = create(:comment, user: author_user, commentable: article)
      tree = { comment => {} }
      helper.instance_variable_set(:@article, article)

      expected = helper.__send__(
        :legacy_nested_comments,
        tree: tree,
        commentable: article,
        is_view_root: true,
        is_admin: false,
      )
      allow(ForemNative).to receive(:render_comment_tree).and_return(nil)

      actual = helper.nested_comments(tree: tree, commentable: article, is_view_root: true, is_admin: false)
      expect(actual).to eq(expected)
    end
  end
end
