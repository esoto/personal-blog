User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = ENV.fetch("ADMIN_PASSWORD", "password123")
  user.password_confirmation = ENV.fetch("ADMIN_PASSWORD", "password123")
end
