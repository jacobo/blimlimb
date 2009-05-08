require 'rubygems'
require 'hpricot'
require 'net/http'
require 'yaml'

require 'parsers/line_parser.rb'
require 'parsers/content_extractor.rb'

url = "http://mcsweeneys.net/archives/"

contents = Net::HTTP.get(URI.parse(url))

h_obj = Hpricot(contents)

articles_to_fetch = []
h_obj.search("p").each do |p_tag|
  href = nil
  title = nil
  author = nil
  date = nil
  p_tag.search("a").each do |a_tag|
    if a_tag.attributes && a_tag.attributes["href"]
      unless a_tag.attributes["href"]["http"]
        unless a_tag.attributes["href"]["mailto"]
          title = a_tag.inner_text
          href = "http://mcsweeneys.net" + a_tag.attributes["href"]
        end
      end
    end
  end
  # puts p_tag.inner_html
  br_split = p_tag.inner_html.split("</a>")
  if br_split.size > 1
    author, date = br_split[1].gsub(/<[^>]*>/,"").split("(")
    if date
      date, rest = date.split(")")
      date = date.strip
    end
    author = author.strip
  end
  if href && title
    articles_to_fetch << [href, title, author, date]
  end
end

# puts articles_to_fetch.to_yaml
titles_fetched = []
articles_to_fetch[0..-1].each do |article_url, title, author, date|
  index = articles_to_fetch.index(article_url)
  puts "fetching ##{index}: #{article_url}"
  begin
    contents = Net::HTTP.get(URI.parse(article_url))
    
    extractor = ContentExtractor.new(contents)
    p_texts = extractor.p_texts
    line_parser = LineParser.new(p_texts)
    lines = line_parser.lines
    contents_condensed = p_texts.join("\n")
    article_size = contents_condensed.size
    
    downcase_name = "#{title}_#{author}".downcase.strip.gsub(/[^a-z_]/, ".")
    if downcase_name.size > 50
      downcase_name = downcase_name[0,25] + "." + downcase_name[-25...-1]
    end
    while titles_fetched.include?(downcase_name)
      downcase_name[downcase_name.size - 1] = (downcase_name[downcase_name.size - 1, 1].to_i + 1).to_s
    end
    titles_fetched << downcase_name
    
    puts "#{title} - #{author} - #{date} - #{downcase_name}"
    puts "#{lines.size} lines #{article_size} chars"
        
    write_info_to = File.join(File.dirname(__FILE__), "mit_waa2", downcase_name+".yml")
    
    File.open(write_info_to, "w+") do |fp|
      fp.write({
        "title" => title,
        "author" => author,
        "date" => date,
        "downcase_name" => downcase_name,
        "article_size" => article_size,
        "article_url" => article_url,
        "text" => contents_condensed,
        "lines" => lines
      }.to_yaml)
    end
  rescue => e
    puts e.inspect
    puts e.backtrace.join("\n")
  end
end
