module GestionSchemasHelper
  def find_gestion_schema_vision(gestion_schemas, vision, profil)
    gestion_schemas.select { |gs| gs.vision == vision && gs.profil == profil }&.first
  end
end
