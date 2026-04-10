class AnonymizeVisitsJob < ApplicationJob
  queue_as :default

  def perform
    count = Visit.stale_pii.count
    Visit.anonymize_stale!
    Rails.logger.info("Anonymized #{count} visits older than #{Visit::ANONYMIZATION_THRESHOLD.inspect}")
  end
end
