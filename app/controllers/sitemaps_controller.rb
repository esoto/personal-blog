class SitemapsController < ApplicationController
  def show
    @posts = Post.published.recent
    @tags = Tag.order(:name)
    expires_in 1.hour, public: true
    fresh_when(
      etag: [@posts, @tags],
      last_modified: [@posts.maximum(:updated_at), @tags.maximum(:updated_at)].compact.max
    )
  end
end
