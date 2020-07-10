FactoryBot.define do
  factory :ahoy_message, class: "Ahoy::Message" do
    user
  end

  factory :ahoy_visit, class: "Ahoy::Visit" do
    user
    started_at { Timecop.freeze(Time.zone.now) }
  end

  factory :ahoy_event, class: "Ahoy::Event" do
    user
    visit { create(:ahoy_visit, user: user) } # Ahoy::Events require an Ahoy::Visit
    time { Timecop.freeze(Time.zone.now) }
    name { "Clicked Welcome Notification" }
    properties { { title: "welcome_notification_welcome_thread" } }
  end
end
