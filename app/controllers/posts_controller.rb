class PostsController < ApplicationController
  def index
    @posts = Post.published.recent.includes(:tags)
    @page = (params[:page] || 1).to_i
    @per_page = 10
    @total_posts = @posts.count
    @posts = @posts.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    @post = Post.published.find_by!(slug: params[:slug])
  end
end
