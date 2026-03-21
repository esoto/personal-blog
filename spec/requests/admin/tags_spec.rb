require "rails_helper"

RSpec.describe "Admin::Tags", type: :request do
  let!(:user) { User.create!(email: "admin@example.com", password: "password12345", password_confirmation: "password12345") }

  before do
    post login_path, params: { email: "admin@example.com", password: "password12345" }
  end

  describe "GET /admin/tags" do
    it "renders the index page" do
      get admin_tags_path
      expect(response).to have_http_status(:ok)
    end

    it "displays all tags with post counts" do
      tag = Tag.create!(name: "Ruby")
      blog_post = Post.create!(title: "Ruby Post", body_markdown: "# Content", status: :draft)
      blog_post.tags << tag

      get admin_tags_path
      expect(response.body).to include("Ruby")
      expect(response.body).to include("1")
    end
  end

  describe "GET /admin/tags/new" do
    it "renders the new tag form" do
      get new_admin_tag_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/tags" do
    context "with valid params" do
      it "creates a tag and redirects to index" do
        expect {
          post admin_tags_path, params: { tag: { name: "Ruby" } }
        }.to change(Tag, :count).by(1)
        expect(response).to redirect_to(admin_tags_path)
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        expect {
          post admin_tags_path, params: { tag: { name: "" } }
        }.not_to change(Tag, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a duplicate name" do
      it "re-renders the form with errors" do
        Tag.create!(name: "Ruby")
        expect {
          post admin_tags_path, params: { tag: { name: "Ruby" } }
        }.not_to change(Tag, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/tags/:id/edit" do
    it "renders the edit form" do
      tag = Tag.create!(name: "Ruby")
      get edit_admin_tag_path(tag)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/tags/:id" do
    let!(:tag) { Tag.create!(name: "Ruby") }

    context "with valid params" do
      it "updates the tag and redirects to index" do
        patch admin_tag_path(tag), params: { tag: { name: "Rails" } }
        expect(response).to redirect_to(admin_tags_path)
        expect(tag.reload.name).to eq("Rails")
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        patch admin_tag_path(tag), params: { tag: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(tag.reload.name).to eq("Ruby")
      end
    end
  end

  describe "DELETE /admin/tags/:id" do
    it "destroys the tag and redirects to index" do
      tag = Tag.create!(name: "Ruby")
      expect {
        delete admin_tag_path(tag)
      }.to change(Tag, :count).by(-1)
      expect(response).to redirect_to(admin_tags_path)
    end
  end

  describe "authentication" do
    before { delete logout_path }

    it "redirects unauthenticated users to login" do
      get admin_tags_path
      expect(response).to redirect_to(login_path)
    end
  end
end
