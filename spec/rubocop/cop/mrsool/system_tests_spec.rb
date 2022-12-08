# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::SystemTests, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when using :feature tag" do
    expect_offense(<<~RUBY)
      RSpec.describe "whatever", type: :feature do
                                 ^^^^^^^^^^^^^^ Prefer system tests over features. Tag it with type: :system
      end
    RUBY
  end

  it "registers an offense when using strings" do
    expect_offense(<<~RUBY)
      RSpec.describe "whatever", 'type' => 'feature' do
                                 ^^^^^^^^^^^^^^^^^^^ Prefer system tests over features. Tag it with type: :system
      end
    RUBY
  end

  it "registers an offense when RSpec is omitted" do
    expect_offense(<<~RUBY)
      describe "whatever", 'type' => 'feature' do
                           ^^^^^^^^^^^^^^^^^^^ Prefer system tests over features. Tag it with type: :system
      end
    RUBY
  end

  it "registers an offense when using mutiple tags" do
    expect_offense(<<~RUBY)
      RSpec.describe "whatever", js: true, type: 'feature', foo: :bar do
                                           ^^^^^^^^^^^^^^^ Prefer system tests over features. Tag it with type: :system
      end
    RUBY
  end

  it "is calm without a feature tag" do
    expect_no_offenses(<<~RUBY)
      RSpec.describe "whatever", js: true, foo: :bar do
      end
    RUBY
  end

  it "does not alert on arbitrary hashes" do
    expect_no_offenses(<<~RUBY)
      RSpec.describe "whatever", js: true, foo: :bar do
        { type: :feature }
      end
    RUBY
  end
end

