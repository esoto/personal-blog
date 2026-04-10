require "rails_helper"

RSpec.describe "Visit Tracking", type: :request do
  describe "automatic tracking on public pages" do
    it "creates a visit for the home page" do
      expect { get root_path }.to change(Visit, :count).by(1)
    end

    it "records the request path" do
      get root_path
      expect(Visit.last.path).to eq("/")
    end

    it "records the referrer" do
      get root_path, headers: { "HTTP_REFERER" => "https://google.com" }
      expect(Visit.last.referrer).to eq("https://google.com")
    end

    it "records the user agent" do
      get root_path, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 Chrome/120" }
      expect(Visit.last.user_agent).to eq("Mozilla/5.0 Chrome/120")
    end

    it "tracks visits with no user agent" do
      expect {
        get root_path, headers: { "HTTP_USER_AGENT" => "" }
      }.to change(Visit, :count).by(1)
    end
  end

  describe "bot filtering" do
    it "does not track Googlebot" do
      expect {
        get root_path, headers: { "HTTP_USER_AGENT" => "Googlebot/2.1" }
      }.not_to change(Visit, :count)
    end

    it "does not track bingbot" do
      expect {
        get root_path, headers: { "HTTP_USER_AGENT" => "bingbot/2.0" }
      }.not_to change(Visit, :count)
    end

    it "does not track generic bots" do
      expect {
        get root_path, headers: { "HTTP_USER_AGENT" => "Python-urllib/3.9" }
      }.not_to change(Visit, :count)
    end

    it "does not track curl" do
      expect {
        get root_path, headers: { "HTTP_USER_AGENT" => "curl/7.88.1" }
      }.not_to change(Visit, :count)
    end

    it "does not track wget" do
      expect {
        get root_path, headers: { "HTTP_USER_AGENT" => "Wget/1.21.4" }
      }.not_to change(Visit, :count)
    end
  end

  describe "excluded routes" do
    it "does not track the health check endpoint" do
      expect {
        get rails_health_check_path
      }.not_to change(Visit, :count)
    end

    it "does not track admin requests" do
      user = User.create!(email: "admin@example.com", password: "password12345", password_confirmation: "password12345")
      post login_path, params: { email: "admin@example.com", password: "password12345" }
      expect {
        get admin_root_path
      }.not_to change(Visit, :count)
    end

    it "does not track login page" do
      expect {
        get login_path
      }.not_to change(Visit, :count)
    end
  end

  describe "error resilience" do
    it "does not break page loads when tracking fails" do
      allow(Visit).to receive(:create_from_request).and_raise(StandardError, "DB connection lost")
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
