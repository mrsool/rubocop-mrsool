# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::SidekiqWorkerDirtyRename, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it 'does not register an offense when worker class name matches path' do
    expect_no_offenses(<<~RUBY, 'app/workers/orders/expire_worker.rb')
      # frozen_string_literal: true

      module Orders
        class ExpireWorker
          include Sidekiq::Worker
          def perform; end
        end
      end
    RUBY
  end

  it 'does not register an offense for top-level worker matching path' do
    expect_no_offenses(<<~RUBY, 'app/workers/sms_worker.rb')
      # frozen_string_literal: true

      class SmsWorker
        include Sidekiq::Worker
        def perform; end
      end
    RUBY
  end

  it 'registers an offense when worker class name does not match path' do
    expect_offense(<<~RUBY, 'app/workers/orders/expire_worker.rb')
      # frozen_string_literal: true

      module Orders
        class ExpireOrderWorker
        ^^^^^^^^^^^^^^^^^^^^^ Do not change Sidekiq worker names. Expected `Orders::ExpireWorker` (from path) but found `Orders::ExpireOrderWorker`. Keep the worker name the same.
          include Sidekiq::Worker
          def perform; end
        end
      end
    RUBY
  end

  it 'registers an offense when top-level worker class does not match path' do
    expect_offense(<<~RUBY, 'app/workers/sms_worker.rb')
      # frozen_string_literal: true

      class SmsNotificationWorker
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not change Sidekiq worker names. Expected `SmsWorker` (from path) but found `SmsNotificationWorker`. Keep the worker name the same.
        include Sidekiq::Worker
        def perform; end
      end
    RUBY
  end

  it 'does not register an offense for non-worker files' do
    expect_no_offenses(<<~RUBY, 'app/workers/orders/expire_worker.rb')
      # frozen_string_literal: true

      module Orders
        class ExpireOrderWorker
          def perform; end
        end
      end
    RUBY
  end
end
