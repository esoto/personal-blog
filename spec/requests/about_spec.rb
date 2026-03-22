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

    it "displays profile content" do
      get about_path
      expect(response.body).to include("Esteban Soto")
      expect(response.body).to include("full-stack developer")
    end

    it "includes Open Graph meta tags" do
      get about_path
      expect(response.body).to include('property="og:title" content="About')
      expect(response.body).to include('property="og:description" content="Full-stack developer building with Ruby and JavaScript."')
      expect(response.body).to include('property="og:type" content="website"')
      expect(response.body).to include('property="og:url"')
    end

    it "includes Twitter Card meta tags" do
      get about_path
      expect(response.body).to include('name="twitter:card" content="summary"')
      expect(response.body).to include('name="twitter:title" content="About')
      expect(response.body).to include('name="twitter:description" content="Full-stack developer building with Ruby and JavaScript."')
    end

    it "includes a canonical URL" do
      get about_path
      expect(response.body).to include('rel="canonical"')
    end

    it "includes JSON-LD structured data for Person" do
      get about_path
      expect(response.body).to include('application/ld+json')
      expect(response.body).to include('"@type":"Person"')
      expect(response.body).to include('"name":"Esteban Soto"')
    end

    it "includes a link back to the homepage" do
      get about_path
      expect(response.body).to include(root_path)
    end

    it "includes real social links" do
      get about_path
      expect(response.body).to include("https://github.com/esoto")
      expect(response.body).to include("https://www.linkedin.com/in/soto-esteban/")
    end
  end
end
