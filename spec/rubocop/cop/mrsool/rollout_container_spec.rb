# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::RolloutContainer, :config do
  let(:config) { RuboCop::Config.new }

  it "matches ROLLOUT_FLAGS" do
    expect_offense(<<~RUBY)
      ROLLOUT_FLAGS.foo.enabled?
      ^^^^^^^^^^^^^ Use `Rollout[:platform]` or consider moving the flag to a feature specific container like `Rollout[:your_feature]`
    RUBY

    expect_correction(<<~RUBY)
      Rollout[:platform].foo.enabled?
    RUBY
  end
end
