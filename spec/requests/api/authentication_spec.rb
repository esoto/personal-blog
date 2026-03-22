require "rails_helper"

RSpec.describe "API Authentication", type: :request do
  around do |example|
    original = ENV["BLOG_API_TOKEN"]
    ENV["BLOG_API_TOKEN"] = "test-api-token"
    example.run
  ensure
    original ? ENV["BLOG_API_TOKEN"] = original : ENV.delete("BLOG_API_TOKEN")
  end

  describe "token validation" do
    it "returns 401 when no Authorization header is provided" do
      get "/api/v1/stats"
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Unauthorized")
    end

    it "returns 401 when Authorization header has wrong scheme" do
      get "/api/v1/stats", headers: { "Authorization" => "Basic test-api-token" }
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Unauthorized")
    end

    it "returns 401 when token is sent without Bearer scheme" do
      get "/api/v1/stats", headers: { "Authorization" => "test-api-token" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when token is invalid" do
      get "/api/v1/stats", headers: api_headers("wrong-token")
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Unauthorized")
    end

    it "returns 401 when Authorization header is empty" do
      get "/api/v1/stats", headers: { "Authorization" => "" }
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Unauthorized")
    end

    it "returns 401 when Bearer scheme has no token" do
      get "/api/v1/stats", headers: { "Authorization" => "Bearer " }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when BLOG_API_TOKEN is not set" do
      ENV.delete("BLOG_API_TOKEN")
      get "/api/v1/stats", headers: api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 200 with valid token" do
      get "/api/v1/stats", headers: api_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON content type" do
      get "/api/v1/stats", headers: api_headers
      expect(response.content_type).to include("application/json")
    end
  end
end
