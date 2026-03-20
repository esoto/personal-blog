class FeedsController < ApplicationController
  def index
    @posts = Post.published.recent.limit(20)
    expires_in 1.hour, public: true
  end
end
