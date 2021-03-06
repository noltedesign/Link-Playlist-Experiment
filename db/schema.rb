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

ActiveRecord::Schema.define(version: 20150123233620) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "feed_categories", force: :cascade do |t|
    t.string "category_name", limit: 255
  end

  create_table "feed_categorizations", force: :cascade do |t|
    t.integer "feed_id"
    t.integer "feed_category_id"
    t.string  "category_order",   limit: 255
  end

  create_table "feed_items", force: :cascade do |t|
    t.string   "feed_id",      limit: 255
    t.text     "title"
    t.text     "summary"
    t.text     "item_url"
    t.string   "published_on", limit: 255
    t.text     "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feeds", force: :cascade do |t|
    t.string "link",       limit: 255
    t.string "feed_title", limit: 255
    t.string "feed_link",  limit: 255
    t.string "feed_type",  limit: 255
  end

  create_table "saved_items", force: :cascade do |t|
    t.string   "user_id",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "feed_item_id"
  end

  create_table "user_feeds", force: :cascade do |t|
    t.integer "feed_id"
    t.integer "user_id"
    t.string  "feed_order", limit: 255
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",         limit: 255
    t.string   "password_hash", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "page_title",    limit: 255
    t.string   "userurl"
  end

end
