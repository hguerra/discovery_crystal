require "fiberpool"

maximum_number_of_workers = 10
# some list of things to do
queue = (1..100).to_a
# optional accumulator where the worker-fibers can register the processed results
results = [] of Int32

puts "Criando pool..."
pool = Fiberpool.new(queue, maximum_number_of_workers)
pool.run do |item|
  results << item
end

puts "Resultado: #{results}"
