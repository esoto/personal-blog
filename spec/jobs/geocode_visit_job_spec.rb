require "rails_helper"

RSpec.describe GeocodeVisitJob, type: :job do
  it "geocodes the visit and saves coordinates" do
    visit = Visit.create!(ip_address: "8.8.8.8", path: "/")

    GeocodeVisitJob.perform_now(visit.id)

    visit.reload
    expect(visit.latitude).to be_present
    expect(visit.longitude).to be_present
  end

  it "skips if the visit no longer exists" do
    expect { GeocodeVisitJob.perform_now(999_999) }.not_to raise_error
  end

  it "skips if the visit already has coordinates" do
    visit = Visit.create!(ip_address: "8.8.8.8", path: "/", latitude: 40.7, longitude: -74.0)

    expect(visit).not_to receive(:geocode)
    GeocodeVisitJob.perform_now(visit.id)
  end
end
