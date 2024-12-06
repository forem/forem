module Blazer
  class Dashboard < Record
    belongs_to :creator, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class
    has_many :dashboard_queries, dependent: :destroy
    has_many :queries, through: :dashboard_queries

    validates :name, presence: true

    def variables
      queries.flat_map { |q| q.variables }.uniq
    end

    def to_param
      [id, name.gsub("'", "").parameterize].join("-")
    end
  end
end
