module ApplicationHelper
  def nav_link_class(path, prefix_match: false)
    active = prefix_match ? request.path.start_with?(path) : current_page?(path)
    if active
      "text-accent-blue font-semibold transition-fast"
    else
      "text-text-secondary hover:text-accent-blue transition-fast"
    end
  end
end
