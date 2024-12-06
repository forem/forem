class Ahoy::Event
  include Mongoid::Document

  # associations
  belongs_to :visit, class_name: "Ahoy::Visit", index: true
  belongs_to :user, index: true, optional: true

  # fields
  field :name, type: String
  field :properties, type: Hash
  field :time, type: Time

  index({name: 1, time: 1})
end
