ActiveRecord::Schema.define do
  self.verbose = false

  [ :roles, :privileges, :admin_rights ].each do |table|
    create_table(table) do |t|
    t.string :name
    t.references :resource, :polymorphic => true

    t.timestamps null: false
    end
  end

  [ :users, :human_resources, :customers, :admin_moderators, :strict_users ].each do |table|
    create_table(table) do |t|
      t.string :login
    end
  end

  create_table(:users_roles, :id => false) do |t|
    t.references :user
    t.references :role
  end

  create_table(:strict_users_roles, :id => false) do |t|
    t.references :strict_user
    t.references :role
  end

  create_table(:human_resources_roles, :id => false) do |t|
    t.references :human_resource
    t.references :role
  end

  create_table(:customers_privileges, :id => false) do |t|
    t.references :customer
    t.references :privilege
  end

  create_table(:moderators_rights, :id => false) do |t|
    t.references :moderator
    t.references :right
  end

  create_table(:forums) do |t|
    t.string :name
  end

  create_table(:groups) do |t|
    t.integer :parent_id
    t.string :name
  end

  create_table(:teams, :id => false) do |t|
    t.primary_key :team_code
    t.string :name
  end

  create_table(:organizations) do |t|
    t.string :type
  end
end
