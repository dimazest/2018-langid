\set ascii_lowercase abcdefghijklmnopqrstuvwxyz
\set lv_special āčēģīķļņšūž
\set ru_special абвгдеёжзийклмнопрстуфхцчшщъыьэюя

drop table if exists _multi_character_set_tweets;

with tweet_letters as (
    select
    *,
    string_to_array(
        lower(
            array_to_string(array(select jsonb_array_elements_text(features#>'{tokenizer,tokens_without_entities}')), '')
        ),
        NULL
    ) letters,
    features#>>'{filter,is_retweet}' = 'true' is_retweet,
    regexp_replace(features#>>'{filter,source}', E'<[^>]+>', '', 'gi') source_pretty,
    regexp_replace(text, E'[\\n\\r]+', ' ', 'g') clean_text
    from tweet
),
letters_by_category as (
    select
    *,
    letters && string_to_array(:'ascii_lowercase', NULL) has_ascii,
    letters && string_to_array(:'lv_special', NULL) has_lv_special,
    letters && string_to_array(:'ru_special', NULL) has_ru
    from tweet_letters
)
select *
into temporary _multi_character_set_tweets
from letters_by_category
where
collection = 'lv2'
and has_lv_special and has_ru
order by created_at asc;

\copy (select tweet_id, clean_text from _multi_character_set_tweets ) to 'multi_character_set_tweets.csv' with csv header

drop table if exists _twitter_clients_tweets;
select tweet_id, clean_text
into _twitter_clients_tweets
from _multi_character_set_tweets
where not is_retweet and source_pretty like 'Twitter %'
order by tweet_id % 197, tweet_id % 9973, created_at
;

\copy (select * from _twitter_clients_tweets) to 'twitter_clients_tweets.csv' with csv header

drop table if exists _not_twitter_clients_tweets;
select tweet_id, clean_text
into _not_twitter_clients_tweets
from _multi_character_set_tweets
where not is_retweet and source_pretty not like 'Twitter %'
order by tweet_id % 197, tweet_id % 9973, created_at
;

\copy (select * from _not_twitter_clients_tweets) to 'not_twitter_clients_tweets.csv' with csv header

drop table if exists _not_twitter_clients_not_insta_not_fq_tweets;
select tweet_id, clean_text
into _not_twitter_clients_not_insta_not_fq_tweets
from _multi_character_set_tweets
where
not is_retweet
and source_pretty not like 'Twitter %'
and source_pretty <> 'Instagram'
and source_pretty <> 'Foursquare'
order by tweet_id % 197, tweet_id % 9973, created_at
;

\copy (select * from _not_twitter_clients_not_insta_not_fq_tweets) to 'not_twitter_clients_not_insta_not_fq_tweets.csv' with csv header
