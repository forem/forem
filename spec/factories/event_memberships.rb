FactoryBot.define do
  factory :event_membership do
    parent_event factory: %i[event], type_of: :conference
    child_event factory: %i[event], type_of: :live_stream
    sequence(:position) { |n| n }
    role { nil }
    featured { false }
  end
end
