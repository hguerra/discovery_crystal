require "db"
require "pg"

DB.open("postgresql://tasks:tasks@localhost:5432/tasks?schema=public&initial_pool_size=1&max_pool_size=10&max_idle_pool_size=2") do |db|
  # p! db

  db.transaction do |tx|
    cnn = tx.connection
    cnn.exec("insert into tasks(title, description) values('A','B')")

    args = [] of DB::Any
    args << "C"
    args << "D"
    cnn.exec "insert into tasks(title, description) values($1,$2)", args: args

    cnn.exec("insert into tasks(title, description) values($1,$2)", "E", "F")
  end

  tasks = db.query_all "select title from tasks order by id desc", as: {title: String}
  p! tasks
end
