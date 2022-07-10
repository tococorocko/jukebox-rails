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

ActiveRecord::Schema[7.0].define(version: 2022_07_10_174448) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "devices", force: :cascade do |t|
    t.string "name"
    t.string "device_uid"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "jukeboxes", force: :cascade do |t|
    t.string "name"
    t.integer "credit", default: 0
    t.bigint "user_id"
    t.bigint "device_id"
    t.bigint "playlist_id"
    t.string "camera_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_jukeboxes_on_device_id"
    t.index ["playlist_id"], name: "index_jukeboxes_on_playlist_id"
    t.index ["user_id"], name: "index_jukeboxes_on_user_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.string "name"
    t.string "playlist_uid"
    t.string "uri"
    t.integer "track_number"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_playlists_on_user_id"
  end

  create_table "queued_songs", force: :cascade do |t|
    t.bigint "jukebox_id"
    t.bigint "song_id"
    t.string "song_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jukebox_id"], name: "index_queued_songs_on_jukebox_id"
    t.index ["song_id"], name: "index_queued_songs_on_song_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string "name"
    t.string "artist"
    t.string "uri"
    t.string "cover_uri"
    t.string "length"
    t.boolean "playing", default: false
    t.bigint "jukebox_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jukebox_id"], name: "index_songs_on_jukebox_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "provider", default: "", null: false
    t.string "uid", default: "", null: false
    t.string "access_token", default: "", null: false
    t.string "refresh_token", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
