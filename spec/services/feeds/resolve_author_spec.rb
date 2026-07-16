require "rails_helper"

RSpec.describe Feeds::ResolveAuthor do
  let(:feed_owner) { create(:user) }
  let(:feed_source) { build(:feed_source, user: feed_owner) }

  before do
    allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
  end

  def item_with_author(author_string)
    double("FeedItem", author: author_string)
  end

  describe ".call" do
    context "when feed source has an organization" do
      let(:organization) { create(:organization) }
      let(:feed_source) do
        create(:organization_membership, user: feed_owner, organization: organization, type_of_user: "admin")
        build(:feed_source, user: feed_owner, organization: organization)
      end

      context "when RSS author matches an org member by email" do
        it "returns the matched org member" do
          org_member = create(:user, email: "alice@example.com")
          create(:organization_membership, user: org_member, organization: organization)
          item = item_with_author("alice@example.com")

          result = described_class.call(item, feed_source)
          expect(result).to eq(org_member)
        end

        it "extracts email from 'Name <email>' format" do
          org_member = create(:user, email: "bob@example.com")
          create(:organization_membership, user: org_member, organization: organization)
          item = item_with_author("Bob Smith <bob@example.com>")

          result = described_class.call(item, feed_source)
          expect(result).to eq(org_member)
        end
      end

      context "when RSS author matches an org member by name" do
        it "returns the matched org member" do
          org_member = create(:user, name: "Alice Johnson")
          create(:organization_membership, user: org_member, organization: organization)
          item = item_with_author("Alice Johnson")

          result = described_class.call(item, feed_source)
          expect(result).to eq(org_member)
        end

        it "strips email and matches by name" do
          org_member = create(:user, name: "Bob Smith")
          create(:organization_membership, user: org_member, organization: organization)
          item = item_with_author("Bob Smith <unknown@other.com>")

          result = described_class.call(item, feed_source)
          expect(result).to eq(org_member)
        end
      end

      context "when RSS author matches a user outside the organization" do
        it "does not match and falls back to feed source effective author" do
          _outsider = create(:user, name: "Alice Johnson", email: "alice@example.com")
          item = item_with_author("Alice Johnson")

          result = described_class.call(item, feed_source)
          expect(result).to eq(feed_owner)
        end

        it "does not match by email for non-org users" do
          _outsider = create(:user, email: "outsider@example.com")
          item = item_with_author("outsider@example.com")

          result = described_class.call(item, feed_source)
          expect(result).to eq(feed_owner)
        end
      end
    end

    context "when feed source has no organization" do
      it "matches the feed owner by email" do
        item = item_with_author(feed_owner.email)

        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end

      it "matches the feed owner by name" do
        item = item_with_author(feed_owner.name)

        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end

      it "does not match a different user with the same name" do
        _other_user = create(:user, name: "Same Name")
        feed_owner.update!(name: "Different Name")
        item = item_with_author("Same Name")

        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end

      it "does not match a different user by email" do
        _other_user = create(:user, email: "other@example.com")
        item = item_with_author("other@example.com")

        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end
    end

    context "when RSS author does not match any user" do
      it "falls back to feed source default author" do
        default_author = create(:user)
        feed_source.author = default_author

        item = item_with_author("Unknown Person")
        result = described_class.call(item, feed_source)
        expect(result).to eq(default_author)
      end

      it "falls back to feed source owner when no default author" do
        item = item_with_author("Unknown Person")
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end
    end

    context "when RSS item has no author" do
      it "returns feed source effective author" do
        item = item_with_author(nil)
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end

      it "returns feed source effective author for blank author" do
        item = item_with_author("  ")
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end
    end

    context "when item does not respond to author" do
      it "returns feed source effective author" do
        item = double("FeedItem")
        allow(item).to receive(:try).with(:author).and_return(nil)
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end
    end

    context "with Medium-style dc:creator author names (regression for #22953)" do
      it "does not misattribute to a same-named user on an unrelated feed" do
        # Medium feeds always include dc:creator with the author's display name.
        # Before the scoping fix, a name collision would silently assign the
        # article to an unrelated platform user.
        _colliding_user = create(:user, name: "Vaidehi Joshi")
        feed_owner.update!(name: "Different Person")
        item = item_with_author("Vaidehi Joshi")

        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end

      it "matches the correct org member when names collide across orgs" do
        organization = create(:organization)
        create(:organization_membership, user: feed_owner, organization: organization, type_of_user: "admin")
        org_feed_source = build(:feed_source, user: feed_owner, organization: organization)

        org_member = create(:user, name: "Vaidehi Joshi")
        create(:organization_membership, user: org_member, organization: organization)

        _other_user_same_name = create(:user, name: "Vaidehi Joshi")

        item = item_with_author("Vaidehi Joshi")
        result = described_class.call(item, org_feed_source)
        expect(result).to eq(org_member)
      end
    end
  end
end
