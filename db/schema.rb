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

ActiveRecord::Schema[7.2].define(version: 2025_02_19_095742) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

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
    t.bigint "user_id", null: false
    t.integer "annee"
    t.integer "duree_prevision", default: 12
    t.index ["bop_id"], name: "index_avis_on_bop_id"
    t.index ["user_id"], name: "index_avis_on_user_id"
  end

  create_table "bops", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ministere"
    t.integer "numero_programme"
    t.string "nom_programme"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dotation"
    t.bigint "programme_id"
    t.bigint "dcb_id"
    t.index ["dcb_id"], name: "index_bops_on_dcb_id"
    t.index ["programme_id"], name: "index_bops_on_programme_id"
    t.index ["user_id"], name: "index_bops_on_user_id"
  end

  create_table "gestion_schemas", force: :cascade do |t|
    t.bigint "programme_id", null: false
    t.bigint "user_id", null: false
    t.bigint "schema_id", null: false
    t.string "vision"
    t.string "profil"
    t.integer "annee"
    t.float "ressources_ae"
    t.float "ressources_cp"
    t.float "depenses_ae"
    t.float "depenses_cp"
    t.float "mer_ae"
    t.float "mer_cp"
    t.float "surgel_ae"
    t.float "surgel_cp"
    t.float "mobilisation_mer_ae"
    t.float "mobilisation_mer_cp"
    t.float "mobilisation_surgel_ae"
    t.float "mobilisation_surgel_cp"
    t.float "fongibilite_ae"
    t.float "fongibilite_cp"
    t.float "decret_ae"
    t.float "decret_cp"
    t.float "credits_lfg_ae"
    t.float "credits_lfg_cp"
    t.float "reports_ae"
    t.float "reports_cp"
    t.float "charges_a_payer_ae"
    t.float "charges_a_payer_cp"
    t.float "reports_autre_ae"
    t.float "reports_autre_cp"
    t.float "credits_reports_ae"
    t.float "credits_reports_cp"
    t.text "commentaire"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "fongibilite_hcas"
    t.float "fongibilite_cas"
    t.index ["programme_id"], name: "index_gestion_schemas_on_programme_id"
    t.index ["schema_id"], name: "index_gestion_schemas_on_schema_id"
    t.index ["user_id"], name: "index_gestion_schemas_on_user_id"
  end

  create_table "ht2_actes", force: :cascade do |t|
    t.string "type_acte", null: false
    t.string "etat"
    t.string "instructeur"
    t.string "nature"
    t.float "montant_ae"
    t.float "montant_global"
    t.date "date_chorus"
    t.string "numero_chorus"
    t.string "beneficiaire"
    t.string "objet"
    t.string "ordonnateur"
    t.text "precisions_acte"
    t.boolean "pre_instruction"
    t.string "action"
    t.string "sous_action"
    t.string "activite"
    t.boolean "lien_tf"
    t.string "numero_tf"
    t.boolean "disponibilite_credits"
    t.boolean "imputation_depense"
    t.boolean "consommation_credits"
    t.boolean "programmation"
    t.string "proposition_decision"
    t.text "commentaire_proposition_decision"
    t.string "complexite"
    t.text "observations"
    t.string "type_observations", default: [], array: true
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_ht2_actes_on_user_id"
  end

  create_table "ministeres", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "missions", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "programmes", force: :cascade do |t|
    t.string "numero"
    t.string "nom"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "mission_id"
    t.bigint "ministere_id"
    t.boolean "deconcentre"
    t.string "dotation"
    t.string "statut", default: "Actif"
    t.date "date_inactivite"
    t.index ["ministere_id"], name: "index_programmes_on_ministere_id"
    t.index ["mission_id"], name: "index_programmes_on_mission_id"
    t.index ["user_id"], name: "index_programmes_on_user_id"
  end

  create_table "schemas", force: :cascade do |t|
    t.bigint "programme_id", null: false
    t.bigint "user_id", null: false
    t.string "statut"
    t.integer "annee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["programme_id"], name: "index_schemas_on_programme_id"
    t.index ["user_id"], name: "index_schemas_on_user_id"
  end

  create_table "transferts", force: :cascade do |t|
    t.bigint "gestion_schema_id", null: false
    t.string "nature"
    t.float "montant_ae"
    t.float "montant_cp"
    t.bigint "programme_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gestion_schema_id"], name: "index_transferts_on_gestion_schema_id"
    t.index ["programme_id"], name: "index_transferts_on_programme_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "avis", "bops"
  add_foreign_key "avis", "users"
  add_foreign_key "bops", "programmes"
  add_foreign_key "bops", "users"
  add_foreign_key "bops", "users", column: "dcb_id"
  add_foreign_key "gestion_schemas", "programmes"
  add_foreign_key "gestion_schemas", "schemas"
  add_foreign_key "gestion_schemas", "users"
  add_foreign_key "ht2_actes", "users"
  add_foreign_key "programmes", "ministeres"
  add_foreign_key "programmes", "missions"
  add_foreign_key "programmes", "users"
  add_foreign_key "schemas", "programmes"
  add_foreign_key "schemas", "users"
  add_foreign_key "transferts", "gestion_schemas"
  add_foreign_key "transferts", "programmes"
end
