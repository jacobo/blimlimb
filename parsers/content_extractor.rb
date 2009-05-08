class ContentExtractor
  
  attr_accessor :contents
  
  def initialize(contents)
    @contents = contents
  end
  
  def story_contents
    @contents = @contents.gsub(/<\!\-\-.*\-\->/,"")
    start_index = contents.index("<!-- end byline-->")
    unless start_index
      start_index = contents.index("</h1>")
      start_index = start_index + 5 if start_index
    end
    unless start_index
      start_index = contents.index("</nobr>")
      start_index = start_index + 7 if start_index
    end
    end_index = contents.index("OTHER McSWEENEY'S")
    unless end_index
      end_index = contents.index("MAIN PAGE")
    end
    if end_index
      end_index -= 1
    end
    unless start_index && end_index
      raise "not found start_index #{start_index} end_index #{end_index}"
    end
    
    to_return = contents[start_index..end_index]    
    # puts "returning: " + to_return    
    to_return
  end
  
  def p_texts
    non_p_tags_stripped = self.story_contents.gsub(
                                        /<[pP]{1}[^>]*>/,"%PP%").gsub(
                                        /<\/[pP]{1}>/,"%PP%").gsub(
                                        /<br>/,"%PP%").gsub(
                                        /<br\/>/,"%PP%").gsub(
                                        /<[^>]*>/, " ")
    p_texts = non_p_tags_stripped.split("%PP%").collect{ |txt| txt.strip }.reject{ |txt| txt.empty? }    
  end
  
end