class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  after_action :track_visit

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def track_visit
    return if bot_request?
    return if health_check?
    return if excluded_path?

    Visit.create_from_request(request)
  rescue StandardError => e
    Rails.logger.warn("Visit tracking failed: #{e.message}")
  end

  def bot_request?
    ua = request.user_agent.to_s
    ua.match?(/bot|crawl|spider|slurp|baiduspider|yandex|duckduckbot|facebookexternalhit|twitterbot|linkedinbot|embedly|quora|pinterest|semrush|ahrefs|python|curl|wget|httpx|scrapy/i)
  end

  def health_check?
    request.path == "/up"
  end

  def excluded_path?
    request.path.start_with?("/api/", "/admin", "/login") ||
      request.path == "/logout"
  end
end
