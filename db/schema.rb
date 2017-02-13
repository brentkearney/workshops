# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20161117004538) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.string   "code"
    t.text     "name"
    t.string   "short_name"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "event_type"
    t.string   "location"
    t.text     "description"
    t.text     "press_release"
    t.integer  "max_participants"
    t.integer  "door_code"
    t.string   "booking_code"
    t.string   "updated_by"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "template",         default: false
    t.string   "time_zone"
    t.boolean  "publish_schedule", default: false
    t.integer  "confirmed_count",  default: 0,     null: false
  end

  add_index "events", ["code"], name: "index_events_on_code", unique: true, using: :btree

  create_table "lectures", force: :cascade do |t|
    t.integer  "event_id",            null: false
    t.integer  "person_id"
    t.string   "title"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "abstract"
    t.text     "notes"
    t.string   "filename"
    t.string   "room"
    t.boolean  "do_not_publish"
    t.boolean  "tweeted"
    t.text     "hosting_license"
    t.text     "archiving_license"
    t.boolean  "hosting_release"
    t.boolean  "archiving_release"
    t.string   "authors"
    t.string   "copyright_owners"
    t.string   "publication_details"
    t.string   "updated_by"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "cmo_license"
    t.string   "keywords"
    t.integer  "legacy_id"
  end

  add_index "lectures", ["event_id"], name: "index_lectures_on_event_id", using: :btree
  add_index "lectures", ["person_id"], name: "index_lectures_on_person_id", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "person_id"
    t.date     "arrival_date"
    t.date     "departure_date"
    t.string   "role"
    t.string   "attendance"
    t.datetime "replied_at"
    t.boolean  "share_email",     default: true
    t.text     "org_notes"
    t.text     "staff_notes"
    t.string   "updated_by"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "sent_invitation", default: false
  end

  add_index "memberships", ["event_id"], name: "index_memberships_on_event_id", using: :btree
  add_index "memberships", ["person_id"], name: "index_memberships_on_person_id", using: :btree

  create_table "people", force: :cascade do |t|
    t.string   "lastname"
    t.string   "firstname"
    t.string   "salutation"
    t.string   "gender"
    t.string   "email"
    t.string   "cc_email"
    t.string   "url"
    t.string   "phone"
    t.string   "fax"
    t.string   "emergency_contact"
    t.string   "emergency_phone"
    t.string   "affiliation"
    t.string   "department"
    t.string   "title"
    t.string   "address1"
    t.string   "address2"
    t.string   "address3"
    t.string   "city"
    t.string   "region"
    t.string   "country"
    t.string   "postal_code"
    t.string   "academic_status"
    t.string   "phd_year"
    t.text     "biography"
    t.text     "research_areas"
    t.integer  "legacy_id"
    t.string   "updated_by"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.integer  "event_id",                    null: false
    t.integer  "lecture_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string   "name"
    t.text     "description"
    t.string   "location"
    t.string   "updated_by"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "staff_item",  default: false, null: false
  end

  add_index "schedules", ["event_id"], name: "index_schedules_on_event_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree
  add_index "settings", ["var"], name: "settings_var_key", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "person_id"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",      default: 0
    t.integer  "role",                   default: 0
    t.string   "location"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["person_id"], name: "index_users_on_person_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "lectures", "events"
  add_foreign_key "lectures", "people"
  add_foreign_key "memberships", "events"
  add_foreign_key "memberships", "people"
  add_foreign_key "schedules", "events"
end
