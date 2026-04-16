require 'google/cloud/storage'

module GcsBackupConcern
  GCS_BUCKET  = 'anaco-bucket'
  GCS_PROJECT = 'apps-354210'

  private

  def gcs_bucket
    storage = Google::Cloud::Storage.new(
      project_id: GCS_PROJECT,
      credentials: {
        type: 'service_account',
        project_id: GCS_PROJECT,
        private_key_id: Rails.application.credentials.dig(:gcp, :private_key_id),
        private_key: Rails.application.credentials.dig(:gcp, :private_key),
        client_email: 'anacoservice@apps-354210.iam.gserviceaccount.com',
        client_id: '109301679416864781938',
        token_uri: 'https://oauth2.googleapis.com/token'
      }
    )
    storage.bucket(GCS_BUCKET)
  end
end
