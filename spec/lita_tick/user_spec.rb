require "spec_helper"

describe LitaTick::User do
  let(:user){ double(:user, id: 1) }
  let(:entries){ [
    double(:entry, hours: 2.0),
    double(:entry, hours: 1.0)
  ] }
  subject{ LitaTick::User.new(user) }

  before do
    allow(Tick::Entry).to receive(:where).with({
      user_id: 1,
      start_date: Date.today,
      end_date: Date.today
    }).and_return(entries)
  end

  describe '#needs_reminding?' do
    context 'does need reminding' do
      it 'returns true' do
        expect(subject.needs_reminding?).to eq(true)
      end
    end

    context 'doesn\'t need reminding' do
      it 'returns false' do
        entries << double(:entry, hours: 3.0)
        expect(subject.needs_reminding?).to eq(false)
      end
    end
  end

  describe '#hours_posted_today' do
    it 'returns the sum of the entry hours' do
      expect(subject.hours_posted_today).to eq(3.0)
    end
  end

  describe '#entries_for_today' do
    it 'returns the entries' do
      expect(subject.entries_for_today).to eq(entries)
    end
  end

  describe '.find' do
    let(:users){[
      double(:user, id: 1),
      double(:user, id: 2)
    ]}
    before do
      allow(Tick::User).to receive(:all){ users }
    end
    context 'with a valid id' do
      it 'returns the user' do
        result = double(:result)
        expect(LitaTick::User).to receive(:new).with(users.first){ result }
        expect(LitaTick::User.find(1)).to eq(result)
      end
    end

    context 'without a valid id' do
      it 'returns nil' do
        expect(LitaTick::User).to_not receive(:new)
        expect(LitaTick::User.find(99)).to be_nil
      end
    end
  end

  describe '.find_by_email' do
    let(:users){[
      double(:user, email: 'test1@test.com'),
      double(:user, email: 'test2@test.com')
    ]}
    before do
      allow(Tick::User).to receive(:all){ users }
    end
    context 'with a valid email' do
      it 'returns the user' do
        result = double(:result)
        expect(LitaTick::User).to receive(:new).with(users.first){ result }
        expect(LitaTick::User.find_by_email('test1@test.com')).to eq(result)
      end
    end

    context 'without a valid email' do
      it 'returns nil' do
        expect(LitaTick::User).to_not receive(:new)
        expect(LitaTick::User.find_by_email('test99@test.com')).to be_nil
      end
    end
  end
end


