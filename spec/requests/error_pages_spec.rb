require "rails_helper"

RSpec.describe "Error Pages", type: :request do
  shared_examples "a themed error page" do |filename, status_code, title_text|
    let(:file_path) { Rails.root.join("public", filename) }
    let(:html) { File.read(file_path) }

    it "exists as a static file" do
      expect(File.exist?(file_path)).to be true
    end

    it "uses the dark theme background color" do
      expect(html).to include("background: #0d1117")
    end

    it "uses the dark theme surface color" do
      expect(html).to include("#161b22")
    end

    it "uses the dark theme text color" do
      expect(html).to include("#e6edf3")
    end

    it "uses the dark theme accent color" do
      expect(html).to include("#58a6ff")
    end

    it "uses the dark theme border color" do
      expect(html).to include("#30363d")
    end

    it "includes a Back to home link" do
      expect(html).to include('href="/"')
      expect(html).to include("Back to home")
    end

    it "displays the #{status_code} error code" do
      expect(html).to include(">#{status_code}<")
    end

    it "includes the page title" do
      expect(html).to include(title_text)
    end

    it "uses inline CSS (no external stylesheets)" do
      expect(html).not_to include('rel="stylesheet"')
      expect(html).to include("<style>")
    end

    it "has a terminal-style window" do
      expect(html).to include("terminal-window")
      expect(html).to include("terminal-header")
      expect(html).to include("terminal-body")
    end

    it "uses monospace font for the terminal aesthetic" do
      expect(html).to include("monospace")
    end

    it "includes viewport meta tag for responsive design" do
      expect(html).to include('name="viewport"')
    end

    it "includes noindex meta tag" do
      expect(html).to include("noindex")
    end
  end

  describe "404.html" do
    it_behaves_like "a themed error page", "404.html", "404", "404 - Page Not Found"
  end

  describe "422.html" do
    it_behaves_like "a themed error page", "422.html", "422", "422 - Unprocessable Entity"
  end

  describe "500.html" do
    it_behaves_like "a themed error page", "500.html", "500", "500 - Internal Server Error"
  end
end
