class PagesController < ApplicationController
  def home
    @posts = Post.published.recent.limit(5).includes(:tags)
  end
end
