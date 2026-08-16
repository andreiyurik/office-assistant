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

ActiveRecord::Schema[8.1].define(version: 2026_08_15_170006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "group_id", null: false
    t.integer "resource_id", null: false
    t.datetime "starts_at", null: false
    t.string "state", default: "booked", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["group_id"], name: "index_bookings_on_group_id"
    t.index ["resource_id", "starts_at"], name: "index_bookings_on_active_resource_slot", unique: true, where: "((state)::text = ANY ((ARRAY['booked'::character varying, 'checked_in'::character varying])::text[]))"
    t.index ["resource_id"], name: "index_bookings_on_resource_id"
    t.index ["starts_at"], name: "index_bookings_on_starts_at"
    t.index ["user_id", "starts_at"], name: "index_bookings_on_active_user_slot", unique: true, where: "((state)::text = ANY ((ARRAY['booked'::character varying, 'checked_in'::character varying])::text[]))"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "recurring_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "resource_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.date "valid_from", null: false
    t.date "valid_to"
    t.json "weekdays", default: [], null: false
    t.index ["resource_id"], name: "index_recurring_schedules_on_resource_id"
    t.index ["user_id"], name: "index_recurring_schedules_on_user_id", unique: true
  end

  create_table "resources", force: :cascade do |t|
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.integer "grid_col"
    t.integer "grid_row"
    t.string "kind", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "zone_id", null: false
    t.index ["grid_row", "grid_col"], name: "index_desks_on_grid_cell", unique: true, where: "((kind)::text = 'desk'::text)"
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
    t.integer "default_desk_id"
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.integer "team_id"
    t.datetime "updated_at", null: false
    t.index ["default_desk_id"], name: "index_users_on_default_desk_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  create_table "zones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "floor", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bookings", "resources"
  add_foreign_key "bookings", "users"
  add_foreign_key "recurring_schedules", "resources"
  add_foreign_key "recurring_schedules", "users"
  add_foreign_key "resources", "zones"
  add_foreign_key "sessions", "users"
  add_foreign_key "teams", "zones"
  add_foreign_key "users", "resources", column: "default_desk_id"
  add_foreign_key "users", "teams"
end
