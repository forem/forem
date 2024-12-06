module Blazer
  class Upload < Record
    belongs_to :creator, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class

    validates :table, presence: true, uniqueness: true, format: {with: /\A[a-z0-9_]+\z/, message: "can only contain lowercase letters, numbers, and underscores"}, length: {maximum: 63}

    def table_name
      Blazer.uploads_table_name(table)
    end
  end
end
