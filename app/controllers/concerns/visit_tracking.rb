module VisitTracking
  extend ActiveSupport::Concern

  included do
    after_action :track_visit
  end

  private

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
    request.path.start_with?("/admin", "/login") ||
      request.path == "/logout"
  end
end
