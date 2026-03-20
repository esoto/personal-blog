require "rails_helper"

RSpec.describe "db/seeds.rb" do
  let(:seed_file) { Rails.root.join("db/seeds.rb") }

  after do
    # Clean up env vars set during tests
    ENV.delete("ADMIN_EMAIL")
    ENV.delete("ADMIN_PASSWORD")
  end

  context "in development (default behavior)" do
    it "creates an admin user with default email" do
      expect { load seed_file }.to change(User, :count).by(1)

      user = User.find_by(email: "admin@example.com")
      expect(user).to be_present
      expect(user.authenticate("password123")).to be_truthy
    end

    it "is idempotent — does not create duplicates on re-run" do
      load seed_file
      expect { load seed_file }.not_to change(User, :count)
    end
  end

  context "with ADMIN_EMAIL and ADMIN_PASSWORD set" do
    before do
      ENV["ADMIN_EMAIL"] = "custom@example.com"
      ENV["ADMIN_PASSWORD"] = "securepassword"
    end

    it "creates an admin user with custom email and password" do
      expect { load seed_file }.to change(User, :count).by(1)

      user = User.find_by(email: "custom@example.com")
      expect(user).to be_present
      expect(user.authenticate("securepassword")).to be_truthy
    end
  end

  context "with only ADMIN_EMAIL set" do
    before do
      ENV["ADMIN_EMAIL"] = "custom@example.com"
    end

    it "uses default password in non-production" do
      expect { load seed_file }.to change(User, :count).by(1)

      user = User.find_by(email: "custom@example.com")
      expect(user.authenticate("password123")).to be_truthy
    end
  end
end
