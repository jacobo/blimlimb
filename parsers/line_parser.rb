class LineParser
  
  attr_accessor :lines
  
  def initialize(split_contents)
    @sentence_stack = 0
    @quote_stack = 0
    @in_quoted_sentence = false
    
    @lines = [] 
    
    spc = split_contents.join("\n")
      puts "spc: " + spc
      
      growing_string = ""
      @prev_chars = []
      add_to_next = ""
      spc.chars.each do |c|
        char = c.to_s
        if char.match(/[A-Z]/) && between_sentences?
          begin_sentence!
        end
        if char.match(/[\.\?\!]/)
          if break_on_this_period?
            end_sentence!
          end
        end
        if char.match(/"/)
          quote_found!
        end
        if char.match(/\n/)
          growing_string += " "          
        else
          growing_string += char
        end
        # if between_sentences? && growing_string.size > 1
        #   begin_sentence!
        # end
        if between_sentences?
          stipped_line = growing_string.strip
          if stipped_line.size > 1
            to_add = add_to_next + stipped_line
            # puts "to add:  " + to_add
            if to_add.count("\"") % 2 != 0
              to_add = to_add.gsub("\"","")
            end
            @lines << to_add
          else
            add_to_next = stipped_line
          end
            # puts "#{@sentence_stack} - #{@quote_stack} - #{@in_quoted_sentence} - #{stipped_line}"
          # elsif @lines.last != "\n"
          #   @lines << "\n"
          # elsif growing_string.size > 0
          #   puts "threw away string: #{growing_string}"
          # end
          growing_string = ""          
        end
        @prev_chars.push char
      end
      # stipped_line = growing_string.strip
      # if stipped_line.size > 1
      #   @lines << stipped_line
      #   # puts "-- #{@sentence_stack} - #{@quote_stack} - #{@in_quoted_sentence} - #{stipped_line}"
      # end
      @quote_stack = 0
      @sentence_stack = 0
      @in_quoted_sentence = false
    
    
    # split_contents.each do |spc|
    #   # puts "spc: " + spc
    #   growing_string = ""
    #   @prev_chars = []
    #   spc.chars.each do |c|
    #     char = c.to_s
    #     if char.match(/[A-Z]/) && between_sentences?
    #       begin_sentence!
    #     end
    #     if char.match(/[\.\?\!]/)
    #       if break_on_this_period?
    #         end_sentence!
    #       end
    #     end
    #     if char.match(/"/)
    #       quote_found!
    #     end
    #     if char.match(/\n/)
    #       growing_string += " "          
    #     else
    #       growing_string += char
    #     end
    #     if between_sentences?
    #       stipped_line = growing_string.strip
    #       if stipped_line.size > 1
    #         @lines << stipped_line
    #         # puts "#{@sentence_stack} - #{@quote_stack} - #{@in_quoted_sentence} - #{stipped_line}"
    #       elsif @lines.last != "\n"
    #         @lines << "\n"
    #       end
    #       growing_string = ""
    #     end
    #     @prev_chars.push char
    #   end
    #   stipped_line = growing_string.strip
    #   if stipped_line.size > 1
    #     @lines << stipped_line
    #     # puts "-- #{@sentence_stack} - #{@quote_stack} - #{@in_quoted_sentence} - #{stipped_line}"
    #   end
    #   @quote_stack = 0
    #   @sentence_stack = 0
    #   @in_quoted_sentence = false
    # end
  end
  
  def break_on_this_period?
    c3 = @prev_chars.pop
    c2 = @prev_chars.pop
    c1 = @prev_chars.pop
    ctest = "#{c2}#{c3}"
    if ["Mr","Ms","Dr","No"].include?(ctest)
      return false
    end
    if "#{c1}#{c2}#{c3}" == "Mrs"
      return false
    end
    if "#{c2}#{c3}".match(/ ./)
      return false
    end
    return true
  end
  
  def between_sentences?
    @sentence_stack == 0
  end
  
  def begin_sentence!
    unless between_quotes?
      @sentence_stack = 1
    end
  end
  
  def end_sentence!
    unless between_quotes?
      @sentence_stack = 0
    end
  end
  
  def between_quotes?
    @quote_stack > 1
  end
  
  def quote_found!
    if between_sentences?
      begin_quoted_sentence!
    elsif in_quoted_sentence?
      end_quoted_sentence!
    elsif between_quotes?
      @quote_stack = 0
    else
      @quote_stack += 1
    end
  end
  
  def end_quoted_sentence!
    @in_quoted_sentence = false
    @quote_stack = 0
    @sentence_stack = 0
  end
  
  def begin_quoted_sentence!
    @in_quoted_sentence = true
    @quote_stack = 1
    @sentence_stack = 1
  end
  
  def in_quoted_sentence?
    @in_quoted_sentence
  end
  
end