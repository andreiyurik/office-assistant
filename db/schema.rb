# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_15_170003) do
  create_table "resources", force: :cascade do |t|
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.integer "grid_col"
    t.integer "grid_row"
    t.string "kind", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "zone_id", null: false
    t.index ["grid_row", "grid_col"], name: "index_desks_on_grid_cell", unique: true, where: "kind = 'desk'"
    t.index ["kind"], name: "index_resources_on_kind"
    t.index ["zone_id"], name: "index_resources_on_zone_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "zone_id", null: false
    t.index ["zone_id"], name: "index_teams_on_zone_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "zones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "floor", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "resources", "zones"
  add_foreign_key "sessions", "users"
  add_foreign_key "teams", "zones"
end
