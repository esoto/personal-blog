admin_password = ENV["ADMIN_PASSWORD"]

if Rails.env.production? && admin_password.to_s.empty?
  raise "ADMIN_PASSWORD environment variable must be set in production"
end

admin_password ||= "password123"

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = admin_password
  user.password_confirmation = admin_password
end
