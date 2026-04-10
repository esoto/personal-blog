require "rails_helper"

RSpec.describe Visit, type: :model do
  describe "validations" do
    it "requires ip_address" do
      visit = Visit.new(path: "/")
      expect(visit).not_to be_valid
      expect(visit.errors[:ip_address]).to include("can't be blank")
    end

    it "requires path" do
      visit = Visit.new(ip_address: "1.2.3.4")
      expect(visit).not_to be_valid
      expect(visit.errors[:path]).to include("can't be blank")
    end

    it "is valid with ip_address and path" do
      visit = Visit.new(ip_address: "1.2.3.4", path: "/")
      expect(visit).to be_valid
    end
  end

  describe "scopes" do
    before do
      travel_to Time.zone.local(2026, 4, 9, 12, 0, 0)
      Visit.create!(ip_address: "1.1.1.1", path: "/", created_at: Time.current)
      Visit.create!(ip_address: "2.2.2.2", path: "/about", created_at: 2.days.ago)
      Visit.create!(ip_address: "3.3.3.3", path: "/posts", created_at: 10.days.ago)
      Visit.create!(ip_address: "4.4.4.4", path: "/tags", created_at: 40.days.ago)
    end

    after { travel_back }

    it ".today returns only today's visits" do
      expect(Visit.today.count).to eq(1)
    end

    it ".this_week returns visits from the last 7 days" do
      expect(Visit.this_week.count).to eq(2)
    end

    it ".this_month returns visits from the last 30 days" do
      expect(Visit.this_month.count).to eq(3)
    end
  end

  describe ".top_referrers" do
    before do
      3.times { Visit.create!(ip_address: "1.1.1.1", path: "/", referrer: "https://google.com") }
      1.times { Visit.create!(ip_address: "1.1.1.1", path: "/", referrer: "https://twitter.com") }
      2.times { Visit.create!(ip_address: "1.1.1.1", path: "/", referrer: nil) }
    end

    it "returns referrers ordered by count, excluding nil" do
      result = Visit.top_referrers(5)
      expect(result).to eq([ [ "https://google.com", 3 ], [ "https://twitter.com", 1 ] ])
    end
  end

  describe ".top_locations" do
    before do
      3.times { Visit.create!(ip_address: "1.1.1.1", path: "/", country: "US", city: "New York") }
      2.times { Visit.create!(ip_address: "2.2.2.2", path: "/", country: "UK", city: "London") }
    end

    it "returns locations ordered by count" do
      result = Visit.top_locations(5)
      expect(result).to eq([ [ "New York, US", 3 ], [ "London, UK", 2 ] ])
    end
  end

  describe ".top_browsers" do
    before do
      3.times { Visit.create!(ip_address: "1.1.1.1", path: "/", browser: "Chrome") }
      1.times { Visit.create!(ip_address: "2.2.2.2", path: "/", browser: "Firefox") }
    end

    it "returns browsers ordered by count" do
      result = Visit.top_browsers(5)
      expect(result).to eq([ [ "Chrome", 3 ], [ "Firefox", 1 ] ])
    end
  end

  describe ".create_from_request" do
    let(:request) do
      instance_double(
        ActionDispatch::Request,
        remote_ip: "8.8.8.8",
        path: "/posts/hello",
        referrer: "https://google.com",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      )
    end

    it "creates a visit from a request object" do
      visit = Visit.create_from_request(request)
      expect(visit).to be_persisted
      expect(visit.ip_address).to eq("8.8.8.8")
      expect(visit.path).to eq("/posts/hello")
      expect(visit.referrer).to eq("https://google.com")
      expect(visit.browser).to eq("Chrome")
      expect(visit.device_type).to eq("Desktop")
      expect(visit.os).to eq("Mac OS X")
    end
  end

  describe "geocoding" do
    it "geocodes by ip_address" do
      expect(Visit.new).to respond_to(:latitude)
      expect(Visit.new).to respond_to(:longitude)
    end
  end
end
