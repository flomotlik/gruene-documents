# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Document.create([{body: "Lorem ipsum"}, {body: "Dolor sit"}])

1.times do |i|
  Dir["db/lib/seeds/documents/*.txt"].each do |d|
    Document.create(body: File.open(d).read, title: File.basename(d))
  end
end