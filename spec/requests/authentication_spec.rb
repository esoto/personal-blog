require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "accessing admin routes without authentication" do
    it "redirects to login" do
      get admin_root_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "accessing admin routes while authenticated" do
    let!(:user) { User.create!(email: "admin@example.com", password: "password123", password_confirmation: "password123") }

    it "allows access" do
      post login_path, params: { email: "admin@example.com", password: "password123" }
      get admin_root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
