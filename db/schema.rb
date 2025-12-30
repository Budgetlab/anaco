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

ActiveRecord::Schema[8.1].define(version: 2025_12_29_141841) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

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

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "avis", force: :cascade do |t|
    t.float "ae_f"
    t.float "ae_i"
    t.integer "annee"
    t.bigint "bop_id", null: false
    t.string "commentaire"
    t.float "cp_f"
    t.float "cp_i"
    t.datetime "created_at", null: false
    t.date "date_envoi"
    t.date "date_reception"
    t.integer "duree_prevision", default: 12
    t.string "etat"
    t.float "etpt_f"
    t.float "etpt_i"
    t.boolean "is_crg1"
    t.boolean "is_delai"
    t.string "phase"
    t.string "statut"
    t.float "t2_f"
    t.float "t2_i"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["bop_id"], name: "index_avis_on_bop_id"
    t.index ["user_id"], name: "index_avis_on_user_id"
  end

  create_table "bops", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "dcb_id"
    t.boolean "deconcentre", default: false, null: false
    t.string "dotation"
    t.string "ministere"
    t.string "nom_programme"
    t.integer "numero_programme"
    t.bigint "programme_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["dcb_id"], name: "index_bops_on_dcb_id"
    t.index ["deconcentre"], name: "index_bops_on_deconcentre"
    t.index ["programme_id"], name: "index_bops_on_programme_id"
    t.index ["user_id"], name: "index_bops_on_user_id"
  end

  create_table "centre_financiers", force: :cascade do |t|
    t.bigint "bop_id"
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "deconcentre", default: false, null: false
    t.bigint "programme_id"
    t.string "statut", default: "Actif", null: false
    t.datetime "updated_at", null: false
    t.index ["bop_id"], name: "index_centre_financiers_on_bop_id"
    t.index ["deconcentre"], name: "index_centre_financiers_on_deconcentre"
    t.index ["programme_id"], name: "index_centre_financiers_on_programme_id"
    t.index ["statut"], name: "index_centre_financiers_on_statut"
  end

  create_table "centre_financiers_ht2_actes", id: false, force: :cascade do |t|
    t.bigint "centre_financier_id", null: false
    t.bigint "ht2_acte_id", null: false
    t.index ["centre_financier_id", "ht2_acte_id"], name: "idx_on_centre_financier_id_ht2_acte_id_434d7f4a17"
    t.index ["ht2_acte_id", "centre_financier_id"], name: "idx_on_ht2_acte_id_centre_financier_id_ab5984b1f7"
  end

  create_table "echeanciers", force: :cascade do |t|
    t.integer "annee"
    t.datetime "created_at", null: false
    t.bigint "ht2_acte_id", null: false
    t.float "montant_ae"
    t.float "montant_cp"
    t.datetime "updated_at", null: false
    t.index ["ht2_acte_id"], name: "index_echeanciers_on_ht2_acte_id"
  end

  create_table "gestion_schemas", force: :cascade do |t|
    t.integer "annee"
    t.float "charges_a_payer_ae"
    t.float "charges_a_payer_cp"
    t.text "commentaire"
    t.datetime "created_at", null: false
    t.float "credits_lfg_ae"
    t.float "credits_lfg_cp"
    t.float "credits_reports_ae"
    t.float "credits_reports_cp"
    t.float "decret_ae"
    t.float "decret_cp"
    t.float "depenses_ae"
    t.float "depenses_cp"
    t.float "fongibilite_ae"
    t.float "fongibilite_cas"
    t.float "fongibilite_cp"
    t.float "fongibilite_hcas"
    t.float "mer_ae"
    t.float "mer_cp"
    t.float "mobilisation_mer_ae"
    t.float "mobilisation_mer_cp"
    t.float "mobilisation_surgel_ae"
    t.float "mobilisation_surgel_cp"
    t.string "profil"
    t.bigint "programme_id", null: false
    t.float "reports_ae"
    t.float "reports_autre_ae"
    t.float "reports_autre_cp"
    t.float "reports_cp"
    t.float "ressources_ae"
    t.float "ressources_cp"
    t.bigint "schema_id", null: false
    t.float "surgel_ae"
    t.float "surgel_cp"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "vision"
    t.index ["programme_id"], name: "index_gestion_schemas_on_programme_id"
    t.index ["schema_id"], name: "index_gestion_schemas_on_schema_id"
    t.index ["user_id"], name: "index_gestion_schemas_on_user_id"
  end

  create_table "ht2_actes", force: :cascade do |t|
    t.string "action"
    t.string "activite"
    t.integer "annee"
    t.string "beneficiaire"
    t.string "categorie"
    t.string "centre_financier_code"
    t.text "commentaire_proposition_decision"
    t.boolean "consommation_credits"
    t.datetime "created_at", null: false
    t.date "date_chorus"
    t.date "date_cloture"
    t.date "date_limite"
    t.string "decision_finale"
    t.integer "delai_traitement"
    t.boolean "disponibilite_credits"
    t.string "etat"
    t.string "groupe_marchandises"
    t.boolean "imputation_depense"
    t.string "instructeur"
    t.boolean "liste_actes", default: false
    t.float "montant_ae"
    t.float "montant_global"
    t.string "nature"
    t.integer "nombre_actes"
    t.string "numero_chorus"
    t.string "numero_formate"
    t.string "numero_marche"
    t.string "numero_tf"
    t.integer "numero_utilisateur"
    t.string "objet"
    t.text "observations"
    t.string "ordonnateur"
    t.boolean "pre_instruction"
    t.text "precisions_acte"
    t.boolean "programmation"
    t.boolean "programmation_prevue", default: false
    t.string "proposition_decision"
    t.boolean "renvoie_instruction", default: false
    t.boolean "services_votes", default: false
    t.jsonb "sheet_data", default: {"data" => []}
    t.string "sous_action"
    t.string "type_acte", null: false
    t.string "type_engagement"
    t.string "type_observations", default: [], array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "valideur"
    t.index ["annee"], name: "index_ht2_actes_on_annee"
    t.index ["date_limite"], name: "index_ht2_actes_on_date_limite"
    t.index ["delai_traitement"], name: "index_ht2_actes_on_delai_traitement"
    t.index ["numero_formate"], name: "index_ht2_actes_on_numero_formate"
    t.index ["numero_utilisateur"], name: "index_ht2_actes_on_numero_utilisateur"
    t.index ["user_id", "date_cloture", "annee"], name: "index_ht2_actes_on_user_cloture_annee"
    t.index ["user_id", "etat"], name: "index_ht2_actes_on_user_etat"
    t.index ["user_id", "updated_at"], name: "index_ht2_actes_on_user_updated_at"
    t.index ["user_id"], name: "index_ht2_actes_on_user_id"
  end

  create_table "ministeres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nom"
    t.datetime "updated_at", null: false
  end

  create_table "missions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nom"
    t.datetime "updated_at", null: false
  end

  create_table "poste_lignes", force: :cascade do |t|
    t.string "axe_ministeriel"
    t.string "centre_financier_code"
    t.string "code_activite"
    t.string "compte_budgetaire"
    t.datetime "created_at", null: false
    t.string "domaine_fonctionnel"
    t.string "flux"
    t.string "fonds"
    t.string "groupe_marchandises"
    t.bigint "ht2_acte_id", null: false
    t.float "montant"
    t.string "numero"
    t.string "numero_tf"
    t.datetime "updated_at", null: false
    t.index ["ht2_acte_id"], name: "index_poste_lignes_on_ht2_acte_id"
  end

  create_table "programmes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_inactivite"
    t.boolean "deconcentre"
    t.string "dotation"
    t.bigint "ministere_id"
    t.bigint "mission_id"
    t.string "nom"
    t.string "numero"
    t.string "statut", default: "Actif"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ministere_id"], name: "index_programmes_on_ministere_id"
    t.index ["mission_id"], name: "index_programmes_on_mission_id"
    t.index ["user_id"], name: "index_programmes_on_user_id"
  end

  create_table "schemas", force: :cascade do |t|
    t.integer "annee"
    t.datetime "created_at", null: false
    t.bigint "programme_id", null: false
    t.string "statut"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["programme_id"], name: "index_schemas_on_programme_id"
    t.index ["user_id"], name: "index_schemas_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "suspensions", force: :cascade do |t|
    t.string "commentaire_reprise"
    t.datetime "created_at", null: false
    t.date "date_reprise"
    t.date "date_suspension"
    t.bigint "ht2_acte_id", null: false
    t.string "motif"
    t.text "observations"
    t.datetime "updated_at", null: false
    t.index ["ht2_acte_id"], name: "index_suspensions_on_ht2_acte_id"
  end

  create_table "transferts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "gestion_schema_id", null: false
    t.float "montant_ae"
    t.float "montant_cp"
    t.string "nature"
    t.bigint "programme_id", null: false
    t.datetime "updated_at", null: false
    t.index ["gestion_schema_id"], name: "index_transferts_on_gestion_schema_id"
    t.index ["programme_id"], name: "index_transferts_on_programme_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "nom"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "statut"
    t.datetime "updated_at", null: false
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
  add_foreign_key "centre_financiers", "bops"
  add_foreign_key "centre_financiers", "programmes"
  add_foreign_key "echeanciers", "ht2_actes"
  add_foreign_key "gestion_schemas", "programmes"
  add_foreign_key "gestion_schemas", "schemas"
  add_foreign_key "gestion_schemas", "users"
  add_foreign_key "ht2_actes", "users"
  add_foreign_key "poste_lignes", "ht2_actes"
  add_foreign_key "programmes", "ministeres"
  add_foreign_key "programmes", "missions"
  add_foreign_key "programmes", "users"
  add_foreign_key "schemas", "programmes"
  add_foreign_key "schemas", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "suspensions", "ht2_actes"
  add_foreign_key "transferts", "gestion_schemas"
  add_foreign_key "transferts", "programmes"
end
