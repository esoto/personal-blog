require "rails_helper"

RSpec.describe "Admin::Posts", type: :request do
  let!(:user) { User.create!(email: "admin@example.com", password: "password123", password_confirmation: "password123") }

  before do
    post login_path, params: { email: "admin@example.com", password: "password123" }
  end

  describe "GET /admin/posts" do
    it "renders the index page" do
      get admin_posts_path
      expect(response).to have_http_status(:ok)
    end

    it "displays all posts" do
      Post.create!(title: "Draft Post", status: :draft)
      Post.create!(title: "Published Post", status: :published, published_at: 1.day.ago)

      get admin_posts_path
      expect(response.body).to include("Draft Post")
      expect(response.body).to include("Published Post")
    end
  end

  describe "GET /admin/posts/new" do
    it "renders the new post form" do
      get new_admin_post_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/posts" do
    context "with valid params" do
      it "creates a post and redirects to index" do
        expect {
          post admin_posts_path, params: { post: { title: "New Post", excerpt: "A summary", status: "draft" } }
        }.to change(Post, :count).by(1)
        expect(response).to redirect_to(admin_posts_path)
        follow_redirect!
        expect(response.body).to include("New Post")
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        expect {
          post admin_posts_path, params: { post: { title: "", status: "draft" } }
        }.not_to change(Post, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when publishing without published_at" do
      it "auto-sets published_at to current time" do
        freeze_time do
          post admin_posts_path, params: { post: { title: "Auto Publish", status: "published" } }
          created_post = Post.last
          expect(created_post.published_at).to eq(Time.current)
        end
      end
    end
  end

  describe "GET /admin/posts/:id" do
    it "renders the post detail" do
      blog_post = Post.create!(title: "Show Post", status: :draft)
      get admin_post_path(blog_post)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Show Post")
    end
  end

  describe "GET /admin/posts/:id/edit" do
    it "renders the edit form" do
      blog_post = Post.create!(title: "Edit Me", status: :draft)
      get edit_admin_post_path(blog_post)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/posts/:id" do
    let!(:blog_post) { Post.create!(title: "Original Title", status: :draft) }

    context "with valid params" do
      it "updates the post and redirects to index" do
        patch admin_post_path(blog_post), params: { post: { title: "Updated Title" } }
        expect(response).to redirect_to(admin_posts_path)
        expect(blog_post.reload.title).to eq("Updated Title")
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        patch admin_post_path(blog_post), params: { post: { title: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(blog_post.reload.title).to eq("Original Title")
      end
    end

    context "when publishing without published_at" do
      it "auto-sets published_at to current time" do
        freeze_time do
          patch admin_post_path(blog_post), params: { post: { status: "published" } }
          expect(blog_post.reload.published_at).to eq(Time.current)
        end
      end
    end
  end

  describe "DELETE /admin/posts/:id" do
    it "destroys the post and redirects to index" do
      blog_post = Post.create!(title: "Delete Me", status: :draft)
      expect {
        delete admin_post_path(blog_post)
      }.to change(Post, :count).by(-1)
      expect(response).to redirect_to(admin_posts_path)
    end
  end

  describe "authentication" do
    before { delete logout_path }

    it "redirects unauthenticated users to login" do
      get admin_posts_path
      expect(response).to redirect_to(login_path)
    end
  end
end
