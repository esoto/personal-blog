module ApplicationHelper
  # theme: :public uses the emerald primary accent (default).
  # theme: :admin uses the blue secondary accent so admin nav stays
  # distinct from the public site per the design system roadmap.
  def nav_link_class(path, prefix_match: false, theme: :public)
    active = if prefix_match
               request.path == path || request.path.start_with?("#{path}/")
    else
               current_page?(path)
    end
    accent = theme == :admin ? "accent-blue" : "accent-green"
    if active
      "text-#{accent} font-semibold transition-fast"
    else
      "text-text-secondary hover:text-#{accent} transition-fast"
    end
  end
end
