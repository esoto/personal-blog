admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV["ADMIN_PASSWORD"]

if Rails.env.production? && admin_password.to_s.empty?
  raise "ADMIN_PASSWORD environment variable must be set in production"
end

admin_password ||= "password12345"

User.find_or_create_by!(email: admin_email) do |user|
  user.password = admin_password
  user.password_confirmation = admin_password
end
