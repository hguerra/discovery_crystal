require "granite"
require "granite/adapter/sqlite"

Granite::Connections << Granite::Adapter::Sqlite.new(name: "sqlite", url: "sqlite3://./data.db")

class Post < Granite::Base
  connection sqlite
  table posts # Name of the table to use for the model, defaults to class name snake cased

  column id : Int64, primary: true # Primary key, defaults to AUTO INCREMENT
  column name : String? # Nilable field
  column body : String # Not nil field
end

post = Post.new
post.name = "Granite Rocks!"
post.body = "Check this out."
post.save

post = Post.first
if post
  puts post.name
end
