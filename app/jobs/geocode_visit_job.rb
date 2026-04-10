class GeocodeVisitJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    visit = Visit.find_by(id: visit_id)
    return unless visit
    return if visit.latitude.present?

    visit.geocode
    visit.save
  end
end
