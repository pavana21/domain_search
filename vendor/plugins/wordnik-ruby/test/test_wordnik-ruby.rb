require 'helper'

class TestWordnikRuby < Test::Unit::TestCase

  should "raise InvalidApiKeyError if no api key specified in initializer" do
    assert_raise(InvalidApiKeyError) do
      Wordnik.new
    end
  end

  context "a valid api key" do
    setup do
      @api_key = "test_api_key"
    end

    should "instantiate a Wordnik object without authentication" do
      w = Wordnik.new({:api_key=>@api_key})
      assert_equal w.class, Wordnik
      assert_equal w.api_key, @api_key
      assert w.auth_token.nil?
      assert w.user_id.nil?
      assert !w.authenticated?
    end

    context "a valid, unauthenticated Wordnik client" do
      setup do
        @w = Wordnik.new({:api_key=>@api_key})
      end

      should "raise InvalidAuthTokenError for api methods that require authentication, if no valid auth_key" do
        assert_raise(InvalidAuthTokenError){ @w.lists }
        assert_raise(InvalidAuthTokenError){ @w.create_list("testlist", "testdescription") }
      end

      should "get api headers" do
        assert_equal @w.api_headers, {'Content-Type'=>'application/json', 'api_key' => @api_key}
      end

      should 'get the word of the day' do
        stub_get('/wordoftheday.json', 'wotd.json')
        wotd = @w.word_of_the_day
        assert_equal wotd['wordstring'], 'stammel'
        assert_equal wotd['note'], "Stammel is probably an alteration of a Latin word meaning 'consisting of threads'."
        ['definition', 'example'].each do |attr|
          assert wotd[attr].is_a?(Array)
          assert_equal wotd[attr].length, 3
        end
      end

      should 'get a random word' do
        stub_get('/words.json/randomWord?hasDictionaryDef=true', 'word_random.json')
        randar = @w.random_word
        assert randar.is_a?(Word)
      end

      should 'get autocomplete results' do
        stub_get('/suggest.json/an?maxResults=15&startAt=0', 'word_autocomplete.json')
        search_results = @w.autocomplete('an', {:page=>1, :per_page=>15})
        assert search_results['match'].is_a?(Array)
        assert_equal search_results['match'].length, 16
        assert_equal search_results['match'][1]['wordstring'], 'answered'
        assert search_results['matches'].is_a?(Fixnum)
        assert search_results['more'].is_a?(Fixnum)
        assert search_results['searchTerm'].is_a?(Hash)
        assert search_results['searchTerm']['wordstring']=='an'
      end

      should 'find a word' do
        stub_get('/word.json/cat?literal=true&useSuggest=', 'word_find.json')
        word = Word.find('cat')
        assert word.is_a?(Word)
        assert_equal word.wordstring, 'cat'
      end

      should 'find a word with useSuggest=true' do
        stub_get('/word.json/cat?literal=true&useSuggest=true', 'word_find.json')
        word_data = Word.find('cat', :use_suggest=>true)
        assert word_data.is_a?(Hash)
        assert_equal word_data['wordstring'], 'cat'
      end

      context "a valid word" do
        setup do
          stub_get('/word.json/cat?literal=true&useSuggest=', 'word_find.json')
          @word = Word.find('cat')
        end

        should 'get definitions for a word' do
          stub_get('/word.json/cat/definitions?limit=10&partOfSpeech=', 'word_definitions.json')
          definitions = @word.definitions
          assert_equal definitions.length, 11
          d0 = definitions[0]
          assert d0.is_a?(Definition)
          assert_equal d0.headword, 'cat'
          assert_equal d0.part_of_speech, 'noun'
          assert_equal d0.text, "Any animal belonging to the natural family Felidae, and in particular to the various species of the genera Felis, Panthera, and Lynx. The domestic cat is Felis domestica. The European wild cat (Felis catus) is much larger than the domestic cat. In the United States the name wild cat is commonly applied to the bay lynx (Lynx rufus). The larger felines, such as the lion, tiger, leopard, and cougar, are often referred to as cats, and sometimes as big cats. See wild cat, and tiger cat."
        end

        should 'get examples for a word' do
          stub_get('/word.json/cat/examples', 'word_examples.json')
          examples = @word.examples
          assert_equal examples.length, 5
          e0 = examples[0]
          assert e0.is_a?(Example)
          assert_equal e0.year, 1992
          assert_equal e0.title, "Timegod's World"
          assert_equal e0.display, "That mountain cat is a very confused young hunter, and he might not attack you the next time, and you might be able to dive out of the way again."
        end

        should 'get related words for a word' do
          stub_get('/word.json/cat/related?limit=100&type=', 'word_related.json')
          related = @word.related
          assert_equal related.keys.sort, ["cross-reference", "equivalent", "form", "hyponym", "same-context", "synonym", "variant", "verb-form"]
          related.each do |k,v| 
            assert v.is_a?(Array)
            v.each do |rel_word|
              assert rel_word.is_a?(Word)
              assert_equal rel_word.rel_type, k
            end
          end
        end

        should 'get bigram phrases for a word' do
          stub_get('/word.json/cat/phrases?limit=10', 'word_phrases.json')
          phrases = @word.phrases
          assert phrases.is_a?(Array)
          assert_equal phrases.length, 5
          p0 = phrases[0]
          assert_equal p0['gram1'], 'keyboard'
          assert_equal p0['gram2'], 'cat'
        end

        should 'get punctuation factor for a word' do
          stub_get('/word.json/cat/punctuationFactor', 'word_punctuation.json')
          punctuation = @word.punctuation
          assert punctuation.is_a?(Hash)
          assert_equal punctuation['exclamationPointCount'], 1787
          assert_equal punctuation['questionMarkCount'], 1365
          assert_equal punctuation['periodCount'], 27245
          assert_equal punctuation['totalCount'], 112461
        end

        should 'get text pron for a word' do
          stub_get('/word.json/cat/pronunciations', 'word_text_pron.json')
          text_pron = @word.text_pronunciation
          assert text_pron.is_a?(Array)
          assert_equal text_pron[0]['rawType'], 'gcide-diacritical'
          assert_equal text_pron[1]['rawType'], 'arpabet'
        end

      end

    end

    should "instantiate a Wordnik object with authentication" do
      Wordnik.new({:api_key=>@api_key})
      stub_get('/account.json/authenticate/test_user?password=test_pw', 'user_token.json')
      w = Wordnik.new({:api_key=>@api_key, :username=>"test_user", :password=>"test_pw"})
      assert_equal w.class, Wordnik
      assert_equal w.api_key, @api_key
      assert w.auth_token, "test_token"
      assert w.user_id, 1234567
      assert w.authenticated?
    end

    context "a valid, authenticated Wordnik client" do
      setup do
        Wordnik.new({:api_key=>@api_key})
        stub_get('/account.json/authenticate/test_user?password=test_pw', 'user_token.json')
        @w = Wordnik.new({:api_key=>@api_key, :username=>"test_user", :password=>"test_pw"})
      end

      should "get a user's lists" do
        stub_get('/wordLists.json', 'wordlists.json')
        lists = @w.lists
        assert_equal lists.length, 1
      end

      context "a valid list" do
        setup do
          stub_get('/wordLists.json', 'wordlists.json')
          lists = @w.lists
          @l = lists[0]
        end

        should "validate the test list's attrs" do
          assert @l.is_a?(List)
          assert_equal @l.user_name, 'test_user'
          assert_equal @l.name, "animals"
          assert_equal @l.description, "a trip to the zoo"
          assert_equal @l.word_count, 3
        end

        should "get the words from a list" do
          stub_get("/wordList.json/#{@l.permalink_id}/words", "wordlist_words.json")
          list_words = @l.words
          assert_equal list_words.length, @l.word_count
          lw0 = list_words[0]
          assert_equal lw0['wordstring'], "giraffe"
        end

      end

    end

  end

end
