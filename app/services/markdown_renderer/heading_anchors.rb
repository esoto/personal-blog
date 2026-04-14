class MarkdownRenderer
  # ------------------------------------------------------------------
  # HeadingAnchors — emits slug IDs on h2/h3 headings so the sticky
  # TOC and deep links have anchors to target.
  # ------------------------------------------------------------------
  # Included into both HTMLRenderer and HighlightedRenderer. Tracks
  # slug collisions per renderer instance — a fresh instance is
  # created for each render pass, so counters reset automatically.
  # ------------------------------------------------------------------
  module HeadingAnchors
    ANCHORED_LEVELS = [ 2, 3 ].freeze

    def header(text, header_level)
      return "<h#{header_level}>#{text}</h#{header_level}>\n" unless ANCHORED_LEVELS.include?(header_level)

      slug = unique_slug_for(text)
      %(<h#{header_level} id="#{slug}">#{text}</h#{header_level}>\n)
    end

    private

    # Track emitted slugs (not just bases) so that a natural
    # "Setup 1" heading followed by two "Setup" headings doesn't
    # wrap around and collide with "setup-1".
    def unique_slug_for(text)
      base = text.to_s.parameterize.presence || "section"
      @heading_slug_counts ||= Hash.new(0)
      @heading_slug_emitted ||= Set.new

      loop do
        count = @heading_slug_counts[base]
        candidate = count.zero? ? base : "#{base}-#{count}"
        @heading_slug_counts[base] += 1
        unless @heading_slug_emitted.include?(candidate)
          @heading_slug_emitted << candidate
          return candidate
        end
      end
    end
  end
end
