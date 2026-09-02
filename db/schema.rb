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

ActiveRecord::Schema[8.1].define(version: 2026_09_02_223830) do
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

  create_table "bot_authorizations", force: :cascade do |t|
    t.datetime "approved_at"
    t.string "code_digest"
    t.datetime "code_expires_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "issued_at"
    t.text "justification"
    t.string "name", null: false
    t.string "request_token", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_id", null: false
    t.index ["request_token"], name: "index_bot_authorizations_on_request_token", unique: true
    t.index ["workspace_id", "name"], name: "index_bot_authorizations_on_workspace_id_and_name"
    t.index ["workspace_id"], name: "index_bot_authorizations_on_workspace_id"
  end

  create_table "oauth_client_credentials", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "provider", null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "client_id"], name: "index_oauth_client_credentials_on_provider_and_client_id", unique: true
    t.index ["team_id"], name: "index_oauth_client_credentials_on_team_id"
  end

  create_table "oauth_grants", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "oauth_client_credential_id", null: false
    t.string "provider", null: false
    t.string "refresh_token"
    t.string "remote_user_key"
    t.string "scope"
    t.integer "service_id", null: false
    t.string "token_type"
    t.datetime "updated_at", null: false
    t.index ["oauth_client_credential_id"], name: "index_oauth_grants_on_oauth_client_credential_id"
    t.index ["service_id"], name: "index_oauth_grants_on_service_id", unique: true
  end

  create_table "openapi_kinds", force: :cascade do |t|
    t.string "base_url"
    t.datetime "created_at", null: false
    t.json "definition"
    t.text "description"
    t.json "extra_credentials", default: []
    t.string "health_op"
    t.string "namespace", null: false
    t.string "spec_url"
    t.integer "team_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "namespace"], name: "index_openapi_kinds_on_team_id_and_namespace", unique: true
    t.index ["team_id"], name: "index_openapi_kinds_on_team_id"
  end

  create_table "rails_pulse_deployments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.text "metadata"
    t.string "revision", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.index ["revision"], name: "index_rails_pulse_deployments_on_revision"
    t.index ["started_at"], name: "index_rails_pulse_deployments_on_started_at"
  end

  create_table "services", force: :cascade do |t|
    t.json "config"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.json "oauth"
    t.integer "openapi_kind_id"
    t.integer "team_id", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["openapi_kind_id"], name: "index_services_on_openapi_kind_id"
    t.index ["team_id", "type", "name"], name: "index_services_on_team_id_and_type_and_name", unique: true
    t.index ["team_id"], name: "index_services_on_team_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
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
    t.integer "failed_login_attempts", default: 0, null: false
    t.datetime "locked_until"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workspace_services", force: :cascade do |t|
    t.text "allowed_tools"
    t.datetime "created_at", null: false
    t.integer "service_id", null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_id", null: false
    t.index ["service_id"], name: "index_workspace_services_on_service_id"
    t.index ["workspace_id", "service_id"], name: "index_workspace_services_on_workspace_id_and_service_id", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "log_tool_data", default: false, null: false
    t.string "name"
    t.string "share_code"
    t.string "share_code_digest"
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_workspaces_on_team_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "workspaces"
  add_foreign_key "bot_authorizations", "workspaces"
  add_foreign_key "oauth_client_credentials", "teams"
  add_foreign_key "oauth_grants", "oauth_client_credentials"
  add_foreign_key "oauth_grants", "services"
  add_foreign_key "openapi_kinds", "teams"
  add_foreign_key "services", "openapi_kinds"
  add_foreign_key "services", "teams"
  add_foreign_key "sessions", "users"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "tool_invocations", "api_tokens"
  add_foreign_key "tool_invocations", "services"
  add_foreign_key "workspace_services", "services"
  add_foreign_key "workspace_services", "workspaces"
  add_foreign_key "workspaces", "teams"
end
