require "rails_helper"

RSpec.describe "Admin Posts Preview", type: :request do
  let!(:user) { User.create!(email: "admin@example.com", password: "password12345", password_confirmation: "password12345") }

  before { post login_path, params: { email: user.email, password: "password12345" } }

  describe "POST /admin/posts/preview" do
    it "renders markdown as highlighted HTML" do
      post admin_posts_preview_path, params: { markdown: "# Hello" },
                                     headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<h1>Hello</h1>")
    end

    it "returns highlighted code blocks" do
      post admin_posts_preview_path, params: { markdown: "```ruby\nputs 'hi'\n```" },
                                     headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("highlight")
    end

    it "returns empty for blank markdown" do
      post admin_posts_preview_path, params: { markdown: "" },
                                     headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("")
    end

    it "requires authentication" do
      delete logout_path
      post admin_posts_preview_path, params: { markdown: "# Hello" }
      expect(response).to redirect_to(login_path)
    end
  end
end
