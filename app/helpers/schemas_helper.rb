module SchemasHelper

  def numero_version(schema)
    schemas = Schema.where(programme_id: schema.programme_id, annee: schema.annee).order(:created_at)
    schemas.index(schema) + 1
  end
end
