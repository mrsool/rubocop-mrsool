# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::DoNotUseDeleteMatched, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using `#bad_method`' do
    expect_offense(<<~RUBY)
      Rails.cache.delete_matched('foo')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use delete_matched, use RedisHashStore#delete_hash instead
    RUBY
  end
end
