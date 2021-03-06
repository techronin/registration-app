require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::SanitizeHelper

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  def setup
    # Is there a sane way to check to see if the URL provided is right without
    # typing the whole email in HTML?
    Game.instance.generate_completion_certs false
    @inv_email_body = strip_tags("Hello #{user_invites(:invite_one).email}! You have been
                   invited to join the team #{user_invites(:invite_one).team.team_name}
                   for the upcoming MITRE CTF Click the link below to register
                   an account in order to accept the invitation. #{link_to '
                   Create my account', new_user_registration_url(:email => user_invites(:invite_one).email)}").squish
    @reg_email_body = strip_tags("Hello #{user_requests(:request_one).team.team_captain.email}!
                   #{user_requests(:request_one).user.full_name}
                   has requested to join your team #{user_requests(:request_one).team.team_name}
                   Click the link below to view and accept or reject the request.
                   #{link_to 'View Team Dashboard', team_url(user_requests(:request_one).team)}").squish
    @remind_email_body = strip_tags("Hello #{users(:user_one).full_name}! This is a reminder for the
                   upcoming MITRE CTF which will start at #{games(:mitre_ctf_game).start}.
                   Click the link below to login and check your account #{link_to 'MITRE CTF', home_index_url}.").squish
    @rank_email_body = strip_tags("Hello #{users(:user_one).full_name}! Congratulations on completing the MITRE CTF!
                   Your team, #{users(:user_one).team.team_name} came ranked #{(1 + (divisions(:high_school).ordered_teams.index users(:user_one).team)).ordinalize}.").squish
  end

  test 'invite' do
    email = UserMailer.invite_user(user_invites(:invite_one)).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    assert_equal ['do-not-reply@mitrecyberacademy.org'], email.from
    assert_equal ['mitrectf+user2@gmail.com'], email.to
    assert_equal "MITRE CTF: Invite to join team #{user_invites(:invite_one).team.team_name}", email.subject
    assert_equal @inv_email_body, strip_tags(email.body.to_s).squish
  end

  test 'invite contains correct url' do
  end

  test 'request' do
    email = UserMailer.user_request(user_requests(:request_one)).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    assert_equal ['do-not-reply@mitrecyberacademy.org'], email.from
    assert_equal ['mitrectf+user1test@gmail.com'], email.to
    assert_equal "MITRE CTF: Request from #{user_requests(:request_one).user.full_name} to join #{user_requests(:request_one).team.team_name}", email.subject
    assert_equal @reg_email_body, strip_tags(email.body.to_s).squish
  end

  test 'reminder' do
    email = UserMailer.competition_reminder(users(:user_one)).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    assert_equal ['do-not-reply@mitrecyberacademy.org'], email.from
    assert_equal ['mitrectf+user1test@gmail.com'], email.to
    assert_equal 'MITRE CTF: Competition Reminder', email.subject
    assert_equal @remind_email_body, strip_tags(email.body.to_s).squish
  end

  test 'ranking' do
    user = users(:user_one)
    email = UserMailer.ranking(user, 1 + (divisions(:high_school).ordered_teams.index users(:user_one).team),
                               Rails.root.join( 'tmp', 'high_school-certificates', 'team_one', 'user_one.pdf')).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    assert_equal ['do-not-reply@mitrecyberacademy.org'], email.from
    assert_equal ['mitrectf+user1test@gmail.com'], email.to
    assert_equal 'MITRE CTF: Congratulations!', email.subject
    assert_equal true, email.has_attachments?
    assert_includes (strip_tags(email.body.parts.first.to_s).squish.to_s), @rank_email_body
  end
end
