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

ActiveRecord::Schema.define(version: 20151208140649) do

  create_table "bids", force: :cascade do |t|
    t.integer "user_id"
    t.integer "book_id"
    t.string  "bid"
    t.boolean "notification", default: false
    t.string  "status",       default: "highest bid"
  end

  add_index "bids", ["book_id"], name: "index_bids_on_book_id"
  add_index "bids", ["user_id"], name: "index_bids_on_user_id"

  create_table "books", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "title"
    t.string   "author"
    t.string   "isbn"
    t.string   "quality"
    t.string   "image"
    t.string   "price"
    t.text     "description"
    t.string   "department"
    t.string   "course"
    t.string   "auction_start_price"
    t.datetime "auction_time"
    t.string   "time_left"
    t.string   "bid_price"
    t.string   "bidder_id"
    t.string   "status"
    t.boolean  "notification",        default: false
  end

  add_index "books", ["user_id"], name: "index_books_on_user_id"

  create_table "tags", force: :cascade do |t|
    t.integer "book_id"
    t.string  "tag"
  end

  add_index "tags", ["book_id"], name: "index_tags_on_book_id"

  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "email"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "last_name"
    t.string   "user_id"
    t.string   "password_digest"
    t.string   "session_token"
    t.integer  "books_sold"
    t.integer  "books_bought"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["session_token"], name: "index_users_on_session_token"

end
