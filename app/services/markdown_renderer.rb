class MarkdownRenderer
  EXTENSIONS = {
    autolink: true,
    fenced_code_blocks: true,
    tables: true,
    strikethrough: true,
    no_intra_emphasis: true,
    lax_spacing: true
  }.freeze

  ALLOWED_TAGS = %w[
    p br h1 h2 h3 h4 h5 h6 ul ol li a img pre code
    em strong blockquote table thead tbody tr th td del hr span
  ].freeze

  ALLOWED_ATTRIBUTES = %w[href src alt title class target rel style].freeze

  class HTMLRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      lang = ERB::Util.html_escape(language || "plaintext")
      %(<pre><code class="language-#{lang}">#{ERB::Util.html_escape(code)}</code></pre>)
    end
  end

  class HighlightedRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      lexer = Rouge::Lexer.find_fancy(language) || Rouge::Lexers::PlainText.new
      formatter = Rouge::Formatters::HTMLInline.new(Rouge::Theme.find("base16.solarized"))
      formatted = formatter.format(lexer.lex(code))
      %(<pre class="highlight"><code>#{formatted}</code></pre>)
    end
  end

  def self.render(markdown)
    return "" if markdown.blank?

    renderer = HTMLRenderer.new(filter_html: true, hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" })
    html = Redcarpet::Markdown.new(renderer, **EXTENSIONS).render(markdown)
    sanitize(html).html_safe
  end

  def self.render_with_highlighting(markdown)
    return "" if markdown.blank?

    renderer = HighlightedRenderer.new(filter_html: true, hard_wrap: true,
                                       link_attributes: { target: "_blank", rel: "noopener" })
    html = Redcarpet::Markdown.new(renderer, **EXTENSIONS).render(markdown)
    sanitize(html).html_safe
  end

  def self.sanitize(html)
    Rails::HTML5::SafeListSanitizer.new.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
  end
  private_class_method :sanitize
end
