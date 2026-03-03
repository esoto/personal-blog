require "rails_helper"

RSpec.describe PostTag, type: :model do
  let!(:post) { Post.create!(title: "Test Post", status: :draft) }
  let!(:tag) { Tag.create!(name: "Ruby") }

  describe "validations" do
    it "is valid with a post and tag" do
      post_tag = described_class.new(post: post, tag: tag)
      expect(post_tag).to be_valid
    end

    it "is invalid without a post" do
      post_tag = described_class.new(tag: tag)
      expect(post_tag).not_to be_valid
    end

    it "is invalid without a tag" do
      post_tag = described_class.new(post: post)
      expect(post_tag).not_to be_valid
    end

    it "prevents duplicate post-tag combinations" do
      described_class.create!(post: post, tag: tag)
      duplicate = described_class.new(post: post, tag: tag)
      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a post" do
      expect(described_class.reflect_on_association(:post).macro).to eq(:belongs_to)
    end

    it "belongs to a tag" do
      expect(described_class.reflect_on_association(:tag).macro).to eq(:belongs_to)
    end
  end
end
