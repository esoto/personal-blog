module ApiHelpers
  def api_headers(token = "test-api-token")
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
