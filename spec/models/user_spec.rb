require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { described_class.new(email: "admin@example.com", password: "password12345", password_confirmation: "password12345") }

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
      described_class.create!(email: "admin@example.com", password: "password12345", password_confirmation: "password12345")
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
      expect(user.authenticate("password12345")).to eq(user)
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

  describe "password length validation" do
    it "is invalid with a password shorter than 12 characters" do
      user.password = "short"
      user.password_confirmation = "short"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 12 characters)")
    end

    it "is invalid with an 11-character password" do
      user.password = "a" * 11
      user.password_confirmation = "a" * 11
      expect(user).not_to be_valid
    end

    it "is valid with a 12-character password" do
      user.password = "a" * 12
      user.password_confirmation = "a" * 12
      expect(user).to be_valid
    end

    it "is valid with a password longer than 12 characters" do
      user.password = "a" * 20
      user.password_confirmation = "a" * 20
      expect(user).to be_valid
    end
  end
end
