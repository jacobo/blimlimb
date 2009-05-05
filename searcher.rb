require 'search'

class Searcher
  
  def initialize
    @searcher = Search.new

    mit_waa_dir = File.join(File.dirname(__FILE__), 'mit_waa')
    @stories = {}
    Dir.new(mit_waa_dir).each do |entry|
      unless entry[0,1] == "."
        to_add = YAML::load_file(File.join(mit_waa_dir, entry))
        @stories[entry] = to_add
        @searcher.add_document(:uri => entry, :title => to_add["title"], :text => to_add["text"])
      end
    end

    @searcher.finish!
  end
  
  def look_for_response_to(string)
    found_mostly = @searcher.find_most(string.gsub(/[^a-z]/," ").split(" "))
    to_return = []    
    found_mostly.each do |term, docs_found_in|
      # puts "#{term} found in #{docs_found_in.join(',')}"
      docs_found_in.each do |doc_id|
        story_text = @stories[doc_id]["text"]
        # puts "index of #{term} "
        if term_at = story_text.index(term)
          start_at = term_at - 100
          end_at = term_at + 100
          if start_at < 0
            end_at += start_at
            start_at = 0      
          end
          # puts "---#{term}--in---#{doc_id}---"
          snippet = story_text[start_at...end_at]
          start_point = snippet.index(term) - term.size
          end_point = snippet.index(term) + term.size
          start_found = false
          end_found = false

          while !start_found && start_point > 0
            char = snippet[start_point, 1]
            if char == "." || char == "?" || char == "!" || char == "\n"
              start_found = true
              start_point += 1
            else
              start_point -= 1
            end
          end

          while !end_found && end_point < snippet.size
            char = snippet[end_point, 1]
            if char == "." || char == "?" || char == "!" || char == "\n"
              end_found = true
            else
              end_point += 1
            end
          end

          shorter_snip = snippet[start_point...end_point]
          # puts snippet
          # puts "---"
          # puts shorter_snip
          if start_found && end_found && shorter_snip.size > 5
            to_return << [shorter_snip, snippet]
          end
        end
      end
    end
    
    to_return    
  end
  
end