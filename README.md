# rubydeps

The DependencyWorker currently performs the following actions:

* Fetch gemfile and gemspec for a given Gem
  * Currently, the GithubGem class specifies the needed information for a gem hosted on github. Other providers could be added.
* Parse both files for dependency-requirements
* Determine the latest version for each required gem
* Generate a Hash of results of the following form:
```ruby
{
  "gemspec" => [
    {"name"=>"gollum-lib", "required"=>">= 4.2.10, ~> 4.2", "latest"=>"4.2.10", "outdated"=>false},
    {"name"=>"kramdown", "required"=>"~> 1.9.0", "latest"=>"2.1.0", "outdated"=>true}
  ],
  "gemfile" => [
    {"name"=>"rake", "required"=>"~> 10.4", "latest"=>"13.0.1", "outdated"=>true}
  ]
}
```
* These results are stored as JSON in Redis using a `Redis::HashKey`. The default Redis key under which this `HashKey` is saved is `:github`.
  

## Example usage

See `test.rb`. The basics:

* start a Redis server with `redis-server`
* start `sidekiq` with `bundle exec sidekiq -r ./lib/workers/dependency.rb`
* Run the following code (or `bundle exec ruby test.rb`):

```ruby
Redis::Objects.redis = Redis.new
github_repos = Redis::HashKey.new(:github)
# There is nothing in the HashKey at the moment

gem = GithubGem.new('gollum', 'gollum')
DependencyWorker.perform_async(gem.identifier, gem.gemspec_location, gem.gemfile_location) # Fire up a Sidekiq job

# Sleep 5

puts github_repos.keys # ['gollum/gollum']
github_repos['gollum/gollum'] # The JSON results hash
```