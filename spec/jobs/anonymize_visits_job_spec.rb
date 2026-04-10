require "rails_helper"

RSpec.describe AnonymizeVisitsJob, type: :job do
  it "anonymizes visits older than 90 days" do
    old_visit = Visit.create!(ip_address: "8.8.8.8", path: "/", user_agent: "Mozilla/5.0", created_at: 91.days.ago)
    recent_visit = Visit.create!(ip_address: "1.1.1.1", path: "/about", user_agent: "Chrome", created_at: 30.days.ago)

    AnonymizeVisitsJob.perform_now

    old_visit.reload
    expect(old_visit.ip_address).to eq("0.0.0.0")
    expect(old_visit.user_agent).to be_nil

    recent_visit.reload
    expect(recent_visit.ip_address).to eq("1.1.1.1")
    expect(recent_visit.user_agent).to eq("Chrome")
  end

  it "skips already anonymized visits" do
    anonymized = Visit.create!(ip_address: "0.0.0.0", path: "/", created_at: 100.days.ago)

    expect { AnonymizeVisitsJob.perform_now }.not_to change { anonymized.reload.updated_at }
  end

  it "preserves analytics fields on anonymized visits" do
    old_visit = Visit.create!(
      ip_address: "8.8.8.8", path: "/posts/hello", browser: "Chrome",
      device_type: "Desktop", os: "Mac OS X", country: "US", city: "New York",
      referrer: "https://google.com", created_at: 91.days.ago
    )

    AnonymizeVisitsJob.perform_now

    old_visit.reload
    expect(old_visit.path).to eq("/posts/hello")
    expect(old_visit.browser).to eq("Chrome")
    expect(old_visit.device_type).to eq("Desktop")
    expect(old_visit.country).to eq("US")
    expect(old_visit.city).to eq("New York")
    expect(old_visit.referrer).to eq("https://google.com")
  end
end
