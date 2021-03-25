require 'spec_helper'

describe Buffer::Client do
  let(:client) { Buffer::Client.new("some_token") }
  let(:profile_id) { "4eb854340acb04e870000010" }
  let(:id) { "4eb8565e0acb04bb82000004" }

  describe "updates" do
    describe "#update_by_id" do

      before do
        stub_request(:get, "https://api.bufferapp.com/1/updates/#{ id }.json?access_token=some_token").
                 to_return(fixture("update_by_id.txt"))
      end
      it "fails without an id" do
        lambda {
          update = client.update_by_id}.
          should raise_error(ArgumentError)
      end

      it "connects to the correct endpoint" do
        client.update_by_id(id)
      end

      it "returns a well formed update rash" do
        client.update_by_id(id).sent_at.should eq(1320744001)
      end

    end


    describe "#updates_by_profile_id" do
      it "requires an id arg" do
        lambda { client.updates_by_profile_id }.
          should raise_error(ArgumentError)
      end

      it "fails without a :status arg" do
        lambda { client.updates_by_profile_id(profile_id)}.
          should raise_error(Buffer::Error::MissingStatus)
      end

      it "connects to the correct endpoint" do
        url = "https://api.bufferapp.com/1/profiles/4eb854340acb04e870000010/updates/pending.json?access_token=some_token"

        stub_request(:get, url).
          to_return(fixture('updates_by_profile_id_pending.txt'))
        client.updates_by_profile_id(profile_id, status: :pending).
          total.should eq(1)
      end

      it "utilizes the optional params" do
        url = "https://api.bufferapp.com/1/profiles/4eb854340acb04e870000010/updates/pending.json?access_token=some_token&count=3&page=2"

        stub_request(:get, url).
          to_return(fixture('updates_by_profile_id_pending.txt'))
        client.updates_by_profile_id(profile_id, status: :pending, page: 2, count: 3).
          total.should eq(1)
      end
    end

    describe "#interactions_by_update_id" do
      let(:url) { "https://api.bufferapp.com/1/updates/4ecda476542f7ee521000006/interactions.json?access_token=some_token&page=2" }
      let(:id) { "4ecda476542f7ee521000006" }

      before do
        stub_request(:get, url).
          to_return(fixture("interactions_by_update_id.txt"))
      end

      it "requires an id" do
        lambda { client.interactions_by_update_id(page: 2) }.
          should raise_error(Buffer::Error::InvalidIdLength)
      end

      it "allows optional params" do
        response =<<EOF
{
    "total":2,
    "interactions":[
        {
            "_id":"50f98310c5ac415d7f2e74fd",
            "created_at":1358509258,
            "event":"favorite",
            "id":"50f98310c5ac415d7f2e74fd",
            "interaction_id":"292235127847788544",
            "user":{
                "username":"Crispy Potatoes",
                "followers":160,
                "avatar":"http:\/\/si0.twimg.com\/profile_images\/...",
                "avatar_https":"https:\/\/si0.twimg.com\/profile_images\/...",
                "twitter_id":"70712344376"
            }
        },
        {
            "_id":"50f8623ac5ac415d7f1d4f77",
            "created_at":1358454592,
            "event":"retweet",
            "id":"50f8623ac5ac415d7f1d4f77",
            "interaction_id":"292005842654461953",
            "user":{
                "username":"Lucky Number 8",
                "followers":36079,
                "avatar":"http:\/\/si0.twimg.com\/profile_images\/2901468678\/...",
                "avatar_https":"https:\/\/si0.twimg.com\/profile_images\/2901468678\/...",
                "twitter_id":"1423444249"
            }
        }
    ]
}
EOF
        stub_request(:get, "https://api.bufferapp.com/1/updates/4ecda476542f7ee521000006/interactions.json?access_token=some_token&count=3&event=favorite&page=2").
           with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.1'}).
           to_return(:status => 200, :body => response, :headers => {})
        client.interactions_by_update_id(id, page: 2, count: 3, event: "favorite")
      end
    end

    describe "#check_id" do
      it "fails if id is not 24 chars" do
        stub_request(:get, "https://api.bufferapp.com/1/updates/4eb8565e0acb04bb82000004X.json?access_token=some_token").
                 to_return(:status => 200, :body => "", :headers => {})
        id = "4eb8565e0acb04bb82000004X"
        lambda { client.update_by_id(id) }.
          should raise_error(Buffer::Error::InvalidIdLength)
      end

      it "fails if id is not numbers and a-f" do
        stub_request(:get, "https://api.bufferapp.com/1/updates/4eb8565e0acb04bb8200000X.json?access_token=some_token").
                 to_return(:status => 200, :body => "", :headers => {})
        id = "4eb8565e0acb04bb8200000X"
        lambda { client.update_by_id(id) }.
          should raise_error(Buffer::Error::InvalidIdContent)
      end
    end

    describe "#reorder_updates" do
      it "connects to appropriate endpoint" do
        id_no = "4ecda256512f7ee521000001"
        order_hash = { order: [id_no, id_no, id_no] }
        stub_request(:post, %r{https://api\.bufferapp\.com/1/profiles/4ecda256512f7ee521000001/updates/reorder\.json\?access_token=.*}).
                   with(:body => {"order"=>["4ecda256512f7ee521000001", "4ecda256512f7ee521000001", "4ecda256512f7ee521000001"]},
                        :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Faraday v0.9.1'}).
                   to_return(:status => 200, :body => reorder_updates_body_response, :headers => {})
        client.reorder_updates(id_no, order_hash)
      end
    end

    describe "#shuffle_updates" do
      it "connects to appropriate endpoint" do
        id_no = "4ecda256512f7ee521000001"
        stub_request(:post, %r{https://api\.bufferapp\.com/1/profiles/4ecda256512f7ee521000001/updates/shuffle\.json\?access_token=.*}).
           with(:body => {"count"=>"10"}).
           to_return(:status => 200, :body => '{"success": true,
                                                "updates": [],
                                                "time_to_shuffle":0.0041220188140869}')
        client.shuffle_updates(id_no, count: 10)
      end
    end

    describe "#share_update" do
      it "should connect to correct endpoint" do
        stub_request(:post, %r{https://api\.bufferapp\.com/1/updates/4ecda256512f7ee521000001/share\.json\?access_token=.*}).
           to_return(:status => 200, :body => '{"success": true}', :headers => {})
        update_id = "4ecda256512f7ee521000001"
        client.share_update(update_id)
      end
    end

    describe "#create_update" do

      let(:body_content) do {text: "Text for an update",
                                 profile_ids: [
                  "4eb854340acb04e870000010",
                  "4eb9276e0acb04bb81000067"
                  ]}
      end

      let(:url) { %r{https://api\.bufferapp\.com/1/updates/create\.json\?access_token=.*} }

      context "should create an update" do
        it "when only required params are present" do
          stub_request(:post, url).
            with(:body => body_content).
             to_return(:status => 200, :body => create_update_return_body, :headers => {})
          client.create_update(body: body_content)
        end
        it "when optional params are included" do
          body_content[:media] = {}
          body_content[:media][:link] = "http://google.com"
          body_content[:media][:description] = "Google Homepage"
          stub_request(:post, url).
            with(:body => body_content).
             to_return(:status => 200, :body => create_update_return_body, :headers => {})
          client.create_update(body: body_content)

        end
      end
    end

    describe "#modify_update_text" do

      let(:body_content) { {text: "Text for an updated text for update"} }

      id = "4ecda256512f7ee521000004"
      let(:url) { %r{https://api\.bufferapp\.com/1/updates/#{ id }/update\.json\?access_token=.*} }

      context "should modify an update" do
        it "when params are present" do
          stub_request(:post, url).
            with(:body => body_content).
             to_return(:status => 200, :body => modify_update_response, :headers => {})
          client.modify_update_text(id, body: body_content)
        end
      end
    end

    describe "#destroy_update" do
      it "connects to correct endpoint" do
        stub_request(:post, %r{https://api\.bufferapp\.com/1/updates/4ecda256512f7ee521000001/destroy\.json\?access_token=.*}).
           to_return(fixture('destroy.txt'))
             update_id = "4ecda256512f7ee521000001"
        client.destroy_update(update_id)
      end
    end
  end
end
