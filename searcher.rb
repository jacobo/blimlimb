class Searcher
  
  def initialize
    @searcher = Search.new

    mit_waa_dir = File.join(File.dirname(__FILE__), 'mit_waa2')
    @stories = {}
    Dir.new(mit_waa_dir).each_with_index do |entry, idx|
      # puts "importing #{entry} #{idx}"
      unless entry[0,1] == "."
        to_add = YAML::load_file(File.join(mit_waa_dir, entry))
        @stories[entry] = to_add
        # @searcher.add_document(:uri => "#{entry}%%#{idx}", :title => to_add["title"], :text => to_add["text"])
        
        if idx < 50
          to_add['lines'].each_with_index do |line, index|
            unless line.strip.empty?
              @searcher.add_document(:uri => "#{entry}%%#{index}", :text => line, :title => "ignorme")
            end
          end
        end
        
      end
    end

    @searcher.finish!
  end
  
  def look_for_response_to(string, search_pattern)
    found_mostly = @searcher.find_most(string.gsub(/[^a-z]/," ").split(" "), search_pattern)
    to_return = []    
    found_mostly.each do |term, docs_found_in|
      puts "#{term} found in #{docs_found_in.join(',')}"
      docs_found_in.each do |doc_id_given|
        doc_id,line_number = doc_id_given.split("%%")
        to_return << @stories[doc_id]["lines"][line_number.to_i]
        # story_text = @stories[doc_id]["text"]
        # # puts "index of #{term} "
        # if term_at = story_text.index(term)
        #   start_at = term_at - 100
        #   end_at = term_at + 100
        #   if start_at < 0
        #     end_at += start_at
        #     start_at = 0      
        #   end
        #   # puts "---#{term}--in---#{doc_id}---"
        #   snippet = story_text[start_at...end_at]
        #   start_point = snippet.index(term) - term.size
        #   end_point = snippet.index(term) + term.size
        #   start_found = false
        #   end_found = false
        # 
        #   while !start_found && start_point > 0
        #     char = snippet[start_point, 1]
        #     if char == "." || char == "?" || char == "!" || char == "\n"
        #       start_found = true
        #       start_point += 1
        #     else
        #       start_point -= 1
        #     end
        #   end
        # 
        #   while !end_found && end_point < snippet.size
        #     char = snippet[end_point, 1]
        #     if char == "." || char == "?" || char == "!" || char == "\n"
        #       end_found = true
        #     else
        #       end_point += 1
        #     end
        #   end
        # 
        #   shorter_snip = snippet[start_point...end_point]
        #   # puts snippet
        #   # puts "---"
        #   # puts shorter_snip
        #   if start_found && end_found && shorter_snip.size > 5
        #     to_return << shorter_snip
        #   end
        # end
      end
    end
    
    to_return    
  end
  
end