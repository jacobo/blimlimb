require 'rubygems'
require 'hpricot'
require 'net/http'
require 'yaml'

require '../parsers/line_parser.rb'
require '../parsers/content_extractor.rb'

# article_url = "http://www.mcsweeneys.net/2009/5/7wood.html"
# article_url = "http://www.mcsweeneys.net/1998/11/23concise.html"
# article_url = "http://mcsweeneys.net/1999/01/20adolf.html"

# contents = Net::HTTP.get(URI.parse(article_url))

yaml_loaded = YAML::load_file("../mit_waa2/a.graceland.for.adolf_by.zev.borow.yml")

contents = yaml_loaded["text"]


# extractor = ContentExtractor.new(contents)

# p_texts = extractor.p_texts

p_texts = contents.split("\n")

# puts "Story contents:\n" + p_texts.join("\n")

line_parser = LineParser.new(p_texts)

puts line_parser.lines.join("\n\n")