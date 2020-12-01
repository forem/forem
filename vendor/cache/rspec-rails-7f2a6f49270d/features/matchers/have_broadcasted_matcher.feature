@rails_post_6
Feature: have_broadcasted matcher

  The `have_broadcasted_to` (also aliased as `broadcast_to`) matcher is used
  to check if a message has been broadcasted to a given stream.

  Background:
    Given action cable testing is available

  Scenario: Checking stream name
    Given a file named "spec/models/broadcaster_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "broadcasting" do
        it "matches with stream name" do
          expect {
            ActionCable.server.broadcast(
              "notifications", { text: "Hello!" }
            )
          }.to have_broadcasted_to("notifications")
        end
      end
      """
    When I run `rspec spec/models/broadcaster_spec.rb`
    Then the examples should all pass

  Scenario: Checking passed message to stream
    Given a file named "spec/models/broadcaster_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "broadcasting" do
        it "matches with message" do
          expect {
            ActionCable.server.broadcast(
              "notifications", { text: "Hello!" }
            )
          }.to have_broadcasted_to("notifications").with(text: 'Hello!')
        end
      end
      """
    When I run `rspec spec/models/broadcaster_spec.rb`
    Then the examples should all pass

  Scenario: Checking that message passed to stream matches
    Given a file named "spec/models/broadcaster_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "broadcasting" do
        it "matches with message" do
          expect {
            ActionCable.server.broadcast(
              "notifications", { text: 'Hello!', user_id: 12 }
            )
          }.to have_broadcasted_to("notifications").with(a_hash_including(text: 'Hello!'))
        end
      end
      """
    When I run `rspec spec/models/broadcaster_spec.rb`
    Then the examples should all pass

  Scenario: Checking passed message with block
    Given a file named "spec/models/broadcaster_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "broadcasting" do
        it "matches with message" do
          expect {
            ActionCable.server.broadcast(
              "notifications", { text: 'Hello!', user_id: 12 }
            )
          }.to have_broadcasted_to("notifications").with { |data|
            expect(data['user_id']).to eq 12
          }
        end
      end
      """
    When I run `rspec spec/models/broadcaster_spec.rb`
    Then the examples should all pass

  Scenario: Using alias method
    Given a file named "spec/models/broadcaster_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "broadcasting" do
        it "matches with stream name" do
          expect {
            ActionCable.server.broadcast(
              "notifications", { text: 'Hello!' }
            )
          }.to broadcast_to("notifications")
        end
      end
      """
    When I run `rspec spec/models/broadcaster_spec.rb`
    Then the examples should all pass

  Scenario: Checking broadcast to a record
    Given a file named "spec/channels/chat_channel_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ChatChannel, type: :channel do
        it "successfully subscribes" do
          user = User.new(42)

          expect {
            ChatChannel.broadcast_to(user, text: 'Hi')
          }.to have_broadcasted_to(user)
        end
      end
      """
    And a file named "app/models/user.rb" with:
      """ruby
      class User < Struct.new(:name)
        def to_gid_param
          name
        end
      end
      """
    When I run `rspec spec/channels/chat_channel_spec.rb`
    Then the example should pass

  Scenario: Checking broadcast to a record in non-channel spec
    Given a file named "spec/models/broadcaster_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "broadcasting" do
        it "matches with stream name" do
          user = User.new(42)

          expect {
            ChatChannel.broadcast_to(user, text: 'Hi')
          }.to broadcast_to(ChatChannel.broadcasting_for(user))
        end
      end
      """
    And a file named "app/models/user.rb" with:
      """ruby
      class User < Struct.new(:name)
        def to_gid_param
          name
        end
      end
      """
    When I run `rspec spec/models/broadcaster_spec.rb`
    Then the example should pass
