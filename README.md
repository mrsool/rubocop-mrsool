# Rubocop::Mrsool

Custom cops used in mrsool backend.

## Usage

Enable cops in `.rubocop.yml` in the main repo as follows:

```ruby
Mrsool/LetsNot:
  Enabled: true
```

## Contributing

Before you start, read the [guide](https://www.fastruby.io/blog/rubocop/code-quality/create-a-custom-rubocop-cop.html) and check existing examples.
Read more info about node [patterns](https://github.com/rubocop/rubocop-ast/blob/master/docs/modules/ROOT/pages/node_pattern.adoc).

When you're ready:
- Create a cop file under `lib/rubocop/cop/mrsool/`
- Include the new file in `lib/rubocop/cop/mrsool_cops.rb`
- Don't forget to add specs
- Push changes to github and update the commit hash in Gemfile in the main repo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
