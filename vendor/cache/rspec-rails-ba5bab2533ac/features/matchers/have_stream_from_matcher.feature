@rails_post_6
Feature: have_stream_from matcher

  The `have_stream_from` matcher is used to check if a channel has been subscribed to a given stream specified as a String.
  If you use `stream_for` in you channel to subscribe to a model, use `have_stream_for` matcher instead.

  The `have_no_streams` matcher is used to check if a channe hasn't been subscribed to any stream.

  It is available only in channel specs.

  Background:
    Given action cable testing is available

    And a file named "app/channels/chat_channel.rb" with:
      """ruby
      class ChatChannel < ApplicationCable::Channel
        def subscribed
          reject unless params[:room_id].present?

          stream_from "chat_#{params[:room_id]}"
        end

        def leave
          stop_all_streams
        end
      end
      """

  Scenario: subscribing with params and checking streams
    Given a file named "spec/channels/chat_channel_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ChatChannel, :type => :channel do
        it "successfully subscribes" do
          subscribe room_id: 42

          expect(subscription).to be_confirmed
          expect(subscription).to have_stream_from("chat_42")
        end
      end
      """
    When I run `rspec spec/channels/chat_channel_spec.rb`
    Then the example should pass

  Scenario: stopping all streams
    Given a file named "spec/channels/chat_channel_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ChatChannel, :type => :channel do
        it "successfully subscribes" do
          subscribe(room_id: 42)

          expect(subscription).to have_stream_from("chat_42")

          perform :leave
          expect(subscription).not_to have_streams
        end
      end
      """
    When I run `rspec spec/channels/chat_channel_spec.rb`
    Then the example should pass

  Scenario: subscribing and checking streams for models
    Given a file named "app/channels/notifications_channel.rb" with:
      """ruby
      class NotificationsChannel < ApplicationCable::Channel
        def subscribed
          stream_for current_user
        end
      end
      """
    And a file named "app/channels/application_cable/connection.rb" with:
      """ruby
      class ApplicationCable::Connection < ActionCable::Connection::Base
        identified_by :current_user
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
    And a file named "spec/channels/user_channel_spec.rb" with:
      """ruby
      require "rails_helper"
      RSpec.describe NotificationsChannel, :type => :channel do
        it "successfully subscribes to user's stream" do
          stub_connection current_user: User.new(42)
          subscribe
          expect(subscription).to be_confirmed
          expect(subscription).to have_stream_for(User.new(42))
        end
      end
      """
    When I run `rspec spec/channels/user_channel_spec.rb`
    Then the example should pass
