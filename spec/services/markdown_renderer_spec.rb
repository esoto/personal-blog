require "rails_helper"

RSpec.describe MarkdownRenderer do
  describe ".render" do
    it "converts markdown headings to HTML" do
      result = described_class.render("# Hello")
      expect(result).to include("<h1>Hello</h1>")
    end

    it "converts bold text" do
      result = described_class.render("**bold**")
      expect(result).to include("<strong>bold</strong>")
    end

    it "converts code blocks to pre/code tags" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include("<pre>")
      expect(result).to include("<code")
    end

    it "converts inline code" do
      result = described_class.render("Use `foo` here")
      expect(result).to include("<code>foo</code>")
    end

    it "converts links" do
      result = described_class.render("[click](https://example.com)")
      expect(result).to include('<a href="https://example.com"')
    end

    it "returns empty string for nil input" do
      expect(described_class.render(nil)).to eq("")
    end

    it "returns empty string for blank input" do
      expect(described_class.render("")).to eq("")
    end

    it "enables tables" do
      md = "| A | B |\n|---|---|\n| 1 | 2 |"
      result = described_class.render(md)
      expect(result).to include("<table>")
    end

    it "enables autolinks" do
      result = described_class.render("Visit https://example.com")
      expect(result).to include('<a href="https://example.com"')
    end
  end

  describe ".render_with_highlighting" do
    it "syntax highlights code blocks" do
      result = described_class.render_with_highlighting("```ruby\nputs 'hi'\n```")
      expect(result).to include("highlight")
    end

    it "falls back to plain code for unknown languages" do
      result = described_class.render_with_highlighting("```\nplain code\n```")
      expect(result).to include("<pre")
      expect(result).to include("<code>")
    end
  end
end
