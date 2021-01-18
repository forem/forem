# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160322223258) do
  create_table "companies", force: :cascade do |t|
    t.string "addr1"
    t.string "addr2"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "phone"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "zip"
  end

  add_index "companies", ["city"], name: "index_companies_on_city"
  add_index "companies", ["name"], name: "index_companies_on_name"
  add_index "companies", ["state"], name: "index_companies_on_state"

  create_table "people", force: :cascade do |t|
    t.integer "age"
    t.date "birthdate"
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
  end
end
