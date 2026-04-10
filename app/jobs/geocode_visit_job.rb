class GeocodeVisitJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    visit = Visit.find_by(id: visit_id)
    return unless visit
    return if visit.latitude.present?

    results = Geocoder.search(visit.ip_address)
    return if results.empty?

    result = results.first
    visit.update(
      latitude: result.latitude,
      longitude: result.longitude,
      city: result.city,
      country: result.country
    )
  end
end
