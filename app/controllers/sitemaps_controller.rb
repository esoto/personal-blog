class SitemapsController < ApplicationController
  def show
    @posts = Post.published.recent
    @tags = Tag.all
    fresh_when(etag: @posts, last_modified: @posts.maximum(:updated_at))
    expires_in 1.hour, public: true
  end
end
