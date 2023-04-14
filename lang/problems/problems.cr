require "./*"

module Problems
  extend self
  VERSION = "0.1.0"

  def call
    puts ">> Running problems (#{VERSION})..."
    # Problems::Problem01.call
    Problem01.call
    Problem02.call [0.0, 13, 89, 65, 42, 12, 11, 56]
  end
end

Problems.call
