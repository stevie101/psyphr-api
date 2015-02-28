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

ActiveRecord::Schema.define(version: 20150222210626) do

  create_table "certificates", force: true do |t|
    t.integer  "certificatable_id"
    t.string   "certificatable_type"
    t.binary   "certificate",         limit: 16777215
    t.string   "distinguished_name"
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.string   "serial_number"
    t.string   "filename",                             default: "unknown"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "certificates", ["certificatable_id", "certificatable_type"], name: "index_certificates_on_certificatable_id_and_certificatable_type", using: :btree

  create_table "crls", force: true do |t|
    t.integer  "crlable_id"
    t.string   "crlable_type"
    t.integer  "number"
    t.binary   "crl"
    t.datetime "last_update_at"
    t.datetime "next_update_at"
    t.string   "issuer_name"
    t.integer  "serial"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "crls", ["crlable_id", "crlable_type"], name: "index_crls_on_crlable_id_and_crlable_type", using: :btree

  create_table "end_entities", force: true do |t|
    t.integer  "sec_app_id"
    t.string   "uuid"
    t.string   "e_password"
    t.string   "did"
    t.string   "slug"
    t.integer  "status",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sec_apps", force: true do |t|
    t.string   "uuid"
    t.integer  "user_id"
    t.string   "name"
    t.binary   "client_key"
    t.binary   "ca_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "serial_number", limit: 8
    t.integer  "crl_count",               default: 0
  end

  create_table "users", force: true do |t|
    t.string   "slug"
    t.string   "firstname"
    t.string   "surname"
    t.string   "email"
    t.string   "locality"
    t.string   "country"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
