SELECT articles.cached_tag_list,
       articles.crossposted_at,
       articles.path,
       articles.published_at,
       articles.reading_time,
       articles.title,
       articles.user_id,
       reactions.id AS reaction_id,
       reactions.user_id AS reaction_user_id,
       reactions.created_at AS reaction_created_at,
       reactions.status AS reaction_status,
       users.name AS user_name,
       users.profile_image AS user_profile_image,
       users.username AS user_username,
       (to_tsvector('simple'::regconfig, articles.body_markdown) || to_tsvector('simple'::regconfig, articles.cached_tag_list) || to_tsvector('simple'::regconfig, articles.title) || to_tsvector('simple'::regconfig, COALESCE(organizations.name, '')) || to_tsvector('simple'::regconfig, users.name) || to_tsvector('simple'::regconfig, users.username)) AS document
FROM articles
JOIN reactions ON reactions.reactable_id = articles.id
JOIN users ON users.id = articles.user_id
LEFT OUTER JOIN organizations ON organizations.id = articles.organization_id
WHERE reactions.reactable_type = 'Article';
