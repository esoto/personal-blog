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
  end

  describe "excluded routes" do
    it "does not track the health check endpoint" do
      expect {
        get rails_health_check_path
      }.not_to change(Visit, :count)
    end

    it "does not track API requests" do
      expect {
        get api_v1_posts_path, headers: { "Authorization" => "Bearer test-api-token" }
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
end
