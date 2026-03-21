require "rails_helper"

RSpec.describe "Dockerfile" do
  let(:dockerfile_content) { File.read(Rails.root.join("Dockerfile")) }

  it "uses the correct Ruby version" do
    expected_version = File.read(Rails.root.join(".ruby-version")).strip
    expect(dockerfile_content).to include("RUBY_VERSION=#{expected_version}")
  end

  it "installs postgresql-client for runtime" do
    expect(dockerfile_content).to include("postgresql-client")
  end

  it "installs libpq-dev for building the pg gem" do
    expect(dockerfile_content).to include("libpq-dev")
  end

  it "precompiles assets" do
    expect(dockerfile_content).to include("assets:precompile")
  end

  it "uses Thruster as the entrypoint command" do
    expect(dockerfile_content).to include('./bin/thrust')
  end

  it "exposes port 80 for Thruster" do
    expect(dockerfile_content).to include("EXPOSE 80")
  end

  it "sets RAILS_ENV to production" do
    expect(dockerfile_content).to include('RAILS_ENV="production"')
  end
end
