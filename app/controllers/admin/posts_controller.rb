module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[show edit update destroy]

    def index
      @posts = Post.recent
    end

    def show
    end

    def new
      @post = Post.new
    end

    def create
      @post = Post.new(post_params)
      set_published_at_if_needed

      if @post.save
        redirect_to admin_posts_path, notice: "Post was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @post.assign_attributes(post_params)
      set_published_at_if_needed

      if @post.save
        redirect_to admin_posts_path, notice: "Post was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "Post was successfully deleted."
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :excerpt, :body, :status, :published_at)
    end

    def set_published_at_if_needed
      if @post.published? && @post.published_at.blank?
        @post.published_at = Time.current
      end
    end
  end
end
