FactoryBot.define do
  factory :activesupport_event, class: "ActiveSupport::Notifications::Event" do
    name { "audit.log" }
    time { Timecop.freeze(Time.zone.now) }
    ending { time + 10.seconds }
    transaction_id { Faker::Crypto.md5 }
    payload { {} }

    initialize_with { new(name, time, ending, transaction_id, payload) }
  end
end
