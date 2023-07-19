# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::PluralFactoryFilename, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it 'registers an offense for plural factory filenames' do
    expect_offense(<<~RUBY, 'spec/fixtures/factories/users_factory.rb')
      # frozen_string_literal: true

      FactoryBot.define do
      ^^^^^^^^^^^^^^^^^^^^ Factory filename should be singular.
        factory :user do
          name { 'John Doe' }
        end
      end
    RUBY
  end

  it 'does not register an offense for singular factory filenames' do
    expect_no_offenses(<<~RUBY, 'spec/fixtures/factories/user_factory.rb')
      # frozen_string_literal: true

      FactoryBot.define do
        factory :user do
          name { 'John Doe' }
        end
      end
    RUBY
  end
end
