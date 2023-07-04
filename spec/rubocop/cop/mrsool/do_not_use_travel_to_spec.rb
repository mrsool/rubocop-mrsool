# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::DoNotUseTravelTo, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense for travel_to with 'travel_to(time)' format" do
    expect_offense(<<~RUBY)
      travel_to(foo)
      ^^^^^^^^^^^^^^ Do not use travel_to, use Timecop.freeze instead. Check our freeze meta syntax in rails_helper.rb
    RUBY
  end

  it "registers an offense for travel_to with 'travel_to time' format" do
    expect_offense(<<~RUBY)
      travel_to foo
      ^^^^^^^^^^^^^ Do not use travel_to, use Timecop.freeze instead. Check our freeze meta syntax in rails_helper.rb
    RUBY
  end
end
