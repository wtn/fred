# FRED

## Configuration

Add your API key to the environment:

```sh
export FRED_API_KEY=d5232867f3cfe9db23c68f470d1a4c70
```

## Usage

```ruby
require "fred"

# Fetch a series
gdp = FRED.series series_id: "GDP"
gdp.title      #=> "Gross Domestic Product"
gdp.frequency  #=> "Quarterly"

# Get observations
obs = FRED.series_observations series_id: "GDP", limit: 5, sort_order: "desc"
obs.each { |o| puts "#{o.date} => #{o.value}" }

# Search for series
results = FRED.series_search search_text: "unemployment rate", limit: 3
results.each { |s| puts "#{s.id}: #{s.title}" }
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wtn/fred.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
