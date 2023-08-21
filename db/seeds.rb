# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'securerandom'

["florian.motlik@gruene.at", "suleyman.zorba@gruene.at"].each do |e|
  unless User.exists?(email: e)
    uuid = SecureRandom.uuid
    User.create!(email: e, password: uuid, password_confirmation: uuid)
  end
end

user = User.first

Dir["db/lib/seeds/documents/*"].each do |d|
  @document = Document.new(body: "", title: File.basename(d))
  @document.file.attach(io: File.open(d), filename: File.basename(d))
  @document.user_id = user.id
  @document.save
end
