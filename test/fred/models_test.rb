# frozen_string_literal: true

require_relative "../test_helper"

describe FRED::Series do
  let(:row) do
    {
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
    }
  end

  it "parses all fields" do
    s = FRED::Series.parse row
    expect(s.id).to be == "GNPCA"
    expect(s.title).to be == "Real Gross National Product"
    expect(s.observation_start).to be == "1929-01-01"
    expect(s.observation_end).to be == "2023-01-01"
    expect(s.frequency).to be == "Annual"
    expect(s.frequency_short).to be == "A"
    expect(s.units).to be == "Billions of Chained 2017 Dollars"
    expect(s.units_short).to be == "Bil. of Chn. 2017 $"
    expect(s.seasonal_adjustment).to be == "Not Seasonally Adjusted"
    expect(s.seasonal_adjustment_short).to be == "NSA"
    expect(s.last_updated).to be == "2024-03-28 07:56:03-05"
    expect(s.popularity).to be == 16
    expect(s.notes).to be == "BEA Account Code: A001RX"
  end

  it "handles missing notes" do
    row.delete "notes"
    s = FRED::Series.parse row
    expect(s.notes).to be == nil
  end

  it "is immutable" do
    s = FRED::Series.parse row
    expect { s.id = "OTHER" }.to raise_exception(NoMethodError)
  end
end

describe FRED::Category do
  it "parses fields" do
    cat = FRED::Category.parse("id" => 125, "name" => "Trade Balance", "parent_id" => 13)
    expect(cat.id).to be == 125
    expect(cat.name).to be == "Trade Balance"
    expect(cat.parent_id).to be == 13
  end
end

describe FRED::Release do
  it "parses fields" do
    rel = FRED::Release.parse(
      "id" => 53,
      "name" => "Gross Domestic Product",
      "press_release" => true,
      "link" => "http://www.bea.gov/national/index.htm",
    )
    expect(rel.id).to be == 53
    expect(rel.name).to be == "Gross Domestic Product"
    expect(rel.press_release).to be == true
    expect(rel.link).to be == "http://www.bea.gov/national/index.htm"
  end

  it "handles nil link" do
    rel = FRED::Release.parse("id" => 10, "name" => "Test", "press_release" => false)
    expect(rel.link).to be == nil
  end
end

describe FRED::Source do
  it "parses fields" do
    src = FRED::Source.parse(
      "id" => 1,
      "name" => "Board of Governors",
      "link" => "http://www.federalreserve.gov/",
      "notes" => "Some notes",
    )
    expect(src.id).to be == 1
    expect(src.name).to be == "Board of Governors"
    expect(src.link).to be == "http://www.federalreserve.gov/"
    expect(src.notes).to be == "Some notes"
  end
end

describe FRED::ReleaseDate do
  it "parses fields with release_name" do
    rd = FRED::ReleaseDate.parse(
      "release_id" => 53,
      "release_name" => "Gross Domestic Product",
      "date" => "2024-06-27",
    )
    expect(rd.release_id).to be == 53
    expect(rd.release_name).to be == "Gross Domestic Product"
    expect(rd.date).to be == Date.new(2024, 6, 27)
  end

  it "parses fields without release_name" do
    rd = FRED::ReleaseDate.parse(
      "release_id" => 53,
      "date" => "2024-06-27",
    )
    expect(rd.release_id).to be == 53
    expect(rd.release_name).to be == nil
    expect(rd.date).to be == Date.new(2024, 6, 27)
  end
end

describe FRED::Tag do
  it "parses fields" do
    tag = FRED::Tag.parse(
      "name" => "gdp",
      "group_id" => "gen",
      "notes" => "Gross Domestic Product",
      "created" => "2012-02-27 10:18:19-06",
      "popularity" => 100,
      "series_count" => 1234,
    )
    expect(tag.name).to be == "gdp"
    expect(tag.group_id).to be == "gen"
    expect(tag.notes).to be == "Gross Domestic Product"
    expect(tag.created).to be == "2012-02-27 10:18:19-06"
    expect(tag.popularity).to be == 100
    expect(tag.series_count).to be == 1234
  end
end
