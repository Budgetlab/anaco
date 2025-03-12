Rails.application.config.to_prepare do
  ActionText::RichText.class_eval do
    def self.ransackable_attributes(auth_object = nil)
      ["body", "created_at", "id", "id_value", "name", "record_id", "record_type", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end
  end
end