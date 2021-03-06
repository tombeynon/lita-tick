require "spec_helper"

describe LitaTick::Notifier do
  let(:handler){ double(:handler) }
  let(:redis){ double(:redis) }
  let(:log){ double(:log) }

  let(:users){ {
    '1' => {'tick_id': 1}.to_json,
    '2' => {'tick_id': 2}.to_json
  } }

  subject { LitaTick::Notifier.new(handler, redis, log) }

  describe '#start!' do
    it 'sets a cron schedule' do
      schedule = double(:schedule)
      expect(schedule).to receive(:cron).with('10 17 * * 1-4')
      subject.start!(schedule, '17:10', '1-4')
    end
  end

  describe '#remind!' do
    it 'stores the parameters in redis' do
      user = double(:user, id: 1)
      tick_id = '1'
      expect(redis).to receive(:hset).with('users', 1, {'tick_id' => tick_id}.to_json)
      subject.remind!(user, tick_id)
    end
  end

  describe '#forget!' do
    context 'with stored user data' do
      it 'removes the user data and returns true' do
        user = double(:user, id: 1)
        expect(redis).to receive(:hdel).with('users', user.id){ 1 }
        expect(subject.forget!(user)).to eq(true)
      end
    end

    context 'without stored user data' do
      it 'returns false' do
        user = double(:user, id: 1)
        expect(redis).to receive(:hdel).with('users', user.id){ 0 }
        expect(subject.forget!(user)).to eq(false)
      end
    end
  end

  describe '#stop_until!' do
    it 'stores the stop_until date' do
      date = double(:date)
      expect(redis).to receive(:set).with('stop_until', date)
      subject.stop_until!(date)
    end
  end

  describe '#resume!' do
    it 'deletes the store stop_until date' do
      expect(redis).to receive(:del).with('stop_until')
      subject.resume!
    end
  end

  describe '#list' do
    before do
      allow(redis).to receive(:hgetall).with('users'){ users }
    end
    it 'returns an array containing information about each reminder' do
      expect(subject.list).to eq([{id: '1', tick_id: 1}, {id: '2', tick_id: 2}])
    end
  end

  describe '#stopped?' do
    context 'stop_until in the future' do
      it 'returns true' do
        expect(redis).to receive(:get).with('stop_until'){ (Date.today + 1).to_s }
        expect(subject.stopped?).to eq(true)
      end
    end

    context 'stop_until in the past' do
      it 'returns false' do
        expect(redis).to receive(:get).with('stop_until'){ (Date.today - 1).to_s }
        expect(subject.stopped?).to eq(false)
      end
    end

    context 'stop_until not set' do
      it 'returns false' do
        expect(redis).to receive(:get).with('stop_until')
        expect(subject.stopped?).to eq(false)
      end
    end
  end

  context 'sending' do
    before do
      allow(redis).to receive(:hgetall).with('users'){ users }
    end
    describe '#send' do
      context 'not stopped' do
        it 'notifies the handler to remind the users' do
          expect(redis).to receive(:get).with('stop_until')
          expect(handler).to receive(:remind_user).with('1', 1)
          expect(handler).to receive(:remind_user).with('2', 2)
          subject.send
        end
      end

      context 'stopped' do
        it 'doesn\'t notify the handler' do
          expect(redis).to receive(:get).with('stop_until'){ (Date.today + 1).to_s }
          expect(handler).to_not receive(:remind_user)
          subject.send
        end
      end
    end

    describe '#send!' do
      context 'not stopped' do
        it 'notifies the handler to remind the users' do
          expect(handler).to receive(:remind_user).with('1', 1)
          expect(handler).to receive(:remind_user).with('2', 2)
          subject.send!
        end
      end

      context 'stopped' do
        it 'notifies the handler to remind the users' do
          expect(handler).to receive(:remind_user).with('1', 1)
          expect(handler).to receive(:remind_user).with('2', 2)
          subject.send!
        end
      end
    end
  end
end

