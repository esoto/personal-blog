require "rails_helper"

RSpec.describe "About Page", type: :request do
  describe "GET /about" do
    it "returns 200" do
      get about_path
      expect(response).to have_http_status(:ok)
    end

    it "sets the page title" do
      get about_path
      expect(response.body).to include("<title>About")
    end

    it "displays a bio section" do
      get about_path
      expect(response.body).to include("About Me")
    end

    it "displays placeholder profile content" do
      get about_path
      expect(response.body).to include("Software Engineer")
    end

    it "includes Open Graph meta tags" do
      get about_path
      expect(response.body).to include('property="og:title"')
      expect(response.body).to include('property="og:description"')
    end

    it "includes a link back to the homepage" do
      get about_path
      expect(response.body).to include(root_path)
    end
  end
end
