RSpec.describe Mutest::Mutation do
  let(:mutation_class) do
    Class.new(Mutest::Mutation) do
      const_set(:SYMBOL, 'test'.freeze)
      const_set(:TEST_PASS_SUCCESS, true)
    end
  end

  let(:context) { instance_double(Mutest::Context) }

  let(:object) do
    mutation_class.new(mutation_subject, Mutest::AST::Nodes::N_NIL)
  end

  let(:mutation_subject) do
    instance_double(
      Mutest::Subject,
      identification: 'subject',
      context:        context,
      source:         'original'
    )
  end

  describe '#insert' do
    subject { object.insert(kernel) }

    let(:root_node) { s(:foo)                 }
    let(:kernel)    { instance_double(Kernel) }

    before do
      expect(context).to receive(:root)
        .with(object.node)
        .and_return(root_node)

      expect(mutation_subject).to receive(:prepare)
        .ordered
        .and_return(mutation_subject)

      expect(Mutest::Loader).to receive(:call)
        .ordered
        .with(
          binding: TOPLEVEL_BINDING,
          kernel:  kernel,
          node:    root_node,
          subject: mutation_subject
        )
        .and_return(Mutest::Loader)
    end

    it_behaves_like 'a command method'
  end

  describe '#code' do
    subject { object.code }

    it { is_expected.to eql('8771a') }

    it_behaves_like 'an idempotent method'
  end

  describe '#original_source' do
    subject { object.original_source }

    it { is_expected.to eql('original') }

    it_behaves_like 'an idempotent method'
  end

  describe '#source' do
    subject { object.source }

    it { is_expected.to eql('nil') }

    it_behaves_like 'an idempotent method'
  end

  describe '.success?' do
    subject { mutation_class.success?(test_result) }

    let(:test_result) do
      instance_double(
        Mutest::Result::Test,
        passed: passed
      )
    end

    context 'on mutation with positive pass expectation' do
      context 'when Result::Test#passed equals expectation' do
        let(:passed) { true }

        it { is_expected.to be(true) }
      end

      context 'when Result::Test#passed NOT equals expectation' do
        let(:passed) { false }

        it { is_expected.to be(false) }
      end
    end

    context 'on mutation with negative pass expectation' do
      let(:mutation_class) do
        Class.new(super()) do
          const_set(:TEST_PASS_SUCCESS, false)
        end
      end

      context 'when Result::Test#passed equals expectation' do
        let(:passed) { true }

        it { is_expected.to be(false) }
      end

      context 'when Result::Test#passed NOT equals expectation' do
        let(:passed) { false }

        it { is_expected.to be(true) }
      end
    end
  end

  describe '#identification' do
    subject { object.identification }

    it { is_expected.to eql('test:subject:8771a') }

    it_behaves_like 'an idempotent method'
  end
end
