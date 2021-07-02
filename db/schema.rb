# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 4) do

  create_table "cheerings", force: :cascade do |t|
    t.string "emoji", null: false
    t.string "name", limit: 64, null: false
    t.text "text", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["emoji"], name: "index_cheerings_on_emoji", unique: true
  end

  create_table "search_words", force: :cascade do |t|
    t.string "channel_id", limit: 64, null: false
    t.text "keyword", null: false
    t.integer "since_id", limit: 8, default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["channel_id"], name: "index_search_words_on_channel_id", unique: true
  end

  create_table "twitter_profiles", force: :cascade do |t|
    t.string "screen_name", limit: 255, null: false
    t.integer "twitter_user_id", limit: 8, null: false
    t.integer "followers_count", limit: 8, default: 0, null: false
    t.integer "friends_count", limit: 8, default: 0, null: false
    t.integer "statuses_count", limit: 8, default: 0, null: false
    t.string "post_channel_id", limit: 64, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["twitter_user_id", "post_channel_id"], name: "index_twitter_profiles_on_tuid_and_pcid", unique: true
  end

  create_table "youtube_channels", force: :cascade do |t|
    t.string "title", limit: 255, null: false
    t.string "youtube_channel_id", limit: 255, null: false
    t.integer "subscriber_count", limit: 8, default: 0, null: false
    t.integer "view_count", limit: 8, default: 0, null: false
    t.string "post_channel_id", limit: 64, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["youtube_channel_id", "post_channel_id"], name: "index_youtube_channels_on_ycid_and_pcid", unique: true
  end

end
