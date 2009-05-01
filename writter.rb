require 'rubygems'
require 'hpricot'
require 'net/http'

url = ARGV[0]
unless url
  raise ArgumentError, "please specify a url as argument to this script"
end


contents = Net::HTTP.get(URI.parse(url))

h_obj = Hpricot(contents)

# puts "h_obj: " + h_obj.inspect

# puts "p's: " + h_obj.search("p").inspect

# h_obj.search("p").each do |p_tag|
  # puts "p tag: " + p_tag.inspect
# end

# puts "h1's: " + h_obj.search("h1").to_html.inspect

p_texts = []

h_obj.search("p").each do |p_tag|
  p_texts << p_tag.inner_text.strip
  # puts p_tag.content rescue "failed"
end

h1_texts = []

h_obj.search("h1").each do |h1_tag|
  h1_texts << h1_tag.inner_text
end

unless h1_texts.size == 2
  raise "Expected h1 text size of 2, "+
        "where first thing is title and second thing is author, but got:"+
        h1_texts.inspect
end

play_title, author = h1_texts

author.gsub("BY ","")

p_texts_reduced = []
dash_dashys_found = 0
p_texts.each_with_index do |p_text, index|
  if p_text["OTHER McSWEENEY'S FEATURES"]
    break
  elsif p_text == "- - - -"
    dash_dashys_found += 1
  elsif dash_dashys_found >= 2
    #strip periods from the end of sentences
    if p_text[-1,1] == "."
      p_text = p_text[0...-1]
    end
    p_texts_reduced << p_text
  end
end


#+======= CONFIGURABLES: set this stuff up PER RUN

#for http://www.mcsweeneys.net/2009/1/21jacobsonsacks.html
authors = [["W", "W"]]
after_each = Proc.new do |output, text, index|
  output.puts "(s) 'click' "
end

#====== FINAL OUTPUT+++======

output = StringIO.new

output.puts "Introducing: " + play_title
output.puts "By: " + author

p_texts_reduced.each_with_index do |text, index|
  author_here = authors[index % authors.size][0]
  output.puts "#{author_here}: #{text}"
  after_each.call(output, text, index)
end


#=== ok we are done

puts output.string


