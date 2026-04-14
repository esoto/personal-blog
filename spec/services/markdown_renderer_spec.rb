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

    it "strips javascript: URIs from markdown links" do
      result = described_class.render("[click](javascript:alert(1))")
      expect(result).not_to include("javascript:")
    end

    it "strips data: URIs from markdown links" do
      result = described_class.render("[click](data:text/html,<script>alert(1)</script>)")
      expect(result).not_to include("data:")
    end

    it "preserves legitimate https links" do
      result = described_class.render("[click](https://example.com)")
      expect(result).to include('href="https://example.com"')
    end
  end

  describe ".render — enhanced code block structure" do
    it "wraps code blocks in a figure with the clipboard controller" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('<figure class="code-block"')
      expect(result).to include('data-controller="clipboard"')
    end

    it "includes a figcaption with language label" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('<figcaption class="code-block-header">')
      expect(result).to include('<span class="code-block-language">ruby</span>')
    end

    it "includes a copy button wired to the clipboard controller" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('class="code-block-copy"')
      expect(result).to include('data-clipboard-target="button"')
      expect(result).to include('data-action="click->clipboard#copy"')
    end

    it "includes the copy icon as inline SVG" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('<svg class="code-block-copy-icon"')
    end

    it "falls back to plaintext when language is omitted" do
      result = described_class.render("```\nplain\n```")
      expect(result).to include('<span class="code-block-language">plaintext</span>')
    end

    it "HTML-escapes code contents to prevent injection" do
      result = described_class.render("```html\n<script>alert(1)</script>\n```")
      expect(result).not_to include("<script>alert(1)</script>")
      expect(result).to include("&lt;script&gt;")
    end
  end

  describe ".render — callouts" do
    %w[info tip warning danger].each do |type|
      it "renders a :::#{type} callout as an aside with the callout-#{type} class" do
        md = ":::#{type}\nThis is a #{type} body.\n:::"
        result = described_class.render(md)
        expect(result).to include("<aside")
        expect(result).to include("callout-#{type}")
        expect(result).to include("This is a #{type} body.")
      end

      it "marks the #{type} callout with role=note for accessibility" do
        md = ":::#{type}\nContent\n:::"
        result = described_class.render(md)
        expect(result).to include('role="note"')
      end

      it "includes an inline SVG icon in the #{type} callout" do
        md = ":::#{type}\nContent\n:::"
        result = described_class.render(md)
        expect(result).to include('class="callout-icon"')
      end
    end

    it "renders markdown inside the callout body (bold/links/inline code)" do
      md = <<~MD
        :::tip
        Use **bold** and `code` and [link](https://example.com).
        :::
      MD
      result = described_class.render(md)
      expect(result).to include("<strong>bold</strong>")
      expect(result).to include("<code>code</code>")
      expect(result).to include('href="https://example.com"')
    end

    it "supports multiple callouts in one document" do
      md = <<~MD
        :::info
        First
        :::

        Some paragraph.

        :::warning
        Second
        :::
      MD
      result = described_class.render(md)
      expect(result).to include("callout-info")
      expect(result).to include("callout-warning")
      expect(result).to include("First")
      expect(result).to include("Second")
      expect(result).to include("Some paragraph")
    end

    it "leaves unrecognized callout types untouched (not a known type)" do
      md = ":::bogus\nContent\n:::"
      result = described_class.render(md)
      expect(result).not_to include("callout-bogus")
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

    it "strips javascript: URIs in highlighted renderer" do
      result = described_class.render_with_highlighting("[click](javascript:alert(1))")
      expect(result).not_to include("javascript:")
    end
  end
end
