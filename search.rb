$:.unshift File.join(File.dirname(__FILE__), 'ftsearch', 'lib')
require 'ftsearch/fragment_writer'
require 'ftsearch/analysis/simple_identifier_analyzer'
require 'ftsearchrt'
require 'yaml'

class Search
  include FTSearch
  attr_reader :index
  def initialize fields = [:title, :text]
    field_infos = FTSearch::FieldInfos.new
    fields.each do |name|
      field_infos.add_field :name => name,
        :analyzer => FTSearch::Analysis::SimpleIdentifierAnalyzer.new
    end
    @index = FTSearch::FragmentWriter.new :path => nil, :field_infos => field_infos
  end
  def add_document hsh
    @index.add_document hsh
  end
  def finish!
    @index.finish!

    @ft = FulltextReader.new :io => StringIO.new(@index.fulltext_writer.data)
    @sa = SuffixArrayReader.new @ft, nil, :io => StringIO.new(@index.suffix_array_writer.data)
    @dm = DocumentMapReader.new :io => StringIO.new(@index.doc_map_writer.data)
  end
  def find_all terms, show = 100, prob_sort = false
    h = Hash.new{|h,k| h[k] = 0}
    weights = Hash.new(1.0)
    weights[0] = 10000000   # :uri
    weights[1] = 10000000  # :body
    hits = @sa.find_all terms
    size = hits.size
    puts "hits: #{size}"
    if prob_sort && size > 10000
      iterations = 50 * Math.sqrt(size)
      offsets = @sa.lazyhits_to_offsets(hits)
      weight_arr = weights.sort_by{|id,w| id}.map{|_,v| v}
      sorted = @dm.rank_offsets_probabilistic(offsets, weight_arr, iterations)
    else
      offsets = @sa.lazyhits_to_offsets(hits)
      sorted = @dm.rank_offsets(offsets, weights.sort_by{|id,w| id}.map{|_,v| v})
    end
    puts "Found #{sorted.size} matches"
    sorted[0..show].map do |doc_id, count|
      [@dm.document_id_to_uri(doc_id), count]
    end
  end
  
  def find_most terms_array
    weights = Hash.new(1.0)
    weights[0] = 10000000   # :uri
    weights[1] = 10000000  # :body
    
    terms_array.each do |term|
      hits = @sa.find_all term
      offsets = @sa.lazyhits_to_offsets(hits)
      sorted = @dm.rank_offsets(offsets, weights.sort_by{|id,w| id}.map{|_,v| v})
      # puts "hit is a: " + hits.first.inspect
      puts "sorted: " + sorted.inspect
    end
  end
  
end

searcher = Search.new

mit_waa_dir = File.join(File.dirname(__FILE__), 'mit_waa')
Dir.new(mit_waa_dir).each do |entry|
  unless entry[0,1] == "."
    to_add = YAML::load_file(File.join(mit_waa_dir, entry))
    searcher.add_document(:uri => entry, :title => to_add["title"], :text => to_add["text"])
  end
end

searcher.finish!

puts searcher.find_most("solution to this problem in order to close the ticket".split(" ")).to_yaml
