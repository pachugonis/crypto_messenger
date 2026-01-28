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

ActiveRecord::Schema[8.1].define(version: 2026_01_27_141512) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "advertisements", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "icon_color"
    t.string "icon_type", default: "svg"
    t.string "image_url"
    t.string "link"
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_advertisements_on_active"
    t.index ["position"], name: "index_advertisements_on_position"
  end

  create_table "attachments", force: :cascade do |t|
    t.string "access_token"
    t.datetime "access_token_expires_at"
    t.bigint "attachable_id", null: false
    t.string "attachable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["access_token"], name: "index_attachments_on_access_token", unique: true
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
    t.index ["user_id"], name: "index_attachments_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "message_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_comments_on_deleted_at"
    t.index ["message_id", "created_at"], name: "index_comments_on_message_id_and_created_at"
    t.index ["message_id"], name: "index_comments_on_message_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_folder_id"
    t.datetime "share_expires_at"
    t.string "share_token"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["parent_folder_id"], name: "index_folders_on_parent_folder_id"
    t.index ["share_token"], name: "index_folders_on_share_token"
    t.index ["user_id", "parent_folder_id", "name"], name: "index_folders_on_user_id_and_parent_folder_id_and_name", unique: true
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "message_reads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "message_id", null: false
    t.datetime "read_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["message_id", "user_id"], name: "index_message_reads_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_message_reads_on_message_id"
    t.index ["read_at"], name: "index_message_reads_on_read_at"
    t.index ["user_id"], name: "index_message_reads_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "delivered_at"
    t.integer "message_type", default: 0, null: false
    t.bigint "room_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["room_id", "created_at"], name: "index_messages_on_room_id_and_created_at"
    t.index ["room_id"], name: "index_messages_on_room_id"
    t.index ["status"], name: "index_messages_on_status"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.bigint "message_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["message_id", "emoji"], name: "index_reactions_on_message_id_and_emoji"
    t.index ["message_id", "user_id"], name: "index_reactions_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_reactions_on_message_id"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "room_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.boolean "muted", default: false
    t.integer "role", default: 0, null: false
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["room_id", "user_id"], name: "index_room_participants_on_room_id_and_user_id"
    t.index ["room_id"], name: "index_room_participants_on_room_id"
    t.index ["user_id", "room_id"], name: "index_room_participants_on_user_id_and_room_id", unique: true
    t.index ["user_id"], name: "index_room_participants_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "handle"
    t.integer "messages_count", default: 0
    t.string "name", null: false
    t.integer "participants_count", default: 0
    t.integer "room_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["handle"], name: "index_rooms_on_handle", unique: true, where: "(handle IS NOT NULL)"
    t.index ["room_type", "visibility"], name: "index_rooms_on_room_type_and_visibility"
    t.index ["room_type"], name: "index_rooms_on_room_type"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.datetime "locked_at"
    t.text "otp_backup_codes"
    t.boolean "otp_enabled", default: false, null: false
    t.string "otp_secret"
    t.string "password_digest", null: false
    t.string "recovery_code_digest"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["otp_secret"], name: "index_users_on_otp_secret"
    t.index ["recovery_code_digest"], name: "index_users_on_recovery_code_digest"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attachments", "users"
  add_foreign_key "comments", "messages"
  add_foreign_key "comments", "users"
  add_foreign_key "folders", "folders", column: "parent_folder_id"
  add_foreign_key "folders", "users"
  add_foreign_key "message_reads", "messages"
  add_foreign_key "message_reads", "users"
  add_foreign_key "messages", "rooms"
  add_foreign_key "messages", "users"
  add_foreign_key "reactions", "messages"
  add_foreign_key "reactions", "users"
  add_foreign_key "room_participants", "rooms"
  add_foreign_key "room_participants", "users"
  add_foreign_key "sessions", "users"
end
