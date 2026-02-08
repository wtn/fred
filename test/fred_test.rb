# frozen_string_literal: true

require_relative "test_helper"

describe FRED do
  it "has a version" do
    expect(FRED::VERSION).not.to be == nil
  end

  it "has a client accessor" do
    expect(FRED).to be(:respond_to?, :client)
  end

  it "has a reset_client! method" do
    expect(FRED).to be(:respond_to?, :reset_client!)
  end

  it "delegates series to client" do
    expect(FRED).to be(:respond_to?, :series)
  end

  it "delegates series_observations to client" do
    expect(FRED).to be(:respond_to?, :series_observations)
  end

  it "delegates series_search to client" do
    expect(FRED).to be(:respond_to?, :series_search)
  end

  it "delegates category to client" do
    expect(FRED).to be(:respond_to?, :category)
  end

  it "delegates releases to client" do
    expect(FRED).to be(:respond_to?, :releases)
  end

  it "delegates sources to client" do
    expect(FRED).to be(:respond_to?, :sources)
  end

  it "delegates tags to client" do
    expect(FRED).to be(:respond_to?, :tags)
  end
end
