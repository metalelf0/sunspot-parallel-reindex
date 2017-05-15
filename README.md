# Sunspot::Parallel::Reindex

Add support for multi-process reindexing with sunspot.

[![Gem Version](https://badge.fury.io/rb/sunspot-parallel-reindex.svg)](http://badge.fury.io/rb/sunspot-parallel-reindex)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sunspot-parallel-reindex', git: 'https://github.com/metalelf0/sunspot-parallel-reindex'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sunspot-parallel-reindex

## Usage

Parameters are all optional, just like `rake sunspot:reindex`

    $ rake sunspot:reindex:parallel[<batch_size>,<models>,<processors>,<first_id>]

* `batch_size`: the size of each batch of records. Default: 1000
* `models`: a list of model names to be indexed. Defaults to `Sunspot.searchable`
* `processors`: how many processors to use. Default: 1
* `first_id`: the first id to index. Used to resume an indexing. Default: nil

When `first_id` option is passed the rake task will no longer remove all models from the index.
This allows resuming a previously interrupted indexing or reindexing just most recent models.

## Contributing

1. Fork it ( https://github.com/btucker/sunspot-parallel-reindex/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Thanks

Code heavily inspired by https://github.com/MiraitSystems/enju_trunk/
