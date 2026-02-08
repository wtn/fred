# Fred

This is a Ruby wrapper for the St. Louis Federal Reserve Economic Data [FRED API](https://api.stlouisfed.org/).

## Installation

As a gem:

    gem install fred

## Get a FRED API key

Sign up for a FRED API key: [https://api.stlouisfed.org/api_key.html](https://api.stlouisfed.org/api_key.html)

## Usage

### Instantiate a client

    fred = Fred::Client.new(api_key: 'your_api_key')

### or configure once

    Fred.configure do |config|
      config.api_key = 'your_api_key'
    end
    fred = Fred::Client.new

#### Examples

    fred.category(nil, category_id: '125')
    => #<Fred::Mash categories=#<Fred::Mash category=#<Fred::Mash id="125" name="Trade Balance" parent_id="13">>>

    fred.series(nil, series_id: 'GNPA')
    => #<Fred::Mash seriess=#<Fred::Mash series=#<Fred::Mash id="GNPA" title="Gross National Product" frequency="Annual" ...>>>

    fred.series('observations', series_id: 'GNPA')
    => #<Fred::Mash observations=#<Fred::Mash count="96" observation=[#<Fred::Mash date="1929-01-01" value="105.3">, ...]>>

## Copyright

Contact me if you have any suggestions and feel free to fork it!

Copyright (c) 2009 Johnny Khai Nguyen, released under the MIT license
