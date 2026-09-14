# bin/rails db:seed
#
# Idempotente: pode rodar quantas vezes quiser.
admin = User.find_or_initialize_by(email_address: "admin@example.com")
admin.assign_attributes(
full_name: "Lampião admin",
password: "password123",
password_confirmation: "password123",
role: :admin
)
admin.save!
member = User.find_or_initialize_by(email_address: "user@example.com")
member.assign_attributes(
full_name: "Cabra member",
password: "password123",
password_confirmation: "password123",
role: :user
)
member.save!
# Alguns usuários extras para a tabela e o dashboard não ficarem vazios.
User.suppressing_dashboard_broadcasts do
  12.times do |index|
    user = User.find_or_initialize_by(email_address: "person#{index + 1}@example.com")
    user.assign_attributes(
    full_name: "Person #{index + 1}",
    password: "password123",
    password_confirmation: "password123",
    role: :user
    )
    user.save!
  end
end
User.broadcast_dashboard_stats
puts "Seeded #{User.count} users."
puts " admin@example.com / password123 (admin)"
puts " user@example.com / password123 (user)"
