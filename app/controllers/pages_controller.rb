class PagesController < ApplicationController
  def home
    @posts = Post.published.recent.limit(5).includes(:tags).with_rich_text_body
  end

  def about
  end
end
