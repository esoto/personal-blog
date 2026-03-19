module Admin
  class CommentsController < BaseController
    before_action :set_comment, only: %i[approve spam destroy]

    def index
      @status = params[:status].presence_in(Comment.statuses.keys) || "pending"
      @comments = Comment.where(status: @status).includes(:post).recent
      @status_counts = Comment.group(:status).count
    end

    def approve
      @comment.approved!
      redirect_back fallback_location: admin_comments_path, notice: "Comment approved."
    end

    def spam
      @comment.spam!
      redirect_back fallback_location: admin_comments_path, notice: "Comment marked as spam."
    end

    def destroy
      @comment.destroy!
      redirect_back fallback_location: admin_comments_path, notice: "Comment deleted."
    end

    private

    def set_comment
      @comment = Comment.find(params[:id])
    end
  end
end
