require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { User.create!(email: "admin@example.com", password: "password12345", password_confirmation: "password12345") }

  describe "GET /login" do
    it "renders the login form" do
      get login_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "logs in and redirects to admin root" do
        post login_path, params: { email: "admin@example.com", password: "password12345" }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(admin_root_path)
      end
    end

    context "with invalid credentials" do
      it "re-renders login with an error" do
        post login_path, params: { email: "admin@example.com", password: "wrong" }
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /logout" do
    it "logs out and redirects to root" do
      post login_path, params: { email: "admin@example.com", password: "password12345" }
      delete logout_path
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
