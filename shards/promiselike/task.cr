require "tasker"

def perform_action
  puts "Time: #{Time.local}"
end

puts "Criando task para o futuro"
task = Tasker.at(3.seconds.from_now) { perform_action }
p! task.get
puts "Apos executar task."

tick = 0
task = Tasker.every(2.milliseconds) { tick += 1; tick }

# Calling get will pause until after the next schedule has run
p! task.get == 1 # => true
p! task.get == 2 # => true
p! task.get == 3 # => true

# It also works as an enumerable
# NOTE:: this will only stop counting once the schedule is canceled
task.each do |count|
  puts "The count is #{count}"
  task.cancel if count > 5
end
