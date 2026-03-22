module Api
  class BaseController < ActionController::API
    rate_limit to: 60, within: 1.minute

    before_action :authenticate_api_token

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found" }, status: :not_found
    end

    private

    def authenticate_api_token
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")
      api_token = ENV["BLOG_API_TOKEN"]

      unless api_token.present? && token.present? && ActiveSupport::SecurityUtils.secure_compare(token, api_token)
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
