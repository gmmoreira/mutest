RSpec.describe Mutest::Parallel::Source::Array do
  let(:object) { described_class.new(jobs) }

  let(:job_a) { instance_double(Mutest::Parallel::Job) }
  let(:job_b) { instance_double(Mutest::Parallel::Job) }
  let(:job_c) { instance_double(Mutest::Parallel::Job) }

  let(:jobs) { [job_a, job_b, job_c] }

  describe '#next' do
    subject { object.next }

    context 'when there is a next job' do
      it 'returns that job' do
        is_expected.to be(job_a)
      end

      it 'does not return the same job twice' do
        expect(object.next).to be(job_a)
        expect(object.next).to be(job_b)
        expect(object.next).to be(job_c)
      end
    end

    context 'when there is no next job' do
      let(:jobs) { [] }

      it 'raises error' do
        expect { subject }.to raise_error(Mutest::Parallel::Source::NoJobError)
      end
    end
  end

  describe '#next?' do
    subject { object.next? }

    context 'when there is a next job' do
      it { is_expected.to be(true) }
    end

    context 'when there is no next job' do
      let(:jobs) { [] }

      it { is_expected.to be(false) }
    end
  end
end
