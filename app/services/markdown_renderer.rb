class MarkdownRenderer
  EXTENSIONS = {
    autolink: true,
    fenced_code_blocks: true,
    tables: true,
    strikethrough: true,
    no_intra_emphasis: true,
    lax_spacing: true
  }.freeze

  # Redcarpet renderer that wraps fenced code blocks in the shared
  # CodeBlock chrome (figure + figcaption + copy button).
  class HTMLRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      CodeBlock.render(language, ERB::Util.html_escape(code))
    end
  end

  # Redcarpet renderer that reuses the CodeBlock chrome but inserts
  # Rouge-formatted HTML inside. Used by admin editor preview and API
  # endpoints so the preview matches the published post exactly.
  class HighlightedRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      lexer = Rouge::Lexer.find_fancy(language) || Rouge::Lexers::PlainText.new
      formatter = Rouge::Formatters::HTMLInline.new(Rouge::Theme.find("base16.solarized"))
      highlighted = formatter.format(lexer.lex(code))
      CodeBlock.render(language, highlighted)
    end
  end

  def self.render(markdown)
    return "" if markdown.blank?

    preprocessed = Callouts.preprocess(markdown, body_markdown_renderer)
    html = outer_markdown_renderer(HTMLRenderer).render(preprocessed)
    Sanitizer.sanitize(html).html_safe
  end

  def self.render_with_highlighting(markdown)
    return "" if markdown.blank?

    preprocessed = Callouts.preprocess(markdown, body_markdown_renderer)
    html = outer_markdown_renderer(HighlightedRenderer).render(preprocessed)
    Sanitizer.sanitize(html).html_safe
  end

  # One Redcarpet instance per call for the outer document.
  def self.outer_markdown_renderer(renderer_class)
    renderer = renderer_class.new(hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" })
    Redcarpet::Markdown.new(renderer, **EXTENSIONS)
  end
  private_class_method :outer_markdown_renderer

  # Reused across every callout body inside a single render pass.
  # Hoisting this out of the callout loop saves N Redcarpet
  # instantiations on posts with multiple callouts.
  def self.body_markdown_renderer
    body_renderer = HTMLRenderer.new(hard_wrap: false, link_attributes: { target: "_blank", rel: "noopener" })
    Redcarpet::Markdown.new(body_renderer, **EXTENSIONS)
  end
  private_class_method :body_markdown_renderer
end
