require 'spec_helper'
require 'timeout' #Need to use this avoid blocking

module FakeRedis
  describe "SubscriptionMethods" do
    before(:each) do
      @client = Redis.new
    end

    context "publish" do
      it "should add to channels" do
        expect(@client.publish("channel1", "val1")).to eq(0)
        expect(@client.publish("channel1", "val2")).to eq(0)
      end
    end

    context "subscribe" do
      it "should get all messages from a channel" do
        @client.publish("channel1", "val1")
        @client.publish("channel1", "val2")
        @client.publish("channel2", "val3")

        msgs = []
        subscribe_sent = unsubscribe_sent = false
        Timeout.timeout(1) do
          @client.subscribe("channel1") do |on|
            on.subscribe do |channel|
              subscribe_sent = true
              expect(channel).to eq("channel1")
            end

            on.message do |channel,msg|
              expect(channel).to eq("channel1")
              msgs << msg
            end

            on.unsubscribe do
              unsubscribe_sent = true
            end
          end
        end

        expect(msgs).to eq(["val1", "val2"])
        expect(subscribe_sent).to eq(true)
        expect(unsubscribe_sent).to eq(true)
      end

      it "should get all messages from multiple channels" do
        @client.publish("channel1", "val1")
        @client.publish("channel2", "val2")
        @client.publish("channel2", "val3")

        msgs = []
        Timeout.timeout(1) do
          @client.subscribe("channel1", "channel2") do |on|
            on.message do |channel,msg|
              msgs << [channel, msg]
            end
          end
        end

        expect(msgs[0]).to eq(["channel1", "val1"])
        expect(msgs[1]).to eq(["channel2", "val2"])
        expect(msgs[2]).to eq(["channel2", "val3"])
      end
    end

    context "unsubscribe" do
    end

    context "with patterns" do
      context "psubscribe" do
        it "should get all messages using pattern" do
          @client.publish("channel1", "val1")
          @client.publish("channel1", "val2")
          @client.publish("channel2", "val3")

          msgs = []
          subscribe_sent = unsubscribe_sent = false
          Timeout.timeout(1) do
            @client.psubscribe("channel*") do |on|
              on.psubscribe do |channel|
                subscribe_sent = true
              end

              on.pmessage do |pattern,channel,msg|
                expect(pattern).to eq("channel*")
                msgs << msg
              end

              on.punsubscribe do
                unsubscribe_sent = true
              end
            end
          end

          expect(msgs).to eq(["val1", "val2", "val3"])
          expect(subscribe_sent).to eq(true)
          expect(unsubscribe_sent).to eq(true)
        end
      end

      context "punsubscribe" do
      end
    end
  end
end
