require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:post) do
    Post.create!(
      title: "Test Post",
      status: :published,
      published_at: 1.day.ago,
      excerpt: "Test excerpt"
    )
  end

  let(:valid_attributes) do
    {
      author_name: "Jane Doe",
      email: "jane@example.com",
      body: "Great post!",
      post: post
    }
  end

  describe "validations" do
    it "is valid with all required attributes" do
      comment = Comment.new(valid_attributes)
      expect(comment).to be_valid
    end

    it "requires author_name" do
      comment = Comment.new(valid_attributes.merge(author_name: nil))
      expect(comment).not_to be_valid
      expect(comment.errors[:author_name]).to include("can't be blank")
    end

    it "requires email" do
      comment = Comment.new(valid_attributes.merge(email: nil))
      expect(comment).not_to be_valid
      expect(comment.errors[:email]).to include("can't be blank")
    end

    it "requires a valid email format" do
      comment = Comment.new(valid_attributes.merge(email: "not-an-email"))
      expect(comment).not_to be_valid
      expect(comment.errors[:email]).to include("is invalid")
    end

    it "accepts valid email formats" do
      comment = Comment.new(valid_attributes.merge(email: "user@domain.co.uk"))
      expect(comment).to be_valid
    end

    it "requires body" do
      comment = Comment.new(valid_attributes.merge(body: nil))
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("can't be blank")
    end

    it "requires a post" do
      comment = Comment.new(valid_attributes.merge(post: nil))
      expect(comment).not_to be_valid
      expect(comment.errors[:post]).to include("must exist")
    end

    it "rejects author_name longer than 100 characters" do
      comment = Comment.new(valid_attributes.merge(author_name: "a" * 101))
      expect(comment).not_to be_valid
      expect(comment.errors[:author_name]).to include("is too long (maximum is 100 characters)")
    end

    it "rejects email longer than 254 characters" do
      comment = Comment.new(valid_attributes.merge(email: "a" * 243 + "@example.com"))
      expect(comment).not_to be_valid
      expect(comment.errors[:email]).to include("is too long (maximum is 254 characters)")
    end

    it "rejects body longer than 5000 characters" do
      comment = Comment.new(valid_attributes.merge(body: "a" * 5001))
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("is too long (maximum is 5000 characters)")
    end
  end

  describe "normalizations" do
    it "downcases and strips email" do
      comment = Comment.create!(valid_attributes.merge(email: "  Jane@Example.COM  "))
      expect(comment.email).to eq("jane@example.com")
    end
  end

  describe "status enum" do
    it "defaults to pending" do
      comment = Comment.create!(valid_attributes)
      expect(comment).to be_pending
    end

    it "can be set to approved" do
      comment = Comment.create!(valid_attributes.merge(status: :approved))
      expect(comment).to be_approved
    end

    it "can be set to spam" do
      comment = Comment.create!(valid_attributes.merge(status: :spam))
      expect(comment).to be_spam
    end
  end

  describe "scopes" do
    let!(:pending_comment) { Comment.create!(valid_attributes) }
    let!(:approved_comment) { Comment.create!(valid_attributes.merge(author_name: "Bob", status: :approved)) }
    let!(:spam_comment) { Comment.create!(valid_attributes.merge(author_name: "Spammer", status: :spam)) }

    it ".pending returns only pending comments" do
      expect(Comment.pending).to contain_exactly(pending_comment)
    end

    it ".approved returns only approved comments" do
      expect(Comment.approved).to contain_exactly(approved_comment)
    end

    it ".spam returns only spam comments" do
      expect(Comment.spam).to contain_exactly(spam_comment)
    end

    it ".recent orders by created_at descending" do
      expect(Comment.recent.first).to eq(spam_comment)
      expect(Comment.recent.last).to eq(pending_comment)
    end
  end

  describe "associations" do
    it "belongs to a post" do
      comment = Comment.create!(valid_attributes)
      expect(comment.post).to eq(post)
    end

    it "is destroyed when its post is destroyed" do
      Comment.create!(valid_attributes)
      expect { post.destroy }.to change(Comment, :count).by(-1)
    end
  end
end
