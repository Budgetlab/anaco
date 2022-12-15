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

ActiveRecord::Schema[7.0].define(version: 2022_12_15_095009) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "avis", force: :cascade do |t|
    t.string "phase"
    t.date "date_reception"
    t.date "date_envoi"
    t.boolean "is_delai"
    t.boolean "is_crg1"
    t.float "ae_i"
    t.float "cp_i"
    t.float "t2_i"
    t.float "etpt_i"
    t.float "ae_f"
    t.float "cp_f"
    t.float "t2_f"
    t.float "etpt_f"
    t.string "statut"
    t.string "etat"
    t.string "commentaire"
    t.bigint "bop_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bop_id"], name: "index_avis_on_bop_id"
  end

  create_table "bops", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "consultant"
    t.string "ministere"
    t.integer "numero_programme"
    t.string "nom_programme"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bops_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "statut"
    t.string "nom"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "avis", "bops"
  add_foreign_key "bops", "users"
end
