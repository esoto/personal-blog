module ApplicationHelper
  def nav_link_class(path, prefix_match: false)
    active = if prefix_match
               request.path == path || request.path.start_with?("#{path}/")
             else
               current_page?(path)
             end
    if active
      "text-accent-blue font-semibold transition-fast"
    else
      "text-text-secondary hover:text-accent-blue transition-fast"
    end
  end
end
