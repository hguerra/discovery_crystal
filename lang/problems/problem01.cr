module Problems
  class Problem01
    def self.call
      puts "Give me an integer number"
      print "> "
      int_text = gets

      puts "Give me a float number"
      print "> "
      float_text = gets

      if int_text && float_text
        int_num = int_text.to_i
        float_num = float_text.to_f
        puts "Your result is: #{int_num * float_num}"
        puts "done."
      else
        puts "Invalid input"
        exit
      end
    end
  end
end
