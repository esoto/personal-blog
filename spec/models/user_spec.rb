require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { described_class.new(email: "admin@example.com", password: "password123", password_confirmation: "password123") }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "is invalid without an email" do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "is invalid with a duplicate email" do
      described_class.create!(email: "admin@example.com", password: "password123", password_confirmation: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "is invalid with an improperly formatted email" do
      user.email = "not-an-email"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "normalizes email to lowercase" do
      user.email = "ADMIN@Example.COM"
      user.validate
      expect(user.email).to eq("admin@example.com")
    end
  end

  describe "has_secure_password" do
    it "authenticates with correct password" do
      user.save!
      expect(user.authenticate("password123")).to eq(user)
    end

    it "does not authenticate with incorrect password" do
      user.save!
      expect(user.authenticate("wrong")).to be false
    end

    it "is invalid without a password on create" do
      new_user = described_class.new(email: "test@example.com")
      expect(new_user).not_to be_valid
      expect(new_user.errors[:password]).to include("can't be blank")
    end
  end
end
