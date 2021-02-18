@rails_post_6
Feature: channel spec

  Channel specs are marked by `:type => :channel` or if you have set
  `config.infer_spec_type_from_file_location!` by placing them in `spec/channels`.

  A channel spec is a thin wrapper for an `ActionCable::Channel::TestCase`, and includes all
  of the behavior and assertions that it provides, in addition to RSpec's own
  behavior and expectations.

  It also includes helpers from `ActionCable::Connection::TestCase` to make it possible to
  test connection behavior.

  Background:
    Given action cable testing is available
    And a file named "app/channels/chat_channel.rb" with:
      """ruby
      class ChatChannel < ApplicationCable::Channel
        def subscribed
          reject unless params[:room_id].present?
        end

        def speak(data)
          ActionCable.server.broadcast(
            "chat_#{params[:room_id]}", text: data['message']
          )
        end

        def echo(data)
          data.delete("action")
          transmit data
        end
      end
      """

  Scenario: simple passing example
    Given a file named "spec/channels/chat_channel_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ChatChannel, :type => :channel do
        it "successfully subscribes" do
          subscribe room_id: 42
          expect(subscription).to be_confirmed
        end
      end
      """
    When I run `rspec spec/channels/chat_channel_spec.rb`
    Then the example should pass

  Scenario: verifying that subscription is rejected
    Given a file named "spec/channels/chat_channel_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ChatChannel, :type => :channel do
        it "rejects subscription" do
          subscribe room_id: nil
          expect(subscription).to be_rejected
        end
      end
      """
    When I run `rspec spec/channels/chat_channel_spec.rb`
    Then the example should pass

  Scenario: performing actions and checking transmissions
    Given a file named "spec/channels/chat_channel_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ChatChannel, :type => :channel do
        it "successfully subscribes" do
          subscribe room_id: 42

          perform :echo, foo: 'bar'
          expect(transmissions.last).to eq('foo' => 'bar')
        end
      end
      """
    When I run `rspec spec/channels/chat_channel_spec.rb`
    Then the example should pass

  Scenario: successful connection with url params
    Given a file named "app/channels/application_cable/connection.rb" with:
      """ruby
      class ApplicationCable::Connection < ActionCable::Connection::Base
        identified_by :user_id

        def connect
          self.user_id = request.params[:user_id]
          reject_unauthorized_connection unless user_id.present?
        end
      end
      """
    And a file named "spec/channels/connection_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationCable::Connection, :type => :channel do
        it "successfully connects" do
          connect "/cable?user_id=323"
          expect(connection.user_id).to eq "323"
        end
      end
      """
    When I run `rspec spec/channels/connection_spec.rb`
    Then the example should pass

  Scenario: successful connection with cookies
    Given a file named "app/channels/application_cable/connection.rb" with:
      """ruby
      class ApplicationCable::Connection < ActionCable::Connection::Base
        identified_by :user_id

        def connect
          self.user_id = cookies.signed[:user_id]
          reject_unauthorized_connection unless user_id.present?
        end
      end
      """
    And a file named "spec/channels/connection_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationCable::Connection, :type => :channel do
        it "successfully connects" do
          cookies.signed[:user_id] = "324"

          connect "/cable"
          expect(connection.user_id).to eq "324"
        end
      end
      """
    When I run `rspec spec/channels/connection_spec.rb`
    Then the example should pass

  Scenario: successful connection with headers
    Given a file named "app/channels/application_cable/connection.rb" with:
      """ruby
      class ApplicationCable::Connection < ActionCable::Connection::Base
        identified_by :user_id

        def connect
          self.user_id = request.headers["x-user-id"]
          reject_unauthorized_connection unless user_id.present?
        end
      end
      """
    And a file named "spec/channels/connection_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationCable::Connection, :type => :channel do
        it "successfully connects" do
          connect "/cable", headers: { "X-USER-ID" => "325" }
          expect(connection.user_id).to eq "325"
        end
      end
      """
    When I run `rspec spec/channels/connection_spec.rb`
    Then the example should pass

  Scenario: rejected connection
    Given a file named "app/channels/application_cable/connection.rb" with:
      """ruby
      class ApplicationCable::Connection < ActionCable::Connection::Base
        identified_by :user_id

        def connect
          self.user_id = request.params[:user_id]
          reject_unauthorized_connection unless user_id.present?
        end
      end
      """
    And a file named "spec/channels/connection_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationCable::Connection, :type => :channel do
        it "rejects connection" do
          expect { connect "/cable?user_id=" }.to have_rejected_connection
        end
      end
      """
    When I run `rspec spec/channels/connection_spec.rb`
    Then the example should pass

  Scenario: disconnect connection
    Given a file named "app/channels/application_cable/connection.rb" with:
      """ruby
      class ApplicationCable::Connection < ActionCable::Connection::Base
        identified_by :user_id

        def connect
          self.user_id = request.params[:user_id]
          reject_unauthorized_connection unless user_id.present?
        end

        def disconnect
          $stdout.puts "User #{user_id} disconnected"
        end
      end
      """
    And a file named "spec/channels/connection_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationCable::Connection, :type => :channel do
        it "disconnects" do
          connect "/cable?user_id=42"
          expect { disconnect }.to output(/User 42 disconnected/).to_stdout
        end
      end
      """
    When I run `rspec spec/channels/connection_spec.rb`
    Then the example should pass
