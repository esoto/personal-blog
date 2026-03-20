require "rails_helper"

RSpec.describe "Admin::Comments", type: :request do
  let!(:user) { User.create!(email: "admin@example.com", password: "password12345", password_confirmation: "password12345") }
  let!(:blog_post) { Post.create!(title: "Test Post", status: :published, published_at: 1.day.ago) }

  let(:valid_comment_attrs) do
    { author_name: "Jane Doe", email: "jane@example.com", body: "Great post!", post: blog_post }
  end

  before do
    post login_path, params: { email: "admin@example.com", password: "password12345" }
  end

  describe "GET /admin/comments" do
    it "renders the index page" do
      get admin_comments_path
      expect(response).to have_http_status(:ok)
    end

    it "defaults to showing pending comments" do
      Comment.create!(valid_comment_attrs.merge(author_name: "Pending User"))
      Comment.create!(valid_comment_attrs.merge(author_name: "Approved User", status: :approved))

      get admin_comments_path
      expect(response.body).to include("Pending User")
      expect(response.body).not_to include("Approved User")
    end

    it "filters by pending status" do
      Comment.create!(valid_comment_attrs.merge(author_name: "Pending User"))
      Comment.create!(valid_comment_attrs.merge(author_name: "Approved User", status: :approved))

      get admin_comments_path(status: "pending")
      expect(response.body).to include("Pending User")
      expect(response.body).not_to include("Approved User")
    end

    it "filters by approved status" do
      Comment.create!(valid_comment_attrs.merge(author_name: "Pending User"))
      Comment.create!(valid_comment_attrs.merge(author_name: "Approved User", status: :approved))

      get admin_comments_path(status: "approved")
      expect(response.body).to include("Approved User")
      expect(response.body).not_to include("Pending User")
    end

    it "filters by spam status" do
      Comment.create!(valid_comment_attrs.merge(author_name: "Pending User"))
      Comment.create!(valid_comment_attrs.merge(author_name: "Spam User", status: :spam))

      get admin_comments_path(status: "spam")
      expect(response.body).to include("Spam User")
      expect(response.body).not_to include("Pending User")
    end

    it "falls back to pending for invalid status parameter" do
      Comment.create!(valid_comment_attrs.merge(author_name: "Pending User"))

      get admin_comments_path(status: "invalid")
      expect(response.body).to include("Pending User")
    end

    it "displays comment details" do
      Comment.create!(valid_comment_attrs)

      get admin_comments_path
      expect(response.body).to include("Jane Doe")
      expect(response.body).to include("jane@example.com")
      expect(response.body).to include("Great post!")
      expect(response.body).to include("Test Post")
    end

    it "displays status filter tabs with counts" do
      Comment.create!(valid_comment_attrs)
      Comment.create!(valid_comment_attrs.merge(author_name: "Bob", status: :approved))

      get admin_comments_path
      expect(response.body).to include("Pending (1)")
      expect(response.body).to include("Approved (1)")
      expect(response.body).to include("Spam (0)")
    end

    it "shows empty state when no comments match the filter" do
      get admin_comments_path(status: "spam")
      expect(response.body).to include("No spam comments")
    end
  end

  describe "PATCH /admin/comments/:id/approve" do
    it "changes comment status to approved" do
      comment = Comment.create!(valid_comment_attrs)
      expect(comment).to be_pending

      patch approve_admin_comment_path(comment)
      expect(comment.reload).to be_approved
    end

    it "redirects back with a notice" do
      comment = Comment.create!(valid_comment_attrs)

      patch approve_admin_comment_path(comment)
      expect(response).to redirect_to(admin_comments_path)
      follow_redirect!
      expect(response.body).to include("Comment approved")
    end

    it "can approve a spam comment" do
      comment = Comment.create!(valid_comment_attrs.merge(status: :spam))

      patch approve_admin_comment_path(comment)
      expect(comment.reload).to be_approved
    end
  end

  describe "PATCH /admin/comments/:id/spam" do
    it "changes comment status to spam" do
      comment = Comment.create!(valid_comment_attrs)

      patch spam_admin_comment_path(comment)
      expect(comment.reload).to be_spam
    end

    it "redirects back with a notice" do
      comment = Comment.create!(valid_comment_attrs)

      patch spam_admin_comment_path(comment)
      expect(response).to redirect_to(admin_comments_path)
      follow_redirect!
      expect(response.body).to include("Comment marked as spam")
    end

    it "can mark an approved comment as spam" do
      comment = Comment.create!(valid_comment_attrs.merge(status: :approved))

      patch spam_admin_comment_path(comment)
      expect(comment.reload).to be_spam
    end
  end

  describe "DELETE /admin/comments/:id" do
    it "destroys the comment" do
      comment = Comment.create!(valid_comment_attrs)

      expect {
        delete admin_comment_path(comment)
      }.to change(Comment, :count).by(-1)
    end

    it "redirects back with a notice" do
      comment = Comment.create!(valid_comment_attrs)

      delete admin_comment_path(comment)
      expect(response).to redirect_to(admin_comments_path)
      follow_redirect!
      expect(response.body).to include("Comment deleted")
    end
  end

  describe "authentication" do
    before { delete logout_path }

    it "redirects unauthenticated users to login for index" do
      get admin_comments_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects unauthenticated users to login for approve" do
      comment = Comment.create!(valid_comment_attrs)
      patch approve_admin_comment_path(comment)
      expect(response).to redirect_to(login_path)
    end

    it "redirects unauthenticated users to login for spam" do
      comment = Comment.create!(valid_comment_attrs)
      patch spam_admin_comment_path(comment)
      expect(response).to redirect_to(login_path)
    end

    it "redirects unauthenticated users to login for destroy" do
      comment = Comment.create!(valid_comment_attrs)
      delete admin_comment_path(comment)
      expect(response).to redirect_to(login_path)
    end
  end
end
