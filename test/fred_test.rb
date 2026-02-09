require 'test_helper'

class FredTest < Minitest::Test

  context 'Fred API' do
    setup do
      @client = Fred::Client.new(api_key: 'wtf')
    end

    context 'and get categories' do
      should 'find a specific category' do
        Fred::Client.stub :get, stub_request('category.xml') do
          result = @client.category(nil, category_id: '125')
          assert_equal 'Trade Balance', result.categories.category.name
        end
      end
    end

    context 'and get releases' do
      should 'find all releases' do
        Fred::Client.stub :get, stub_request('releases.xml') do
          result = @client.releases(nil)
          assert_equal 'Advance Monthly Sales for Retail and Food Services', result.first.last.release.first.name
          assert_equal 'Dallas Fed Energy Survey', result.first.last.release.last.name
        end
      end
    end

    context 'and get a release' do
      should 'find a specific release' do
        Fred::Client.stub :get, stub_request('release.xml') do
          result = @client.release(nil, release_id: '53')
          assert_equal 'Gross Domestic Product', result.releases.release.name
        end
      end
    end

    context 'and get series' do
      should 'find a specific series' do
        Fred::Client.stub :get, stub_request('series.xml') do
          result = @client.series(nil, series_id: 'GNPC')
          assert_equal 'Real Gross National Product', result.seriess.series.title
        end
      end
    end

    context 'and get source' do
      should 'find a specific source' do
        Fred::Client.stub :get, stub_request('source.xml') do
          result = @client.source(nil, source_id: '1')
          assert_equal 'Board of Governors of the Federal Reserve System (US)', result.sources.source.name
        end
      end
    end

    context 'and get sources' do
      should 'find all sources' do
        Fred::Client.stub :get, stub_request('sources.xml') do
          result = @client.sources(nil, source_id: '1')
          assert_equal 'Board of Governors of the Federal Reserve System (US)', result.sources.source.first.name
          assert_equal 'Barrero, Jose Maria', result.sources.source.last.name
        end
      end
    end

  end

  context 'API key from environment' do
    should 'read FRED_API_KEY when no key is passed' do
      ENV['FRED_API_KEY'] = 'env-key'
      client = Fred::Client.new
      assert_equal 'env-key', client.api_key
    ensure
      ENV.delete 'FRED_API_KEY'
    end
  end

end
