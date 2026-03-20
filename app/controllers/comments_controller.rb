class CommentsController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: :create

  def create
    @post = Post.published.find_by!(slug: params[:slug])

    if honeypot_filled?
      head :ok
      return
    end

    @comment = @post.comments.build(comment_params)

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to post_show_path(slug: @post.slug), notice: "Comment submitted for moderation." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_form", partial: "posts/comment_form", locals: { post: @post, comment: @comment }), status: :unprocessable_entity }
        format.html { redirect_to post_show_path(slug: @post.slug), alert: "Could not submit comment." }
      end
    end
  end

  private

  def comment_params
    params.expect(comment: [ :author_name, :email, :body ])
  end

  def honeypot_filled?
    params[:website].present?
  end
end
