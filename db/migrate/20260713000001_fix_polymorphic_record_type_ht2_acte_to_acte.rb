class FixPolymorphicRecordTypeHt2ActeToActe < ActiveRecord::Migration[8.1]
  # Le renommage du modèle Ht2Acte -> Acte (migration rename_ht2_actes_to_actes)
  # a renommé la table et les FK, mais PAS la colonne polymorphe `record_type`
  # des tables ActionText / ActiveStorage. Les enregistrements existants
  # pointent donc toujours vers "Ht2Acte" et ne sont plus retrouvés par le
  # modèle `Acte`, d'où la disparition de commentaire_disponibilite_credits
  # (et des PDF attachés) en production.
  #
  # Migration data idempotente et robuste aux doublons : si un même
  # (record_id, name) possède déjà une ligne "Acte" créée après le déploiement,
  # un simple UPDATE violerait l'index d'unicité
  # (record_type, record_id, name). On traite donc les collisions.

  OLD_TYPE = "Ht2Acte".freeze
  NEW_TYPE = "Acte".freeze

  def up
    fix_rich_texts
    fix_attachments
  end

  def down
    # On ne restaure QUE ce qui est un Acte réel ; irréversible pour les
    # lignes fusionnées, mais suffisant pour rejouer un rollback logique.
    execute("UPDATE action_text_rich_texts SET record_type = '#{OLD_TYPE}' WHERE record_type = '#{NEW_TYPE}'")
    execute("UPDATE active_storage_attachments SET record_type = '#{OLD_TYPE}' WHERE record_type = '#{NEW_TYPE}'")
  end

  private

  # --- ActionText ------------------------------------------------------------
  # Index unique sur (record_type, record_id, name). Une ligne "Ht2Acte" et une
  # ligne "Acte" pour le même (record_id, name) entreraient en collision.
  # Règle de résolution : la ligne "Acte" (récente) gagne SI elle a du contenu ;
  # sinon on la supprime et on bascule l'ancienne "Ht2Acte".
  def fix_rich_texts
    # 1. Résoudre les collisions.
    collisions = select_all(<<~SQL).to_a
      SELECT old.id AS old_id, new.id AS new_id,
             COALESCE(new.body, '') AS new_body
      FROM action_text_rich_texts old
      JOIN action_text_rich_texts new
        ON new.record_type = '#{NEW_TYPE}'
       AND new.record_id   = old.record_id
       AND new.name        = old.name
      WHERE old.record_type = '#{OLD_TYPE}'
    SQL

    collisions.each do |row|
      if row["new_body"].to_s.strip.empty?
        # La ligne "Acte" est vide -> on la supprime, l'ancienne prendra sa place.
        execute("DELETE FROM action_text_rich_texts WHERE id = #{row['new_id'].to_i}")
      else
        # La ligne "Acte" a du contenu -> on garde le récent, on jette l'ancien.
        execute("DELETE FROM action_text_rich_texts WHERE id = #{row['old_id'].to_i}")
      end
    end

    # 2. Basculer tout ce qui reste (plus aucune collision possible).
    execute("UPDATE action_text_rich_texts SET record_type = '#{NEW_TYPE}' WHERE record_type = '#{OLD_TYPE}'")
  end

  # --- ActiveStorage ---------------------------------------------------------
  # Index unique sur (record_type, record_id, name, blob_id). Comme `pdf_files`
  # est un has_many_attached, un même blob_id ne devrait pas exister en double,
  # mais on sécurise : on ne bascule que les attachments qui ne créent pas de
  # collision, et on signale les rares cas restants sans supprimer de fichier.
  def fix_attachments
    execute(<<~SQL)
      UPDATE active_storage_attachments old
      SET record_type = '#{NEW_TYPE}'
      WHERE old.record_type = '#{OLD_TYPE}'
        AND NOT EXISTS (
          SELECT 1 FROM active_storage_attachments new
          WHERE new.record_type = '#{NEW_TYPE}'
            AND new.record_id   = old.record_id
            AND new.name        = old.name
            AND new.blob_id     = old.blob_id
        )
    SQL

    remaining = select_value(
      "SELECT COUNT(*) FROM active_storage_attachments WHERE record_type = '#{OLD_TYPE}'"
    ).to_i

    if remaining.positive?
      say "ATTENTION : #{remaining} attachment(s) '#{OLD_TYPE}' n'ont pas été basculés " \
          "(collision d'unicité, un fichier identique existe déjà côté 'Acte'). " \
          "À inspecter manuellement — aucun fichier n'a été supprimé.", true
    end
  end
end
