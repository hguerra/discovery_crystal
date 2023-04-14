require "db"
require "sqlite3"

# https://crystal-lang.github.io/crystal-db/api/0.5.1/DB.html
DB.open "sqlite3://./data.db" do |db|
  db.exec "create table contacts (name text, age integer)"
  db.exec "insert into contacts values (?, ?)", "John Doe", 30

  args = [] of DB::Any
  args << "Sarah"
  args << 33
  db.exec "insert into contacts values (?, ?)", args: args

  puts "max age:"
  puts db.scalar "select max(age) from contacts" # => 33

  puts "contacts:"
  db.query "select name, age from contacts order by age desc" do |rs|
    puts "#{rs.column_name(0)} (#{rs.column_name(1)})"
    # => name (age)
    rs.each do
      puts "#{rs.read(String)} (#{rs.read(Int32)})"
      # => Sarah (33)
      # => John Doe (30)
    end
  end

  contacts = db.query_all "select name, age from contacts order by age desc", as: {name: String, age: Int32}
  p! contacts
end
