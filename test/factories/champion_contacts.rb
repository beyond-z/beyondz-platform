FactoryGirl.define do
  factory :champion_contact do
    user_id ""
champion_id ""
champion_replied false
fellow_get_to_talk_to_champion false
why_not_talk_to_champion "MyText"
would_fellow_recommend_champion 1
what_did_champion_do_well "MyText"
what_could_champion_improve "MyText"
reminder_requested false
fellow_survey_answered_at "2017-09-12 11:24:43"
inappropriate_champion_interaction "MyText"
inappropriate_fellow_interaction "MyText"
champion_get_to_talk_to_champion false
why_not_talk_to_fellow "MyText"
how_champion_felt_conversaion_went 1
what_did_fellow_do_well "MyText"
what_could_fellow_improve "MyText"
champion_comments "MyText"
champion_survey_answered_at "2017-09-12 11:24:43"
fellow_comments "MyText"
  end

end
