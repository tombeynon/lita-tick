require "spec_helper"

describe Lita::Handlers::Tick, lita_handler: true do
  it { is_expected.to route_command('remind me to tick user@email.com').to(:add_reminder) }
  it { is_expected.to route_command('stop reminding me to tick').to(:remove_reminder) }
  it { is_expected.to route_command('send tick reminders').to(:send_reminders).with_authorization_for(:tick_admins) }
  it { is_expected.to route_command('list tick reminders').to(:list_reminders).with_authorization_for(:tick_admins) }
  it { is_expected.to route_command('stop tick reminders until 1/2/2016').to(:stop_reminders).with_authorization_for(:tick_admins) }
  it { is_expected.to route_command('resume tick reminders').to(:resume_reminders).with_authorization_for(:tick_admins) }

  let(:notifier){ double(:notifier) }
  let(:scheduler){ double(:scheduler) }
  let!(:user){ Lita::User.create(123, name: "Test") }

  before do
    robot.config.handlers.tick.api_token = 'API-TOKEN'
    robot.config.handlers.tick.api_contact = 'API-CONTACT'
    robot.config.handlers.tick.subscription_id = 'SUBSCRIPTION-ID'
    allow_any_instance_of(Lita::Handlers::Tick).to receive(:notifier).and_return(notifier)
    allow(Lita::Handlers::Tick).to receive(:scheduler).and_return(scheduler)
  end

  describe '#start_notifier' do
    it 'configures Tick and starts the notifier' do
      expect(Tick).to receive(:api_token=).with('API-TOKEN')
      expect(Tick).to receive(:api_contact=).with('API-CONTACT')
      expect(Tick).to receive(:subscription_id=).with('SUBSCRIPTION-ID')
      expect(notifier).to receive(:start!).with(scheduler, '17:20', '1-5', nil)
      subject.start_notifier({})
    end
  end

  describe '#add_reminder' do
    context 'with a valid tick email' do
      let(:tick_user){ double(:tick_user, id: '1') }

      it 'sets the reminder and confirms' do
        expect(LitaTick::User).to receive(:find_by_email).with('test@email.com'){ tick_user }
        expect(notifier).to receive(:remind!).with(user, tick_user.id)
        send_command("remind me to tick test@email.com", as: user)
        expect(replies.last).to eq("All set")
      end
    end

    context 'with an invalid tick email' do
      it 'sets the reminder and confirms' do
        expect(LitaTick::User).to receive(:find_by_email).with('test@email.com')
        send_command("remind me to tick test@email.com", as: user)
        expect(replies.last).to eq("I couldn't find that user")
      end
    end
  end

  describe '#remove_reminder' do
    context 'with a reminder set' do
      it 'removes the reminder and confirms' do
        expect(notifier).to receive(:forget!).with(user).and_return(true)
        send_command("stop reminding me to tick", as: user)
        expect(replies.last).to eq("All done. I was only trying to help")
      end
    end

    context 'without a reminder set' do
      it 'gives sass' do
        expect(notifier).to receive(:forget!).with(user).and_return(false)
        send_command("stop reminding me to tick", as: user)
        expect(replies.last).to eq("Chill, you didn't ask me to remind you")
      end
    end
  end

  context 'tick_admins' do
    before do
      robot.auth.add_user_to_group!(user, :tick_admins)
    end

    describe '#send_reminders' do
      it 'sends the reminders and confirms' do
        expect(notifier).to receive(:send!)
        send_command("send tick reminders", as: user)
        expect(replies.last).to eq("Tick reminders sent")
      end
    end

    describe '#list_reminders' do
      before do
        Lita::User.create(1, name: "Test 1")
        Lita::User.create(2, name: "Test 2")
        allow(LitaTick::User).to receive(:find).with(11){ double(email: 'tick_1@email.com') }
        allow(LitaTick::User).to receive(:find).with(22){ double(email: 'tick_2@email.com') }
      end

      it 'lists the reminders' do
        expect(notifier).to receive(:list){ [{id: 1, tick_id: 11}, {id: 2, tick_id: 22}] }
        send_command("list tick reminders", as: user)
        expect(replies.last).to eq("Test 1: tick_1@email.com\nTest 2: tick_2@email.com")
      end
    end

    describe '#stop_reminders' do
      it 'stops the reminders and confirms' do
        date = Date.new(2001,1,1)
        expect(Date).to receive(:new).with(2001, 1, 1){ date }
        expect(notifier).to receive(:stop_until!).with(date)
        send_command("stop tick reminders until 1/1/2001", as: user)
        expect(replies.last).to eq("Tick reminders stopped until 2001-01-01")
      end
    end

    describe '#resume_reminders' do
      it 'resumes the reminders and confirms' do
        expect(notifier).to receive(:resume!)
        send_command("resume tick reminders", as: user)
        expect(replies.last).to eq("Tick reminders resumed")
      end
    end
  end

  describe '#remind_user' do
    context 'valid tick user' do
      context 'needs reminding' do
        let(:tick_user){ double(:tick_user, id: '1', hours_posted_today: 4.0) }

        it 'reminds the user' do
          expect(LitaTick::User).to receive(:find).with('1'){ tick_user }
          subject.remind_user(123, '1')
          expect(replies.last).to eq("Don't forget to tick! You've entered 4.0 hours for today")
        end
      end

      context 'doesn\'t need reminding' do
        let(:tick_user){ double(:tick_user, id: '1', hours_posted_today: 6.0) }

        it 'doesn\'t send a message' do
          expect(LitaTick::User).to receive(:find).with('1'){ tick_user }
          subject.remind_user(123, '1')
          expect(replies.last).to be_nil
        end
      end
    end

    context 'invalid tick user' do
      it 'reminds the user' do
        expect(LitaTick::User).to receive(:find).with('1'){ nil }
        subject.remind_user(123, '1')
        expect(replies.last).to eq("I couldn't access your tick account..")
      end
    end
  end
end
