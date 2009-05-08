require 'rubygems'
require 'hpricot'
require 'net/http'
require 'yaml'

# def random_range(string)
#   
# end
# 
# random_range()
# 
# exit 0

url = "http://mcsweeneys.net/archives/"

contents = Net::HTTP.get(URI.parse(url))

h_obj = Hpricot(contents)

articles_to_fetch = []
h_obj.search("a").each do |a_tag|
  if a_tag.inner_text == "MAIN PAGE"
    break
  end
  if a_tag.attributes && a_tag.attributes["href"]
    unless a_tag.attributes["href"]["http"]
      unless a_tag.attributes["href"]["mailto"]
        articles_to_fetch << "http://mcsweeneys.net" + a_tag.attributes["href"]
      end
    end
  end
end

# puts articles_to_fetch.size.inspect
# puts "articles_to_fetch: " + articles_to_fetch.to_yaml

#WHERE 0 == http://mcsweeneys.net/2009/5/1hahn.html

#!!! skipped #43: http://mcsweeneys.net/2009/2/25beanose.html (it's a video)
#!!! skipped #44: http://mcsweeneys.net/2009/2/24vow.html (it's an advert)
#!!! skipped #63: http://mcsweeneys.net/2009/1/26advice.html (it's a video)

#!!! skipped #66: http://mcsweeneys.net/2009/1/20onemorehandful.html (come back to this maybe)
#!!! skipped #67: http://mcsweeneys.net/2009/1/19afewmore.html (come back to this maybe)
#!!! skipped #68: http://mcsweeneys.net/2009/1/16moreobamaletters.html (come back to this maybe)
#!!! skipped #74: http://mcsweeneys.net/2009/1/8letterstoobama.html (come back to this maybe)

#!!! skipped #94: http://mcsweeneys.net/2008/12/3curiousmen.html (excerpt from magazine, come back)

#!!! skipped #141: http://mcsweeneys.net/2008/9/9vacation.html (excerpt from magazine, come back)

#!!! skipped #180: http://mcsweeneys.net/2008/7/15unferth.html (long text after authors name)

#noticed this one messed up: fetching #239: http://mcsweeneys.net/2008/4/21kemper.html

#!!! skipped #251: http://mcsweeneys.net/2008/4/3undergroundamerica.html (advert)

#! skip #301: http://mcsweeneys.net/2008/1/24arkansas.html (advert)
#! skip #350: http://mcsweeneys.net/2007/11/5artissue.html (article excerpt)
#! skip #387: http://mcsweeneys.net/2007/9/13boxofstories.html (this one looks fun, come back)
#! skip #397: http://mcsweeneys.net/2007/8/29millardkaufman.html (article except.. could be good)
#! skip #441: http://mcsweeneys.net/2007/6/22thankyou.html (advert)
#! skip #448: http://mcsweeneys.net/2007/6/12agoodtime.html (advert)
#! skip #449: http://mcsweeneys.net/2007/6/11numbers.html (numbers?!?)
#! skip #456: http://mcsweeneys.net/2007/5/31musicissue.html (excerpt.. could be a good one thou)
#! skip #516: http://mcsweeneys.net/2007/3/7duddurden.html (advert)
#! skip #521: http://mcsweeneys.net/2007/2/28embryoyo.html (article exceprt)
#! skip #559: http://mcsweeneys.net/2006/12/21brennan.html (article excerpt)
#! skip  #560: http://mcsweeneys.net/2006/12/20contest.html (announcement)

#Gave up at fetching #569: http://mcsweeneys.net/2006/12/6wholphin.html

zero_supposed_to_be_at = articles_to_fetch.index("http://mcsweeneys.net/2009/5/1hahn.html")
# puts "zero_supposed_to_be_at: " + zero_supposed_to_be_at.inspect
# raise "end"

articles_to_skip = [43,44,63,66,67,68,74,94,141,180,251,
    301,350,387,397,441,448,449,456,516,521,559,560]
articles_to_skip.collect!{|i| i + zero_supposed_to_be_at }

articles_to_fetch[0..-1].each do |article_url|
  index = articles_to_fetch.index(article_url)
  if articles_to_skip.include?(index)
    next
  end
  puts "fetching ##{index}: #{article_url}"
  begin
    contents = Net::HTTP.get(URI.parse(article_url))
    h_obj = Hpricot(contents)
  
    h1_texts = h_obj.search("h1").collect do |h1_tag|
      text_found = []
      h1_tag.each_child do |h1_child|
        text_found << (" " + h1_child.inner_text + " ").strip
      end
      text_found.reject!{ |it| it.empty? }
      text_found.join(" ")
    end
  
    title = ""
    author = ""
  
    if h1_texts.size >= 2
      title = h1_texts[0]
      author = h1_texts[1]
    elsif h1_texts.size == 1
      if h1_texts[0][0,2] == "BY"
        author = h1_texts[0]
        possible_title = h_obj.search("nobr")[0].inner_html
        if possible_title["&nbsp;"]
          possible_title = possible_title.gsub("<br />", "&nbsp;")
          title = possible_title.split("&nbsp;").collect{ |txt| txt.gsub(/[^A-Z]/,"").strip }.join(" ")
        else
          raise "can't get a title out of #{possible_title}"
        end
      else
        title = h1_texts[0]
    
        from = contents.index("BY")
        to = contents.index("<!-- end byline-->")
        if from && to
          to = to - 1
          search_in = contents[from..to]
    
          author = Hpricot(search_in).inner_text
    
          if author.size > 300
            raise "that author is too long: #{from} - #{to} - title #{title} - author #{author}"
          end
        else
          raise "couldn't find author #{from} - #{to}"
        end
      end
    elsif h1_texts.size < 2
      #TODO: when I run the full, don't raise?
      raise "Not enough h1s found for #{article_url} (at #{index}). found #{h1_texts.inspect}"
    end
    
  
    puts "title: " + title.inspect
    puts "author: " + author.inspect

    # h_obj.search("p").each do |p_tag| 
    #   puts "="*20
    #   puts p_tag.inner_html
    #   puts "="*20
    # end
  
    # p_contents = h_obj.search("p").collect{ |p_tag| p_tag.inner_html }.join(" ")
  
    start_index = contents.index("<!-- end byline-->")
    unless start_index
      start_index = contents.index("</h1>")
      start_index = start_index + 5
    end
    end_index = contents.index("OTHER McSWEENEY'S FEATURES")
  
    # puts "start index: " + start_index.inspect
    # puts "end_index: " + end_index.inspect
  
    unless start_index && end_index
      raise "not found start_index #{start_index} end_index #{end_index}"
    end
  
    story_contents = contents[start_index..end_index]
  
    # non_p_tags_stripped = story_contents.gsub(/<[\/p]{1}[^p]+[^>]*>/, "")
    non_p_tags_stripped = story_contents.gsub(
                                        /<[pP]{1}[^>]*>/,"%PP%").gsub(
                                        /<\/[pP]{1}>/,"%PP%").gsub(
                                        /<[^>]*>/, " ")
    p_texts = non_p_tags_stripped.split("%PP%").collect{ |txt| txt.strip }.reject{ |txt| txt.empty? }
  
    # puts "p texts: " + p_texts.to_yaml
    # non_p_tags_stripped_h_obj = Hpricot(non_p_tags_stripped)
  
    # puts "non_p_tags_stripped:\n" + non_p_tags_stripped.to_s
   
    # p_texts = []
    # p_collector = Proc.new do |each_on|
    #   each_on.each do |p_tag|
    #     sub_ps = p_tag.search("p")
    # 
    #     puts "\n\n===="
    #     puts "p_tag: " + p_tag.inspect
    #     puts "\n++++++++++\n"
    #     puts "sub ps: " + sub_ps.inspect
    # 
    #     if sub_ps.size > 0
    #       p_collector.call(sub_ps)
    #     else
    #       p_texts << p_tag.inner_text.strip
    #     end
    #   end
    # end
    # p_collector.call(non_p_tags_stripped_h_obj.search("p"))
    # p_texts.uniq!
    # h_obj.search("p").each do |p_tag| 
    #   sub_ps = p_tag.search("p")
    #   if sub_ps.size > 0
    #   end
    #   p_texts << p_tag.inner_text.strip
    # end
  
    # p_texts = non_p_tags_stripped_h_obj.search("p").collect{ |p_tag| p_tag.inner_text.strip }
  
    # puts "p texts: " + p_texts.to_yaml
  
    # p_texts_reduced = []
    # dash_dashys_found = 0
    # p_texts.each_with_index do |p_text, index|
    #   # puts "test: " + p_text.inspect
    #   # if p_text["OTHER McSWEENEY'S FEATURES"]
    #   #   puts "break on other features"
    #   #   break
    #   # elsif p_text == "- - - -"
    #   #   puts "dashy found"
    #   #   dash_dashys_found += 1
    #   # elsif dash_dashys_found >= 2
    #     #strip periods from the end of sentences
    #     if p_text[-1,1] == "."
    #       p_text = p_text[0...-1]
    #     end
    #     puts "p_text found:" + p_text.to_s
    #     p_texts_reduced << p_text
    #   # end
    # end
  
    contents_condensed = p_texts.join("\n")
  
    article_size = contents_condensed.size
  
    # snippet = ""
    # contents_condensed.split(" ")[]
  
    downcase_title = title.downcase.strip.gsub(/[^a-z]/, ".")
  
    # write_contents_to = File.join(File.dirname(__FILE__), "mit_waa", downcase_title+".html")
  
    write_info_to = File.join(File.dirname(__FILE__), "mit_waa2", downcase_title+".yml")
  
    # puts "contents_condensed: \n" + contents_condensed.to_s
  
    # File.open(write_contents_to, "w+") do |fp|
    #   fp.write(contents)
    # end
  
    File.open(write_info_to, "w+") do |fp|
      fp.write({
        "title" => title,
        "author" => author,
        "downcase_title" => downcase_title,
        "article_size" => article_size,
        "article_url" => article_url,
        "text" => contents_condensed
      }.to_yaml)
    end
  rescue => e
    puts e.inspect
    puts e.backtrace.join("\n")
  end
end
