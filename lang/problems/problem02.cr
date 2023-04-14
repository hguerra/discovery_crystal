module Problems
  class Problem02
    def self.call(nums : Array(Int32 | Float64))
      sum = 0.0
      nums.each do |n|
        sum += n
      end
      puts sum
    end
  end
end
