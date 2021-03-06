# This spec is a good example for:
#
# If test look that ugly the class under test sucks.
#
# As the bootstrap needs to infect global VM state
# this is to some degree acceptable.
#
# Still the bootstrap needs to be cleaned up.
# And the change that added this warning did the groundwork.
RSpec.describe Mutest::Env::Bootstrap do
  let(:matcher_config)       { Mutest::Matcher::Config::DEFAULT     }
  let(:integration)          { instance_double(Mutest::Integration) }
  let(:integration_class)    { instance_double(Class)               }
  let(:object_space_modules) { []                                   }

  let(:config) do
    Mutest::Config::DEFAULT.with(
      includes:    [],
      integration: integration_class,
      jobs:        1,
      matcher:     matcher_config,
      reporter:    instance_double(Mutest::Reporter),
      requires:    []
    )
  end

  let(:expected_env) do
    Mutest::Env.new(
      actor_env:        Mutest::Actor::Env.new(Thread),
      config:           config,
      integration:      integration,
      matchable_scopes: [],
      mutations:        [],
      parser:           Mutest::Parser.new,
      selector:         Mutest::Selector::Expression.new(integration),
      subjects:         []
    )
  end

  shared_examples_for 'bootstrap call' do
    it { is_expected.to eql(expected_env) }
  end

  def expect_warning
    expect(config.reporter).to receive(:warn)
      .with(expected_warning)
      .and_return(config.reporter)
  end

  before do
    expect(integration_class).to receive(:new)
      .with(config)
      .and_return(integration)

    expect(integration).to receive_messages(setup: integration)

    expect(ObjectSpace).to receive(:each_object)
      .with(Module)
      .and_return(object_space_modules.each)
  end

  describe '#warn' do
    subject { object.warn(expected_warning) }

    let(:object)           { described_class.new(config) }
    let(:expected_warning) { instance_double(String)     }

    before { expect_warning }

    it_behaves_like 'a command method'
  end

  describe '.call' do
    subject { described_class.call(config) }

    context 'when Module#name calls result in exceptions' do
      let(:object_space_modules) { [invalid_class] }

      let(:expected_warning) do
        "Class#name from: #{invalid_class} raised an error: " \
        "RuntimeError. #{Mutest::Env::SEMANTICS_MESSAGE}"
      end

      let(:invalid_class) do
        Class.new do
          def self.name
            fail
          end
        end
      end

      after do
        # Fix Class#name so other specs do not see this one
        class << invalid_class
          undef :name
          def name
          end
        end
      end

      before { expect_warning }

      include_examples 'bootstrap call'
    end

    context 'when requires are configured' do
      let(:config) { super().with(requires: %w[foo bar]) }

      before do
        %w[foo bar].each do |component|
          expect(Kernel).to receive(:require)
            .with(component)
            .and_return(true)
        end
      end

      include_examples 'bootstrap call'
    end

    context 'when includes are configured' do
      let(:config) { super().with(includes: %w[foo bar]) }

      before do
        %w[foo bar].each do |component|
          expect($LOAD_PATH).to receive(:<<)
            .with(component)
            .and_return($LOAD_PATH)
        end
      end

      include_examples 'bootstrap call'
    end

    context 'when Module#name does not return a String or nil' do
      let(:object_space_modules) { [invalid_class] }

      let(:invalid_class) do
        Class.new do
          def self.name
            Object
          end
        end
      end

      let(:expected_warning) do
        "Class#name from: #{invalid_class} " \
        "returned Object. #{Mutest::Env::SEMANTICS_MESSAGE}"
      end

      after do
        # Fix Class#name so other specs do not see this one
        class << invalid_class
          undef :name
          def name
          end
        end
      end

      before { expect_warning }

      include_examples 'bootstrap call'
    end

    context 'when scope matches expression' do
      let(:object_space_modules) { [TestApp::Literal, TestApp::Empty]                               }
      let(:match_expressions)    { object_space_modules.map(&:name).map(&method(:parse_expression)) }

      let(:matcher_config) do
        super().with(match_expressions: match_expressions)
      end

      let(:expected_env) do
        subjects = Mutest::Matcher::Scope.new(TestApp::Literal).call(Fixtures::TEST_ENV)

        super().with(
          matchable_scopes: [
            Mutest::Scope.new(TestApp::Empty,   match_expressions.last),
            Mutest::Scope.new(TestApp::Literal, match_expressions.first)
          ],
          mutations:        subjects.flat_map(&:mutations),
          subjects:         subjects
        )
      end

      include_examples 'bootstrap call'
    end
  end
end
