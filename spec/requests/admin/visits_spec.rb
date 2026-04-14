require "rails_helper"

RSpec.describe "Admin::Visits", type: :request do
  let!(:user) { User.create!(email: "admin@example.com", password: "password12345", password_confirmation: "password12345") }

  before do
    post login_path, params: { email: "admin@example.com", password: "password12345" }
  end

  describe "GET /admin/visits" do
    before do
      Visit.create!(ip_address: "1.1.1.1", path: "/", browser: "Chrome", device_type: "Desktop", country: "US", city: "New York", referrer: "https://google.com")
      Visit.create!(ip_address: "2.2.2.2", path: "/about", browser: "Firefox", device_type: "Mobile", country: "UK", city: "London")
    end

    it "renders successfully" do
      get admin_visits_path
      expect(response).to have_http_status(:ok)
    end

    it "displays visit count stats" do
      get admin_visits_path
      expect(response.body).to include("Total Visits")
    end

    it "requires authentication" do
      delete logout_path
      get admin_visits_path
      expect(response).to redirect_to(login_path)
    end

    it "renders the paginator when total visits exceed one page" do
      # More than the per_page=25 default so @visits.total_pages > 1
      26.times do |i|
        Visit.create!(ip_address: "10.0.0.#{i + 1}", path: "/x/#{i}", browser: "Chrome", device_type: "Desktop")
      end
      get admin_visits_path
      expect(response).to have_http_status(:ok)
      # The custom paginator emits <nav role="navigation" aria-label="pager">
      expect(response.body).to include('aria-label="pager"')
    end
  end
end
