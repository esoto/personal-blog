class MarkdownRenderer
  # ------------------------------------------------------------------
  # Sanitizer — final line of defense against XSS in rendered markdown.
  # ------------------------------------------------------------------
  # Allow-lists are split per-feature so each new component's security
  # footprint can be audited in isolation. Adding a feature means
  # appending one constant here, not hunting through a flat list.
  # ------------------------------------------------------------------
  module Sanitizer
    BASE_TAGS = %w[
      p br h1 h2 h3 h4 h5 h6 ul ol li a img
      em strong blockquote del hr span div
      table thead tbody tr th td
    ].freeze

    CODE_BLOCK_TAGS = %w[pre code figure figcaption button].freeze
    CALLOUT_TAGS    = %w[aside].freeze
    SVG_TAGS        = %w[svg path circle line polyline rect].freeze

    ALLOWED_TAGS = (BASE_TAGS + CODE_BLOCK_TAGS + CALLOUT_TAGS + SVG_TAGS).freeze

    BASE_ATTRIBUTES = %w[href src alt title class target rel style].freeze
    STIMULUS_ATTRIBUTES = %w[data-controller data-action data-clipboard-target].freeze
    A11Y_ATTRIBUTES = %w[aria-label aria-hidden role type].freeze
    SVG_ATTRIBUTES = %w[
      viewBox fill stroke stroke-width stroke-linecap stroke-linejoin
      d x y x1 y1 x2 y2 cx cy r rx ry points width height
    ].freeze

    ALLOWED_ATTRIBUTES = (BASE_ATTRIBUTES + STIMULUS_ATTRIBUTES + A11Y_ATTRIBUTES + SVG_ATTRIBUTES).freeze

    def self.sanitize(html)
      Rails::HTML5::SafeListSanitizer.new.sanitize(
        html,
        tags: ALLOWED_TAGS,
        attributes: ALLOWED_ATTRIBUTES
      )
    end
  end
end
