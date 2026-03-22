module Api
  module V1
    class CommentsController < Api::BaseController
      before_action :set_comment, only: %i[approve spam destroy]

      def index
        status = Comment.statuses.key?(params[:status]) ? params[:status] : "pending"
        comments = Comment.where(status: status).includes(:post).recent

        if params[:post_slug].present?
          comments = comments.joins(:post).where(posts: { slug: params[:post_slug] })
        end

        render json: {
          comments: comments.map { |comment| comment_json(comment) }
        }
      end

      def approve
        @comment.approved!
        render json: comment_json(@comment)
      end

      def spam
        @comment.spam!
        render json: comment_json(@comment)
      end

      def destroy
        @comment.destroy!
        head :no_content
      end

      private

      def set_comment
        @comment = Comment.find(params[:id])
      end

      def comment_json(comment)
        {
          id: comment.id,
          author_name: comment.author_name,
          body: comment.body,
          status: comment.status,
          post_title: comment.post.title,
          post_slug: comment.post.slug,
          created_at: comment.created_at.iso8601(3)
        }
      end
    end
  end
end
