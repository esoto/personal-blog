require "rails_helper"

RSpec.describe "Comments", type: :request do
  let!(:published_post) do
    Post.create!(
      title: "Commentable Post",
      body_markdown: "# Content",
      status: :published,
      published_at: 1.day.ago,
      excerpt: "A post for commenting"
    )
  end

  let(:valid_comment_params) do
    {
      comment: {
        author_name: "Jane Doe",
        email: "jane@example.com",
        body: "Great article, thanks for sharing!"
      }
    }
  end

  describe "POST /posts/:slug/comments" do
    context "with valid params" do
      it "creates a new comment" do
        expect {
          post post_comments_path(slug: published_post.slug), params: valid_comment_params
        }.to change(Comment, :count).by(1)
      end

      it "saves the comment as pending" do
        post post_comments_path(slug: published_post.slug), params: valid_comment_params
        expect(Comment.last).to be_pending
      end

      it "associates the comment with the post" do
        post post_comments_path(slug: published_post.slug), params: valid_comment_params
        expect(Comment.last.post).to eq(published_post)
      end

      it "responds with turbo stream when requested" do
        post post_comments_path(slug: published_post.slug),
             params: valid_comment_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "shows success message in turbo stream response" do
        post post_comments_path(slug: published_post.slug),
             params: valid_comment_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("Thank you for your comment")
        expect(response.body).to include("awaiting moderation")
      end

      it "redirects with notice for HTML requests" do
        post post_comments_path(slug: published_post.slug), params: valid_comment_params

        expect(response).to redirect_to(post_show_path(slug: published_post.slug))
        follow_redirect!
        expect(response.body).to include("Comment submitted for moderation")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          comment: {
            author_name: "",
            email: "not-an-email",
            body: ""
          }
        }
      end

      it "does not create a comment" do
        expect {
          post post_comments_path(slug: published_post.slug), params: invalid_params
        }.not_to change(Comment, :count)
      end

      it "re-renders the form with errors via turbo stream" do
        post post_comments_path(slug: published_post.slug),
             params: invalid_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("can&#39;t be blank")
      end

      it "redirects with alert for HTML requests" do
        post post_comments_path(slug: published_post.slug), params: invalid_params

        expect(response).to redirect_to(post_show_path(slug: published_post.slug))
      end
    end

    context "with honeypot field filled (bot detection)" do
      it "does not create a comment" do
        expect {
          post post_comments_path(slug: published_post.slug),
               params: valid_comment_params.merge(website: "http://spam.example.com")
        }.not_to change(Comment, :count)
      end

      it "returns 200 to fool bots" do
        post post_comments_path(slug: published_post.slug),
             params: valid_comment_params.merge(website: "http://spam.example.com")

        expect(response).to have_http_status(:ok)
      end
    end

    context "with a draft post" do
      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          body_markdown: "# Content",
          status: :draft,
          excerpt: "Not published yet"
        )
      end

      it "returns 404" do
        post post_comments_path(slug: draft_post.slug), params: valid_comment_params

        expect(response).to have_http_status(:not_found)
      end

      it "does not create a comment" do
        expect {
          post post_comments_path(slug: draft_post.slug), params: valid_comment_params
        }.not_to change(Comment, :count)
      end
    end

    context "with a non-existent post" do
      it "returns 404" do
        post post_comments_path(slug: "nonexistent"), params: valid_comment_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /posts/:slug (comments display)" do
    context "with approved comments" do
      let!(:approved_comment) do
        Comment.create!(
          author_name: "Approved User",
          email: "approved@example.com",
          body: "This is an approved comment",
          post: published_post,
          status: :approved
        )
      end

      let!(:pending_comment) do
        Comment.create!(
          author_name: "Pending User",
          email: "pending@example.com",
          body: "This is a pending comment",
          post: published_post,
          status: :pending
        )
      end

      let!(:spam_comment) do
        Comment.create!(
          author_name: "Spam Bot",
          email: "spam@example.com",
          body: "Buy cheap stuff now",
          post: published_post,
          status: :spam
        )
      end

      it "displays approved comments" do
        get post_show_path(slug: published_post.slug)

        expect(response.body).to include("Approved User")
        expect(response.body).to include("This is an approved comment")
      end

      it "does not display pending comments" do
        get post_show_path(slug: published_post.slug)

        expect(response.body).not_to include("Pending User")
        expect(response.body).not_to include("This is a pending comment")
      end

      it "does not display spam comments" do
        get post_show_path(slug: published_post.slug)

        expect(response.body).not_to include("Spam Bot")
        expect(response.body).not_to include("Buy cheap stuff now")
      end

      it "shows the comment count" do
        get post_show_path(slug: published_post.slug)

        expect(response.body).to include("1 Comment")
      end
    end

    context "with no approved comments" do
      it "does not show comment count heading" do
        get post_show_path(slug: published_post.slug)

        expect(response.body).not_to include("Comments")
      end
    end

    context "with multiple approved comments" do
      before do
        3.times do |i|
          Comment.create!(
            author_name: "User #{i}",
            email: "user#{i}@example.com",
            body: "Comment body #{i}",
            post: published_post,
            status: :approved
          )
        end
      end

      it "shows pluralized comment count" do
        get post_show_path(slug: published_post.slug)

        expect(response.body).to include("3 Comments")
      end
    end

    it "displays the comment form" do
      get post_show_path(slug: published_post.slug)

      expect(response.body).to include("Leave a Comment")
      expect(response.body).to include("comment_form")
    end

    it "includes the honeypot field" do
      get post_show_path(slug: published_post.slug)

      expect(response.body).to include('name="website"')
    end
  end
end
