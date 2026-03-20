require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /up" do
    it "returns 200 when the app is healthy" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end

    it "renders HTML content" do
      get rails_health_check_path
      expect(response.content_type).to include("text/html")
    end
  end
end
