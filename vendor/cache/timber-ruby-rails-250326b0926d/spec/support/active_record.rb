require 'active_record'
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
ActiveRecord::Schema.define do
  self.verbose = false

  create_table :organizations, :force => true do |t|
    t.string :name

    t.timestamps :null => false
  end

  create_table :users, :force => true do |t|
    t.integer :age
    t.string :email
    t.string :first_name

    t.timestamps :null => false
  end

end

class Organization < ::ActiveRecord::Base
end

class User < ::ActiveRecord::Base
end
