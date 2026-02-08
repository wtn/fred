# frozen_string_literal: true

require_relative "../test_helper"
require "sus/fixtures/async/http/server_context"

describe "FRED API methods" do
  include Sus::Fixtures::Async::HTTP::ServerContext

  SERIES_JSON = {
    "seriess" => [{
      "id" => "GNPCA",
      "title" => "Real Gross National Product",
      "observation_start" => "1929-01-01",
      "observation_end" => "2023-01-01",
      "frequency" => "Annual",
      "frequency_short" => "A",
      "units" => "Billions of Chained 2017 Dollars",
      "units_short" => "Bil. of Chn. 2017 $",
      "seasonal_adjustment" => "Not Seasonally Adjusted",
      "seasonal_adjustment_short" => "NSA",
      "last_updated" => "2024-03-28 07:56:03-05",
      "popularity" => 16,
      "notes" => "BEA Account Code: A001RX",
    }],
  }.freeze

  OBSERVATIONS_JSON = {
    "observations" => [
      { "date" => "2022-01-01", "value" => "20014.094" },
      { "date" => "2023-01-01", "value" => "21085.394" },
      { "date" => "2024-01-01", "value" => "." },
    ],
  }.freeze

  CATEGORIES_JSON = {
    "categories" => [
      { "id" => 0, "name" => "Categories", "parent_id" => 0 },
      { "id" => 32991, "name" => "Money, Banking, & Finance", "parent_id" => 0 },
    ],
  }.freeze

  RELEASES_JSON = {
    "releases" => [
      { "id" => 53, "name" => "Gross Domestic Product", "press_release" => true, "link" => "http://www.bea.gov/" },
      { "id" => 10, "name" => "Consumer Price Index", "press_release" => true, "link" => "http://www.bls.gov/" },
    ],
  }.freeze

  SOURCES_JSON = {
    "sources" => [
      { "id" => 1, "name" => "Board of Governors", "link" => "http://www.federalreserve.gov/", "notes" => "Notes" },
    ],
  }.freeze

  TAGS_JSON = {
    "tags" => [
      { "name" => "gdp", "group_id" => "gen", "notes" => "Gross Domestic Product", "created" => "2012-02-27 10:18:19-06", "popularity" => 100, "series_count" => 1234 },
    ],
  }.freeze

  RELEASE_DATES_JSON = {
    "release_dates" => [
      { "release_id" => 53, "date" => "2024-06-27" },
      { "release_id" => 53, "date" => "2024-03-28" },
    ],
  }.freeze

  RELEASES_DATES_JSON = {
    "release_dates" => [
      { "release_id" => 53, "release_name" => "Gross Domestic Product", "date" => "2024-06-27" },
      { "release_id" => 10, "release_name" => "Consumer Price Index", "date" => "2024-06-12" },
    ],
  }.freeze

  ERROR_JSON = {
    "error_code" => 429,
    "error_message" => "Too Many Requests.",
  }.freeze

  def json_headers
    [["content-type", "application/json; charset=UTF-8"]]
  end

  def app
    Protocol::HTTP::Middleware.for do |request|
      path = request.path.split("?").first

      case path
      when "/fred/series"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
      when "/fred/series/observations"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(OBSERVATIONS_JSON)]]
      when "/fred/series/search"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
      when "/fred/series/categories"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(CATEGORIES_JSON)]]
      when "/fred/series/release"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(RELEASES_JSON)]]
      when "/fred/series/tags"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(TAGS_JSON)]]
      when "/fred/series/updates"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
      when "/fred/category"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(CATEGORIES_JSON)]]
      when "/fred/category/children"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(CATEGORIES_JSON)]]
      when "/fred/category/series"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
      when "/fred/category/tags"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(TAGS_JSON)]]
      when "/fred/releases"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(RELEASES_JSON)]]
      when "/fred/release"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(RELEASES_JSON)]]
      when "/fred/release/series"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
      when "/fred/release/dates"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(RELEASE_DATES_JSON)]]
      when "/fred/releases/dates"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(RELEASES_DATES_JSON)]]
      when "/fred/sources"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SOURCES_JSON)]]
      when "/fred/source"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SOURCES_JSON)]]
      when "/fred/source/releases"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(RELEASES_JSON)]]
      when "/fred/tags"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(TAGS_JSON)]]
      when "/fred/tags/series"
        Protocol::HTTP::Response[200, json_headers, [JSON.generate(SERIES_JSON)]]
      when "/fred/error"
        Protocol::HTTP::Response[429, json_headers, [JSON.generate(ERROR_JSON)]]
      else
        Protocol::HTTP::Response[404, json_headers, ["{}"]]
      end
    end
  end

  let(:fred) do
    FRED::Client.new(
      api_key: TEST_API_KEY,
      endpoint: client_endpoint,
      rate_limit: false,
    )
  end

  # Series

  describe "#series" do
    it "returns a Series" do
      s = fred.series series_id: "GNPCA"
      expect(s).to be_a(FRED::Series)
      expect(s.id).to be == "GNPCA"
      expect(s.title).to be == "Real Gross National Product"
    end
  end

  describe "#series_observations" do
    it "returns a TimeSeries" do
      ts = fred.series_observations series_id: "GNPCA"
      expect(ts).to be_a(TimeSeries)
      expect(ts.index).to be == "date"
      expect(ts.cast?).to be == true
      expect(ts.types).to be == { "date" => :date, "GNPCA" => :float64? }
      expect(ts.metadata).to be == { series_id: "GNPCA" }
    end

    it "has correct dates and values" do
      ts = fred.series_observations series_id: "GNPCA"
      expect(ts.size).to be == 3
      expect(ts["date"].first).to be == Date.new(2022, 1, 1)
      expect(ts["GNPCA"].first).to be_within(0.001).of(20014.094)
    end

    it "parses missing values as nil" do
      ts = fred.series_observations series_id: "GNPCA"
      expect(ts["GNPCA"].last).to be == nil
    end
  end

  describe "#series_search" do
    it "returns an array of Series" do
      results = fred.series_search search_text: "gnp"
      expect(results.length).to be == 1
      expect(results.first).to be_a(FRED::Series)
      expect(results.first.id).to be == "GNPCA"
    end
  end

  describe "#series_categories" do
    it "returns an array of Categories" do
      cats = fred.series_categories series_id: "GNPCA"
      expect(cats.length).to be == 2
      expect(cats.first).to be_a(FRED::Category)
    end
  end

  describe "#series_release" do
    it "returns a Release" do
      rel = fred.series_release series_id: "GNPCA"
      expect(rel).to be_a(FRED::Release)
      expect(rel.id).to be == 53
    end
  end

  describe "#series_tags" do
    it "returns an array of Tags" do
      tags = fred.series_tags series_id: "GNPCA"
      expect(tags.length).to be == 1
      expect(tags.first).to be_a(FRED::Tag)
      expect(tags.first.name).to be == "gdp"
    end
  end

  describe "#series_updates" do
    it "returns an array of Series" do
      results = fred.series_updates
      expect(results.length).to be == 1
      expect(results.first).to be_a(FRED::Series)
    end
  end

  # Categories

  describe "#category" do
    it "returns a Category" do
      cat = fred.category
      expect(cat).to be_a(FRED::Category)
      expect(cat.id).to be == 0
      expect(cat.name).to be == "Categories"
    end
  end

  describe "#category_children" do
    it "returns an array of Categories" do
      cats = fred.category_children
      expect(cats.length).to be == 2
      expect(cats.first).to be_a(FRED::Category)
    end
  end

  describe "#category_series" do
    it "returns an array of Series" do
      results = fred.category_series category_id: 106
      expect(results.length).to be == 1
      expect(results.first).to be_a(FRED::Series)
    end
  end

  describe "#category_tags" do
    it "returns an array of Tags" do
      tags = fred.category_tags category_id: 106
      expect(tags.length).to be == 1
      expect(tags.first).to be_a(FRED::Tag)
    end
  end

  # Releases

  describe "#releases" do
    it "returns an array of Releases" do
      releases = fred.releases
      expect(releases.length).to be == 2
      expect(releases.first).to be_a(FRED::Release)
      expect(releases.first.id).to be == 53
    end
  end

  describe "#release" do
    it "returns a Release" do
      rel = fred.release release_id: 53
      expect(rel).to be_a(FRED::Release)
      expect(rel.name).to be == "Gross Domestic Product"
    end
  end

  describe "#release_series" do
    it "returns an array of Series" do
      results = fred.release_series release_id: 53
      expect(results.length).to be == 1
      expect(results.first).to be_a(FRED::Series)
    end
  end

  describe "#release_dates" do
    it "returns an array of ReleaseDates" do
      dates = fred.release_dates release_id: 53
      expect(dates.length).to be == 2
      expect(dates.first).to be_a(FRED::ReleaseDate)
      expect(dates.first.release_id).to be == 53
      expect(dates.first.date).to be == Date.new(2024, 6, 27)
      expect(dates.first.release_name).to be == nil
    end
  end

  describe "#releases_dates" do
    it "returns an array of ReleaseDates with names" do
      dates = fred.releases_dates
      expect(dates.length).to be == 2
      expect(dates.first).to be_a(FRED::ReleaseDate)
      expect(dates.first.release_id).to be == 53
      expect(dates.first.release_name).to be == "Gross Domestic Product"
      expect(dates.first.date).to be == Date.new(2024, 6, 27)
    end
  end

  # Sources

  describe "#sources" do
    it "returns an array of Sources" do
      sources = fred.sources
      expect(sources.length).to be == 1
      expect(sources.first).to be_a(FRED::Source)
      expect(sources.first.id).to be == 1
    end
  end

  describe "#source" do
    it "returns a Source" do
      src = fred.source source_id: 1
      expect(src).to be_a(FRED::Source)
      expect(src.name).to be == "Board of Governors"
    end
  end

  describe "#source_releases" do
    it "returns an array of Releases" do
      releases = fred.source_releases source_id: 1
      expect(releases.length).to be == 2
      expect(releases.first).to be_a(FRED::Release)
    end
  end

  # Tags

  describe "#tags" do
    it "returns an array of Tags" do
      tags = fred.tags
      expect(tags.length).to be == 1
      expect(tags.first).to be_a(FRED::Tag)
      expect(tags.first.name).to be == "gdp"
    end
  end

  describe "#tags_series" do
    it "returns an array of Series" do
      results = fred.tags_series tag_names: "gdp"
      expect(results.length).to be == 1
      expect(results.first).to be_a(FRED::Series)
    end
  end

  # Error handling

  describe "error handling" do
    it "raises FRED::Error on HTTP error" do
      bad_client = FRED::Client.new(
        api_key: TEST_API_KEY,
        endpoint: client_endpoint,
        rate_limit: false,
        retry_wait: 0.01,
      )
      expect do
        bad_client.send(:get, "error")
      end.to raise_exception(FRED::Error, message: be =~ /Too Many Requests/)
    end
  end
end
