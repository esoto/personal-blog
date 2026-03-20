require "rails_helper"
require "yaml"

RSpec.describe "render.yaml" do
  let(:config) { YAML.load_file(Rails.root.join("render.yaml")) }

  it "is valid YAML" do
    expect(config).to be_a(Hash)
  end

  describe "databases" do
    let(:databases) { config["databases"] }

    it "defines a PostgreSQL database" do
      expect(databases).to be_present
      expect(databases.length).to eq(1)
    end

    it "has the expected database name" do
      db = databases.first
      expect(db["name"]).to eq("personal-blog-db")
      expect(db["databaseName"]).to eq("personal_blog_production")
    end
  end

  describe "services" do
    let(:services) { config["services"] }
    let(:web_service) { services.first }

    it "defines a web service" do
      expect(services).to be_present
      expect(services.length).to eq(1)
      expect(web_service["type"]).to eq("web")
    end

    it "uses Docker runtime" do
      expect(web_service["runtime"]).to eq("docker")
    end

    it "configures health check path" do
      expect(web_service["healthCheckPath"]).to eq("/up")
    end

    it "sets DATABASE_URL from the database" do
      db_url_var = web_service["envVars"].find { |v| v["key"] == "DATABASE_URL" }
      expect(db_url_var).to be_present
      expect(db_url_var["fromDatabase"]["name"]).to eq("personal-blog-db")
      expect(db_url_var["fromDatabase"]["property"]).to eq("connectionString")
    end

    it "sets RAILS_MASTER_KEY as a sync false secret" do
      master_key_var = web_service["envVars"].find { |v| v["key"] == "RAILS_MASTER_KEY" }
      expect(master_key_var).to be_present
      expect(master_key_var["sync"]).to eq(false)
    end

    it "generates SECRET_KEY_BASE automatically" do
      secret_key_var = web_service["envVars"].find { |v| v["key"] == "SECRET_KEY_BASE" }
      expect(secret_key_var).to be_present
      expect(secret_key_var["generateValue"]).to eq(true)
    end

    it "sets RAILS_ENV to production" do
      rails_env_var = web_service["envVars"].find { |v| v["key"] == "RAILS_ENV" }
      expect(rails_env_var).to be_present
      expect(rails_env_var["value"]).to eq("production")
    end

    it "enables Solid Queue in Puma" do
      sq_var = web_service["envVars"].find { |v| v["key"] == "SOLID_QUEUE_IN_PUMA" }
      expect(sq_var).to be_present
      expect(sq_var["value"]).to eq("true")
    end

    it "configures ADMIN_EMAIL and ADMIN_PASSWORD as secrets" do
      admin_email_var = web_service["envVars"].find { |v| v["key"] == "ADMIN_EMAIL" }
      admin_password_var = web_service["envVars"].find { |v| v["key"] == "ADMIN_PASSWORD" }

      expect(admin_email_var).to be_present
      expect(admin_email_var["sync"]).to eq(false)
      expect(admin_password_var).to be_present
      expect(admin_password_var["sync"]).to eq(false)
    end

    it "configures Solid database URLs from the same database" do
      %w[CACHE_DATABASE_URL QUEUE_DATABASE_URL CABLE_DATABASE_URL].each do |key|
        var = web_service["envVars"].find { |v| v["key"] == key }
        expect(var).to be_present, "Expected #{key} to be configured"
        expect(var["fromDatabase"]["name"]).to eq("personal-blog-db")
      end
    end
  end
end
