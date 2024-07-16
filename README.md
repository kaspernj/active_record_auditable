# ActiveRecordAuditable
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "active_record_auditable"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install active_record_auditable
```

```bash
rails active_record_auditable:install:migrations
```

Sometimes you need to do something like this in `config/initializers/active_record_auditable.rb`:
```ruby
Rails.configuration.to_prepare do
  ActiveRecordAuditable::Audit.class_eval do
    belongs_to :user, default: -> { Current.user }, optional: true

    serialize :audited_changes, coder: JSON
  end
end
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
