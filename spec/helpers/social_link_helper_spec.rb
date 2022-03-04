require "rails_helper"

describe SocialLinkHelper do
  let(:user) { create(:user) }

  describe ".user_twitter_link" do
    let(:value) { helper.user_twitter_link(user) }

    context "when user has username" do
      it "returns link with handler" do
        expect(value).to include("@#{user.twitter_username}")
      end

      it "returns link to user" do
        expect(value).to include("https://twitter.com/#{user.twitter_username}")
      end
    end

    context "when user doesn't have a username" do
      before do
        allow(user).to receive(:twitter_username).and_return(nil)
      end

      it "returns N/A" do
        expect(value).to eq("N/A")
      end
    end
  end

  describe ".user_github_link" do
    let(:value) { helper.user_github_link(user) }

    context "when user has username" do
      it "returns link with handler" do
        expect(value).to include("@#{user.github_username}")
      end

      it "returns link to user" do
        expect(value).to include("https://github.com/#{user.github_username}")
      end
    end

    context "when user doesn't have a username" do
      before do
        allow(user).to receive(:github_username).and_return(nil)
      end

      it "returns N/A" do
        expect(value).to eq("N/A")
      end
    end
  end
end
