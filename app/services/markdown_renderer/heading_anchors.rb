require "cgi"

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

    # Redcarpet passes the already-rendered inner HTML to `header`, which
    # means inline tags (e.g. <code>) and escaped entities (&#39;, &amp;,
    # &quot;) land here. We strip tags first, then unescape entities, so
    # the input to `parameterize` is clean display text. Order matters —
    # unescaping before stripping could turn an entity-encoded tag into a
    # real one. We also strip apostrophes before parameterize so `What's`
    # becomes `whats` (GitHub-style) rather than `what-s`.
    def unique_slug_for(text)
      cleaned = CGI.unescapeHTML(text.to_s.gsub(/<[^>]*>/, ""))
      cleaned = cleaned.gsub(/['']/, "")
      base = cleaned.parameterize.presence || "section"
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
