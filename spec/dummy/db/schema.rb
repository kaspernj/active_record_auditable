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

ActiveRecord::Schema[7.2].define(version: 2024_09_02_062450) do
  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audit_actions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_actions_on_action", unique: true
  end

  create_table "audit_auditable_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_audit_auditable_types_on_name", unique: true
  end

  create_table "audits", force: :cascade do |t|
    t.integer "audit_action_id", null: false
    t.integer "audit_auditable_type_id", null: false
    t.string "auditable_type", null: false
    t.integer "auditable_id", null: false
    t.string "user_type"
    t.integer "user_id"
    t.json "audited_changes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["audit_action_id"], name: "index_audits_on_audit_action_id"
    t.index ["audit_auditable_type_id"], name: "index_audits_on_audit_auditable_type_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audits_on_auditable"
    t.index ["user_type", "user_id"], name: "index_audits_on_user"
  end

  create_table "project_audits", force: :cascade do |t|
    t.integer "project_id", null: false
    t.json "audited_changes"
    t.integer "audit_action_id", null: false
    t.json "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["audit_action_id"], name: "index_project_audits_on_audit_action_id"
    t.index ["project_id"], name: "index_project_audits_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_projects_on_account_id"
  end

  add_foreign_key "audits", "audit_actions"
  add_foreign_key "audits", "audit_auditable_types"
  add_foreign_key "project_audits", "audit_actions"
  add_foreign_key "projects", "accounts"
end
