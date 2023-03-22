require "rails_helper"

RSpec.describe Tweet, vcr: true do
  let(:tweet_id) { "1018911886862057472" }
  let(:tweet_reply_id) { "1242938461784608770" }
  let(:retweet_id) { "1262395854469677058" }

  it { is_expected.to validate_presence_of(:full_fetched_object_serialized) }

  describe ".find_or_fetch" do
    context "when retrieving a tweet", vcr: { cassette_name: "twitter_client_status_extended" } do
      it "saves a new tweet" do
        expect do
          described_class.find_or_fetch(tweet_id)
        end.to change(described_class, :count).by(1)
      end

      it "retrieves an existing tweet" do
        created_tweet = described_class.find_or_fetch(tweet_id)

        expect do
          found_tweet = described_class.find_or_fetch(tweet_id)
          expect(found_tweet.id).to eq(created_tweet.id)
        end.not_to change(described_class, :count)
      end

      it "saves the proper status ID and text" do
        tweet = described_class.find_or_fetch(tweet_id)

        status = tweet.full_fetched_object_serialized

        expect(tweet.text).to eq(status[:full_text])
        expect(tweet.twitter_id_code).to eq(status[:id_str])
      end

      it "saves the proper metadata attributes", :aggregate_failures do
        tweet = described_class.find_or_fetch(tweet_id)

        status = tweet.full_fetched_object_serialized

        expect(tweet.favorite_count).to eq(status[:favorite_count])
        expect(tweet.in_reply_to_status_id_code).to be_empty
        expect(tweet.in_reply_to_user_id_code).to be_empty
        expect(tweet.in_reply_to_username).to be_empty
        expect(tweet.is_quote_status).to be(false)
        expect(tweet.quoted_tweet_id_code).to eq(status[:quoted_status_id_str])
        expect(tweet.retweet_count).to eq(status[:retweet_count])
        expect(tweet.source).to eq(status[:source])
        expect(tweet.tweeted_at.to_i).to eq(Time.zone.parse(status[:created_at]).to_i)
      end

      it "saves the proper serializable attributes", :aggregate_failures do
        tweet = described_class.find_or_fetch(tweet_id)

        status = tweet.full_fetched_object_serialized
        expect(status).to be_present

        expect(tweet.extended_entities_serialized).to eq(status[:extended_entities])
        expect(tweet.hashtags_serialized).to eq(status[:entities][:hashtags])
        expect(tweet.media_serialized).to eq(status[:entities][:media])
        expect(tweet.mentioned_usernames_serialized).to be_empty
        expect(tweet.urls_serialized).to eq(status[:entities][:urls])
      end

      it "saves the proper user attributes", :aggregate_failures do
        tweet = described_class.find_or_fetch(tweet_id)

        status = tweet.full_fetched_object_serialized
        status_user = status[:user]

        expect(tweet.remote_profile_image_url.to_s).to eq(status_user[:profile_image_url])
        expect(tweet.twitter_name).to eq(status_user[:name])
        expect(tweet.twitter_uid).to eq(status_user[:id_str])
        expect(tweet.twitter_user_followers_count).to eq(status_user[:followers_count])
        expect(tweet.twitter_user_following_count).to eq(status_user[:friends_count])
        expect(tweet.twitter_username).to eq(status_user[:screen_name].downcase)
        expect(tweet.user_is_verified).to be(status_user[:verified])
      end

      it "sets #last_fetched_at" do
        tweet = described_class.find_or_fetch(tweet_id)
        expect(tweet.last_fetched_at).to be_present
      end

      it "is assigns to the existing user if the screen name corresponds" do
        user = create(:user, twitter_username: "ThePracticalDev")

        tweet = described_class.find_or_fetch(tweet_id)
        expect(tweet.user_id).to eq(user.id)
      end

      it "raises an error when Twitter key or secret are missing" do
        allow(TwitterClient::Client)
          .to receive(:status)
          .and_raise(TwitterClient::Errors::BadRequest, "Bad Authentication data.")

        expect do
          described_class.find_or_fetch(tweet_id)
        end.to raise_error(TwitterClient::Errors::BadRequest,
                           "Authentication error; please contact your Forem admin about possible missing Twitter keys")
      end
    end

    context "when retrieving non existent tweet", vcr: { cassette_name: "twitter_client_status_not_found_extended" } do
      it "raises an error if the tweet does not exist" do
        expect { described_class.find_or_fetch("0") }.to raise_error(TwitterClient::Errors::NotFound)
      end
    end

    context "when retrieving a reply tweet", vcr: { cassette_name: "twitter_client_status_reply_extended" } do
      it "saves a new tweet" do
        expect do
          described_class.find_or_fetch(tweet_reply_id)
        end.to change(described_class, :count).by(1)
      end

      it "retrieves an existing tweet" do
        created_tweet = described_class.find_or_fetch(tweet_reply_id)

        expect do
          found_tweet = described_class.find_or_fetch(tweet_reply_id)
          expect(found_tweet.id).to eq(created_tweet.id)
        end.not_to change(described_class, :count)
      end

      it "saves the proper reply fields" do
        tweet = described_class.find_or_fetch(tweet_reply_id)

        status = tweet.full_fetched_object_serialized

        expect(tweet.in_reply_to_status_id_code).to eq(status[:in_reply_to_status_id_str])
        expect(tweet.in_reply_to_user_id_code).to eq(status[:in_reply_to_user_id_str])
        expect(tweet.in_reply_to_username).to eq(status[:in_reply_to_screen_name])
      end
    end

    context "when retrieving a reply tweet", vcr: { cassette_name: "twitter_client_status_retweet_extended" } do
      it "saves a new tweet" do
        expect do
          described_class.find_or_fetch(retweet_id)
        end.to change(described_class, :count).by(1)
      end

      it "saves the proper status ID" do
        tweet = described_class.find_or_fetch(retweet_id)

        expect(tweet.twitter_id_code).not_to eq(retweet_id) # we fetch the original tweet
      end
    end
  end
end
