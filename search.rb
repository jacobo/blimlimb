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
    # puts "hits: #{size}"
    if prob_sort && size > 10000
      iterations = 50 * Math.sqrt(size)
      offsets = @sa.lazyhits_to_offsets(hits)
      weight_arr = weights.sort_by{|id,w| id}.map{|_,v| v}
      sorted = @dm.rank_offsets_probabilistic(offsets, weight_arr, iterations)
    else
      offsets = @sa.lazyhits_to_offsets(hits)
      sorted = @dm.rank_offsets(offsets, weights.sort_by{|id,w| id}.map{|_,v| v})
    end
    # puts "Found #{sorted.size} matches"
    sorted[0..show].map do |doc_id, count|
      [@dm.document_id_to_uri(doc_id), count]
    end
  end
  
  def find_most terms_array
    # weights = Hash.new(1.0)
    # weights[0] = 10000000   # :uri
    # weights[1] = 10000000  # :body
    
    # terms_array.reject!{ |term| term.size < }
    
    combined_terms_array = []
    combiner = Proc.new do |num_terms, min_term_size|
      prev_terms = []
      terms_array.each do |term|
        combined_terms_in_reverse = [term]
        if prev_terms.size >= num_terms-1 && (prev_terms + [term]).detect{|t| t.size > min_term_size}
          prev_terms.reverse[0,num_terms-1].each do |prev_term|
            combined_terms_in_reverse << prev_term
          end
          combined_terms_array << combined_terms_in_reverse.reverse.join(" ")
        end
        prev_terms.push(term)
      end
    end
    combiner.call(5, 2)
    combiner.call(4, 2)
    combiner.call(3, 2)
    combiner.call(2, 5)
    combiner.call(1, 8)
    
    to_return = []
    # results = []
    combined_terms_array.each do |term|
      # puts "Searching for #{term}"
      hits = @sa.find_all term
      offsets = @sa.lazyhits_to_offsets(hits)
      # sorted = @dm.rank_offsets(offsets, weights.sort_by{|id,w| id}.map{|_,v| v})
      
      doc_ids_to_found_offsets = {}
      @dm.offsets_to_field_infos(offsets).each do |offset, doc_id, field_id, field_size|
        doc_ids_to_found_offsets[doc_id] ||= []
        doc_ids_to_found_offsets[doc_id] << offset
      end
      doc_uris_to_found_offsets = {}
      doc_ids_to_found_offsets.each{ |k,v| doc_uris_to_found_offsets[@dm.document_id_to_uri(k)] = v }
      
      if doc_uris_to_found_offsets.size > 0
        to_return << [term, doc_uris_to_found_offsets.keys]
      end
      # doc_to_count = sorted.map do |doc_id, count|
      #   [@dm.document_id_to_uri(doc_id), count]
      # end
      # puts "hit is a: " + hits.first.inspect
      # puts "doc_uris_to_found_offsets: " + doc_uris_to_found_offsets.inspect
      # results << [term, doc_to_count]
    end
    to_return
  end
  
end

# searcher = Search.new
# 
# mit_waa_dir = File.join(File.dirname(__FILE__), 'mit_waa')
# stories = {}
# Dir.new(mit_waa_dir).each do |entry|
#   unless entry[0,1] == "."
#     to_add = YAML::load_file(File.join(mit_waa_dir, entry))
#     stories[entry] = to_add
#     searcher.add_document(:uri => entry, :title => to_add["title"], :text => to_add["text"])
#   end
# end
# 
# searcher.finish!
# 
# found_mostly = searcher.find_most("cinco de mayo means I'll be in late tomorrow morning".split(" "))
# 
# found_mostly.each do |term, docs_found_in|
#   # puts "#{term} found in #{docs_found_in.join(',')}"
#   docs_found_in.each do |doc_id|
#     story_text = stories[doc_id]["text"]
#     # puts "index of #{term} "
#     if term_at = story_text.index(term)
#       start_at = term_at - 100
#       end_at = term_at + 100
#       if start_at < 0
#         end_at += start_at
#         start_at = 0      
#       end
#       puts "---#{term}---"
#       snippet = story_text[start_at...end_at]
#       start_point = snippet.index(term) - term.size
#       end_point = snippet.index(term) + term.size
#       start_found = false
#       end_found = false
#       
#       while !start_found && start_point > 0
#         char = snippet[start_point, 1]
#         if char == "." || char == "?" || char == "!" || char == "\n"
#           start_found = true
#           start_point += 1
#         else
#           start_point -= 1
#         end
#       end
# 
#       while !end_found && end_point < snippet.size
#         char = snippet[end_point, 1]
#         if char == "." || char == "?" || char == "!" || char == "\n"
#           end_found = true
#         else
#           end_point += 1
#         end
#       end
# 
#       shorter_snip = snippet[start_point...end_point]
#       # puts snippet
#       # puts "---"
#       puts shorter_snip
# 
#     end
#   end
# end
# 
