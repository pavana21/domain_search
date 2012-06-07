class Word
  
  attr_accessor :wordstring, :rel_type
  
  def initialize(options={})
    @id = options['id']
    @wordstring = options['wordstring']
    @rel_type = options['rel_type']
  end

  # this is used for making api calls
  def client
    return Wordnik.client
  end
  
  # find a word, e.g. Word.find('cat')
  # returns a Word object
  # takes two optional arguments, :use_suggest and :literal
  # if options[:use_suggest]=true, it'll return an array of suggestions for your word.  
  # e.g. Word.find('Zeebra', {:use_suggest=>true}) will return {'id':87264, 'suggestions'=>['zebra'], 'wordstring'=>'Zeebra'}
  # if options[:use_suggest]=true and options[:literal]=false, it won't return an array of suggestions -- it'll simply return the most likely candidate 
  # e.g. Word.find('Zeebra', {:use_suggest=>true, :literal=>false}) will return {'id':87264, 'wordstring'=>'Zeebra'}
  def self.find(the_wordstring, options={})
    options[:use_suggest] ||= nil
    options[:not_literal] ||= false
    word_data = Wordnik.get("/word.json/#{URI.escape(the_wordstring)}", {:headers=>Wordnik.client.api_headers, :query=>{:useSuggest=>options[:use_suggest], :literal=>!options[:not_literal]}})
    if (options[:use_suggest].nil? || (options[:use_suggest] && options[:not_literal]))
      return Word.new(word_data)
    else
      return word_data
    end
  end

  # get this word's definitions
  # returns an array of Definition objects
  # has two options:
  # :limit - specifies the number of results (default=10)
  # :part_of_speech - restricts definitions to the given part of speech. you can ask for multiple parts of speech, like :part_of_speech=>"noun,verb,adjective"
  # supported parts of speech are:
  # noun, verb, adjective, adverb, idiom, article, abbreviation, preposition, prefix, interjection, suffix, conjunction, adjective_and_adverb, noun_and_adjective, noun_and_verb_transitive, noun_and_verb, past_participle, imperative, noun_plural, proper_noun_plural, verb_intransitive, proper_noun, adjective_and_noun, imperative_and_past_participle, pronoun, verb_transitive, noun_and_verb_intransitive, adverb_and_preposition, proper_noun_posessive, noun_posessive
  def definitions(options={})
    options[:limit] ||= 10
    options[:part_of_speech] ||= nil
    raw_defs = Wordnik.get("/word.json/#{URI.escape(self.wordstring)}/definitions", {:headers => self.client.api_headers, :query=>{:limit=>options[:limit], :partOfSpeech=>options[:part_of_speech]}} )
    return raw_defs.map{|definition| Definition.new(definition) }
  end

  # get example sentences for this word
  # returns an array of Example objects
  def examples
    raw_examples = Wordnik.get("/word.json/#{URI.escape(self.wordstring)}/examples", {:headers => self.client.api_headers} )
    return raw_examples.map{|example| Example.new(example) }
  end

  # get this word's related words
  # returns a hash -- keys are relation type (e.g. synonym, antonym, hyponym, etc), values are arrays of Word objects
  # two optional arguments:
  # :limit - the number of results
  # :type - restrict the results to the given relationship type. if you want multiple types, separate them with commas, e.g. :type=>'synonym,antonym'
  # available relationship types are synonym, antonym, form, hyponym, variant, verb-stem, verb-form, cross-reference, same-context
  # for an explanation of each relationship type, see http://docs.wordnik.com/api/methods#relateds
  def related(options={})
    options[:limit] ||= 100
    options[:type] ||= nil
    raw_related = Wordnik.get("/word.json/#{URI.escape(self.wordstring)}/related", {:headers => self.client.api_headers, :query=>{:limit=>options[:limit], :type=>options[:type]}})
    related_hash = {}
    raw_related.each{|type|
      related_hash[type['relType']] ||= []
      type['wordstrings'].each{|word|
        related_hash[type['relType']] << Word.new({'wordstring' => word, 'rel_type' => type['relType']})
      }
    }
    return related_hash
  end

  # get phrases that contain this word
  # e.g. Word.find("Christmas").phrases => ["merry Christmas", "Christmas Eve", "Christmas tree", ...]
  # has one option, :limit, which specifies the number of results (default=10)
  def phrases(options={})
    options[:limit] ||= 10
    word_phrases = Wordnik.get("/word.json/#{URI.escape(self.wordstring)}/phrases", {:headers => self.client.api_headers, :query=>{:limit=>options[:limit]}})
    return word_phrases
  end

  # see how often this word appears before punctuation (period, question mark, exclamation point)
  def punctuation
    punctuation_factor = Wordnik.get("/word.json/#{URI.escape(self.wordstring)}/punctuationFactor", {:headers => self.client.api_headers})
    return punctuation_factor
  end

  # fetches a word’s text pronunciation from the Wordnik corpus, in arpabet and/or gcide-diacritical format
  def text_pronunciation
    text_pron = Wordnik.get("/word.json/#{URI.escape(self.wordstring)}/pronunciations")
    return text_pron
  end

end
