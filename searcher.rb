class Searcher
  
  def initialize
    @searcher = Search.new

    mit_waa_dir = File.join(File.dirname(__FILE__), 'mit_waa2')
    @stories = {}
    Dir.new(mit_waa_dir).each_with_index do |entry, idx|
      unless entry[0,1] == "."
        to_add = YAML::load_file(File.join(mit_waa_dir, entry))
        @stories[entry] = to_add
        # @searcher.add_document(:uri => "#{entry}%%#{idx}", :title => to_add["title"], :text => to_add["text"])
        
        unless @searcher.index_loaded
          puts "importing #{entry} #{idx}"
        
          to_add['lines'].each_with_index do |line, index|
            line_stripped = line.strip.downcase.gsub(/[^a-z]/," ")
            unless line_stripped.empty?
              @searcher.add_document(:uri => "#{entry}%%#{index}", :text => line_stripped, :title => "ignorme")
            end
          end
        end
        
      end
    end

    @searcher.finish!
  end
  
  def look_for_response_to(string, search_pattern)
    string_parts = string.downcase.gsub(/[^a-z]/," ").split(" ")
    found_mostly = @searcher.find_most(string_parts, search_pattern)
    to_return = []
    found_mostly.each do |term, docs_found_in|
      # puts "#{term} found in #{docs_found_in.join(',')}"
      docs_found_in.each do |doc_id_given|
        doc_id,line_number = doc_id_given.split("%%")
        line_number = line_number.to_i
        possible_line = @stories[doc_id]["lines"][line_number]
        if possible_line.size > 2
          to_return << [doc_id,line_number,possible_line]
        end
      end
    end
    to_return.uniq!
    to_return.sort! do |a, b|
      "#{a[0]}#{a[1]}" <=> "#{b[0]}#{b[1]}"
    end
    prev_response = nil
    prev_score = 0
    combined_lines = []
    lines_to_drop = []
    to_return = to_return.collect do |response|
      doc_id,line_number,possible_line = response
      score = 0
      line_stripped = possible_line.downcase.gsub(/[^a-z]/," ")
      string_parts.each do |sp|
        if line_stripped.index(sp)
          score += sp.size
        end
      end
      if prev_response && prev_response[0] == doc_id
        prev_doc_id, prev_line_number, prev_possible_line = prev_response
        if (prev_line_number - line_number).abs < 2
          lines = [prev_line_number, line_number].sort
          line_strings = []
          (lines[0]..lines[1]).each do |line_num|
            line_strings << @stories[doc_id]["lines"][line_num]
          end
          combined_lines << [[doc_id, lines], 5 + prev_score + score, line_strings.join(" ")]
        end
      end
      prev_response = response
      prev_score = score
      [[doc_id, line_number], score, possible_line]
    end + combined_lines
    
    to_return.reject! do |it|
      it[2].size > 250
    end
    
    to_return.sort! do |a, b|
      b[1] <=> a[1]      
    end
    
    to_return    
  end
  
end