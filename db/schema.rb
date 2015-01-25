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

ActiveRecord::Schema.define(version: 20141202163634) do

  create_table "apps", force: true do |t|
    t.string   "uuid"
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificates", force: true do |t|
    t.integer  "end_entity_id"
    t.string   "common_name"
    t.string   "organisational_unit"
    t.string   "organisation"
    t.string   "locality"
    t.integer  "state"
    t.string   "country"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.string   "serial_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "end_entities", force: true do |t|
    t.integer  "app_id"
    t.string   "uuid"
    t.string   "e_password"
    t.string   "did"
    t.string   "slug"
    t.text     "cert",       limit: 16777215
    t.integer  "status",                      default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "slug"
    t.string   "firstname"
    t.string   "surname"
    t.string   "email"
    t.string   "locality"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
