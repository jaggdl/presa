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

ActiveRecord::Schema[8.1].define(version: 2026_08_26_014102) do
  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "name"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_id", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["workspace_id"], name: "index_api_tokens_on_workspace_id"
  end

  create_table "services", force: :cascade do |t|
    t.json "config"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "type", "name"], name: "index_services_on_user_id_and_type_and_name", unique: true
    t.index ["user_id"], name: "index_services_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tool_invocations", force: :cascade do |t|
    t.integer "api_token_id", null: false
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.json "response"
    t.integer "service_id"
    t.string "status", default: "success", null: false
    t.string "tool_name", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token_id", "created_at"], name: "index_tool_invocations_on_api_token_id_and_created_at"
    t.index ["api_token_id"], name: "index_tool_invocations_on_api_token_id"
    t.index ["service_id"], name: "index_tool_invocations_on_service_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workspace_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "service_id", null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_id", null: false
    t.index ["service_id"], name: "index_workspace_services_on_service_id"
    t.index ["workspace_id", "service_id"], name: "index_workspace_services_on_workspace_id_and_service_id", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_workspaces_on_user_id"
  end

  add_foreign_key "api_tokens", "workspaces"
  add_foreign_key "services", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tool_invocations", "api_tokens"
  add_foreign_key "tool_invocations", "services"
  add_foreign_key "workspace_services", "services"
  add_foreign_key "workspace_services", "workspaces"
  add_foreign_key "workspaces", "users"
end
