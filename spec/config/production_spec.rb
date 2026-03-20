require "rails_helper"

RSpec.describe "Production configuration" do
  # We can't load the production config directly in test, but we can verify
  # the config file contains the expected settings by reading it as text.
  let(:config_content) { File.read(Rails.root.join("config/environments/production.rb")) }

  it "enables assume_ssl" do
    expect(config_content).to include("config.assume_ssl = true")
  end

  it "enables force_ssl" do
    expect(config_content).to include("config.force_ssl = true")
  end

  it "excludes health check from SSL redirect" do
    expect(config_content).to include('request.path == "/up"')
  end

  it "uses Solid Cache store" do
    expect(config_content).to include("config.cache_store = :solid_cache_store")
  end

  it "uses Solid Queue for Active Job" do
    expect(config_content).to include("config.active_job.queue_adapter = :solid_queue")
  end

  it "silences health check logs" do
    expect(config_content).to include('config.silence_healthcheck_path = "/up"')
  end
end
