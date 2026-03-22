module Api
  class BaseController < ActionController::API
    rate_limit to: 60, within: 1.minute

    before_action :authenticate_api_token

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found" }, status: :not_found
    end

    rescue_from ActionController::TooManyRequests do
      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
    end

    private

    def authenticate_api_token
      auth_header = request.headers["Authorization"]
      token = auth_header&.start_with?("Bearer ") ? auth_header.delete_prefix("Bearer ") : nil
      api_token = ENV["BLOG_API_TOKEN"]

      unless api_token.present? && token.present? && ActiveSupport::SecurityUtils.secure_compare(token, api_token)
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
