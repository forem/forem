SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ahoy_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ahoy_events (
    id bigint NOT NULL,
    name character varying,
    properties jsonb,
    "time" timestamp without time zone,
    user_id bigint,
    visit_id bigint
);


--
-- Name: ahoy_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ahoy_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ahoy_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ahoy_events_id_seq OWNED BY public.ahoy_events.id;


--
-- Name: ahoy_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ahoy_messages (
    id bigint NOT NULL,
    clicked_at timestamp without time zone,
    content text,
    feedback_message_id bigint,
    mailer character varying,
    opened_at timestamp without time zone,
    sent_at timestamp without time zone,
    subject text,
    "to" text,
    token character varying,
    user_id bigint,
    user_type character varying,
    utm_campaign character varying,
    utm_content character varying,
    utm_medium character varying,
    utm_source character varying,
    utm_term character varying
);


--
-- Name: ahoy_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ahoy_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ahoy_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ahoy_messages_id_seq OWNED BY public.ahoy_messages.id;


--
-- Name: ahoy_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ahoy_visits (
    id bigint NOT NULL,
    started_at timestamp without time zone,
    user_id bigint,
    visit_token character varying,
    visitor_token character varying
);


--
-- Name: ahoy_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ahoy_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ahoy_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ahoy_visits_id_seq OWNED BY public.ahoy_visits.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id bigint NOT NULL,
    banner_style character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: api_secrets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_secrets (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    description character varying NOT NULL,
    secret character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: api_secrets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_secrets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_secrets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_secrets_id_seq OWNED BY public.api_secrets.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.articles (
    id bigint NOT NULL,
    any_comments_hidden boolean DEFAULT false,
    approved boolean DEFAULT false,
    archived boolean DEFAULT false,
    body_html text,
    body_markdown text,
    boost_states jsonb DEFAULT '{}'::jsonb NOT NULL,
    cached_organization text,
    cached_tag_list character varying,
    cached_user text,
    cached_user_name character varying,
    cached_user_username character varying,
    canonical_url character varying,
    co_author_ids bigint[] DEFAULT '{}'::bigint[],
    collection_id bigint,
    comment_score integer DEFAULT 0,
    comment_template character varying,
    comments_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    crossposted_at timestamp without time zone,
    description character varying,
    edited_at timestamp without time zone,
    email_digest_eligible boolean DEFAULT true,
    experience_level_rating double precision DEFAULT 5.0,
    experience_level_rating_distribution double precision DEFAULT 5.0,
    featured boolean DEFAULT false,
    featured_number integer,
    feed_source_url character varying,
    hotness_score integer DEFAULT 0,
    last_comment_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    last_experience_level_rating_at timestamp without time zone,
    main_image character varying,
    main_image_background_hex_color character varying DEFAULT '#dddddd'::character varying,
    nth_published_by_author integer DEFAULT 0,
    organic_page_views_count integer DEFAULT 0,
    organic_page_views_past_month_count integer DEFAULT 0,
    organic_page_views_past_week_count integer DEFAULT 0,
    organization_id bigint,
    originally_published_at timestamp without time zone,
    page_views_count integer DEFAULT 0,
    password character varying,
    path character varying,
    positive_reactions_count integer DEFAULT 0 NOT NULL,
    previous_positive_reactions_count integer DEFAULT 0,
    previous_public_reactions_count integer DEFAULT 0 NOT NULL,
    processed_html text,
    public_reactions_count integer DEFAULT 0 NOT NULL,
    published boolean DEFAULT false,
    published_at timestamp without time zone,
    published_from_feed boolean DEFAULT false,
    rating_votes_count integer DEFAULT 0 NOT NULL,
    reactions_count integer DEFAULT 0 NOT NULL,
    reading_time integer DEFAULT 0,
    receive_notifications boolean DEFAULT true,
    score integer DEFAULT 0,
    search_optimized_description_replacement character varying,
    search_optimized_title_preamble character varying,
    show_comments boolean DEFAULT true,
    slug text,
    social_image character varying,
    spaminess_rating integer DEFAULT 0,
    title character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint,
    user_subscriptions_count integer DEFAULT 0 NOT NULL,
    video character varying,
    video_closed_caption_track_url character varying,
    video_code character varying,
    video_duration_in_seconds double precision DEFAULT 0.0,
    video_source_url character varying,
    video_state character varying,
    video_thumbnail_url character varying,
    tsv tsvector
);


--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.articles_id_seq OWNED BY public.articles.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    category character varying,
    created_at timestamp without time zone NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    roles character varying[],
    slug character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: badge_achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_achievements (
    id bigint NOT NULL,
    badge_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    rewarder_id bigint,
    rewarding_context_message text,
    rewarding_context_message_markdown text,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: badge_achievements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_achievements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_achievements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_achievements_id_seq OWNED BY public.badge_achievements.id;


--
-- Name: badges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badges (
    id bigint NOT NULL,
    badge_image character varying,
    created_at timestamp without time zone NOT NULL,
    description character varying NOT NULL,
    slug character varying NOT NULL,
    title character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    credits_awarded integer DEFAULT 0 NOT NULL
);


--
-- Name: badges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badges_id_seq OWNED BY public.badges.id;


--
-- Name: banished_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.banished_users (
    id bigint NOT NULL,
    banished_by_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    username character varying
);


--
-- Name: banished_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.banished_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: banished_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.banished_users_id_seq OWNED BY public.banished_users.id;


--
-- Name: blazer_audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_audits (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    data_source character varying,
    query_id bigint,
    statement text,
    user_id bigint
);


--
-- Name: blazer_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_audits_id_seq OWNED BY public.blazer_audits.id;


--
-- Name: blazer_checks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_checks (
    id bigint NOT NULL,
    check_type character varying,
    created_at timestamp without time zone NOT NULL,
    creator_id bigint,
    emails text,
    last_run_at timestamp without time zone,
    message text,
    query_id bigint,
    schedule character varying,
    slack_channels text,
    state character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blazer_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_checks_id_seq OWNED BY public.blazer_checks.id;


--
-- Name: blazer_dashboard_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_dashboard_queries (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    dashboard_id bigint,
    "position" integer,
    query_id bigint,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blazer_dashboard_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_dashboard_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_dashboard_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_dashboard_queries_id_seq OWNED BY public.blazer_dashboard_queries.id;


--
-- Name: blazer_dashboards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_dashboards (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    creator_id bigint,
    name text,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blazer_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_dashboards_id_seq OWNED BY public.blazer_dashboards.id;


--
-- Name: blazer_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_queries (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    creator_id bigint,
    data_source character varying,
    description text,
    name character varying,
    statement text,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blazer_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_queries_id_seq OWNED BY public.blazer_queries.id;


--
-- Name: broadcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.broadcasts (
    id bigint NOT NULL,
    active boolean DEFAULT false,
    active_status_updated_at timestamp without time zone,
    banner_style character varying,
    body_markdown text,
    broadcastable_id bigint,
    broadcastable_type character varying,
    created_at timestamp without time zone,
    processed_html text,
    title character varying,
    type_of character varying,
    updated_at timestamp without time zone
);


--
-- Name: broadcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.broadcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: broadcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.broadcasts_id_seq OWNED BY public.broadcasts.id;


--
-- Name: chat_channel_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_channel_memberships (
    id bigint NOT NULL,
    chat_channel_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    has_unopened_messages boolean DEFAULT false,
    last_opened_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    role character varying DEFAULT 'member'::character varying,
    show_global_badge_notification boolean DEFAULT true,
    status character varying DEFAULT 'active'::character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: chat_channel_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_channel_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_channel_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_channel_memberships_id_seq OWNED BY public.chat_channel_memberships.id;


--
-- Name: chat_channels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_channels (
    id bigint NOT NULL,
    channel_name character varying,
    channel_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    description character varying,
    discoverable boolean DEFAULT false,
    last_message_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    slug character varying,
    status character varying DEFAULT 'active'::character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: chat_channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_channels_id_seq OWNED BY public.chat_channels.id;


--
-- Name: classified_listing_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classified_listing_categories (
    id bigint NOT NULL,
    cost integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    rules character varying NOT NULL,
    slug character varying NOT NULL,
    social_preview_color character varying,
    social_preview_description character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: classified_listing_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.classified_listing_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classified_listing_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.classified_listing_categories_id_seq OWNED BY public.classified_listing_categories.id;


--
-- Name: classified_listings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classified_listings (
    id bigint NOT NULL,
    body_markdown text,
    bumped_at timestamp without time zone,
    cached_tag_list character varying,
    classified_listing_category_id bigint,
    contact_via_connect boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone,
    location character varying,
    organization_id bigint,
    originally_published_at timestamp without time zone,
    processed_html text,
    published boolean,
    slug character varying,
    title character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: classified_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.classified_listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classified_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.classified_listings_id_seq OWNED BY public.classified_listings.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    description character varying,
    main_image character varying,
    organization_id bigint,
    published boolean DEFAULT false,
    slug character varying,
    social_image character varying,
    title character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collections_id_seq OWNED BY public.collections.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    ancestry character varying,
    body_html text,
    body_markdown text,
    commentable_id bigint,
    commentable_type character varying,
    created_at timestamp without time zone NOT NULL,
    deleted boolean DEFAULT false,
    edited boolean DEFAULT false,
    edited_at timestamp without time zone,
    hidden_by_commentable_user boolean DEFAULT false,
    id_code character varying,
    markdown_character_count integer,
    positive_reactions_count integer DEFAULT 0 NOT NULL,
    processed_html text,
    public_reactions_count integer DEFAULT 0 NOT NULL,
    reactions_count integer DEFAULT 0 NOT NULL,
    receive_notifications boolean DEFAULT true,
    score integer DEFAULT 0,
    spaminess_rating integer DEFAULT 0,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credits (
    id bigint NOT NULL,
    cost double precision DEFAULT 0.0,
    created_at timestamp without time zone NOT NULL,
    organization_id bigint,
    purchase_id bigint,
    purchase_type character varying,
    spent boolean DEFAULT false,
    spent_at timestamp without time zone,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: credits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.credits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.credits_id_seq OWNED BY public.credits.id;


--
-- Name: custom_profile_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_profile_fields (
    id bigint NOT NULL,
    attribute_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description character varying,
    label public.citext NOT NULL,
    profile_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: custom_profile_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_profile_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_profile_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_profile_fields_id_seq OWNED BY public.custom_profile_fields.id;


--
-- Name: data_update_scripts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_update_scripts (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    error text,
    file_name character varying,
    finished_at timestamp without time zone,
    run_at timestamp without time zone,
    status integer DEFAULT 0 NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: data_update_scripts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_update_scripts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_update_scripts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_update_scripts_id_seq OWNED BY public.data_update_scripts.id;


--
-- Name: devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devices (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    platform character varying NOT NULL,
    app_bundle character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.devices_id_seq OWNED BY public.devices.id;


--
-- Name: display_ad_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.display_ad_events (
    id bigint NOT NULL,
    category character varying,
    context_type character varying,
    created_at timestamp without time zone NOT NULL,
    display_ad_id bigint,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: display_ad_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.display_ad_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: display_ad_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.display_ad_events_id_seq OWNED BY public.display_ad_events.id;


--
-- Name: display_ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.display_ads (
    id bigint NOT NULL,
    approved boolean DEFAULT false,
    body_markdown text,
    clicks_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    impressions_count integer DEFAULT 0,
    organization_id bigint,
    placement_area character varying,
    processed_html text,
    published boolean DEFAULT false,
    success_rate double precision DEFAULT 0.0,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: display_ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.display_ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: display_ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.display_ads_id_seq OWNED BY public.display_ads.id;


--
-- Name: email_authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_authorizations (
    id bigint NOT NULL,
    confirmation_token character varying,
    created_at timestamp without time zone NOT NULL,
    json_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    type_of character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint,
    verified_at timestamp without time zone
);


--
-- Name: email_authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_authorizations_id_seq OWNED BY public.email_authorizations.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    category character varying,
    cover_image character varying,
    created_at timestamp without time zone NOT NULL,
    description_html text,
    description_markdown text,
    ends_at timestamp without time zone,
    host_name character varying,
    live_now boolean DEFAULT false,
    location_name character varying,
    location_url character varying,
    profile_image character varying,
    published boolean,
    slug character varying,
    starts_at timestamp without time zone,
    title character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: feedback_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_messages (
    id bigint NOT NULL,
    affected_id bigint,
    category character varying,
    created_at timestamp without time zone,
    feedback_type character varying,
    message text,
    offender_id bigint,
    reported_url character varying,
    reporter_id bigint,
    status character varying DEFAULT 'Open'::character varying,
    updated_at timestamp without time zone
);


--
-- Name: feedback_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_messages_id_seq OWNED BY public.feedback_messages.id;


--
-- Name: field_test_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.field_test_events (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    field_test_membership_id bigint,
    name character varying
);


--
-- Name: field_test_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.field_test_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: field_test_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.field_test_events_id_seq OWNED BY public.field_test_events.id;


--
-- Name: field_test_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.field_test_memberships (
    id bigint NOT NULL,
    converted boolean DEFAULT false,
    created_at timestamp without time zone,
    experiment character varying,
    participant_id character varying,
    participant_type character varying,
    variant character varying
);


--
-- Name: field_test_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.field_test_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: field_test_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.field_test_memberships_id_seq OWNED BY public.field_test_memberships.id;


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    key character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    value character varying
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follows (
    id bigint NOT NULL,
    blocked boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    explicit_points double precision DEFAULT 1.0,
    followable_id bigint NOT NULL,
    followable_type character varying NOT NULL,
    follower_id bigint NOT NULL,
    follower_type character varying NOT NULL,
    implicit_points double precision DEFAULT 0.0,
    points double precision DEFAULT 1.0,
    subscription_status character varying DEFAULT 'all_articles'::character varying NOT NULL,
    updated_at timestamp without time zone
);


--
-- Name: follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follows_id_seq OWNED BY public.follows.id;


--
-- Name: github_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.github_issues (
    id bigint NOT NULL,
    category character varying,
    created_at timestamp without time zone NOT NULL,
    issue_serialized character varying DEFAULT '--- {}
'::character varying,
    processed_html character varying,
    updated_at timestamp without time zone NOT NULL,
    url character varying
);


--
-- Name: github_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.github_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: github_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.github_issues_id_seq OWNED BY public.github_issues.id;


--
-- Name: github_repos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.github_repos (
    id bigint NOT NULL,
    additional_note character varying,
    bytes_size integer,
    created_at timestamp without time zone NOT NULL,
    description character varying,
    featured boolean DEFAULT false,
    fork boolean DEFAULT false,
    github_id_code bigint,
    info_hash text DEFAULT '--- {}
'::text,
    language character varying,
    name character varying,
    priority integer DEFAULT 0,
    stargazers_count integer,
    updated_at timestamp without time zone NOT NULL,
    url character varying,
    user_id bigint,
    watchers_count integer
);


--
-- Name: github_repos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.github_repos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: github_repos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.github_repos_id_seq OWNED BY public.github_repos.id;


--
-- Name: html_variant_successes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.html_variant_successes (
    id bigint NOT NULL,
    article_id bigint,
    created_at timestamp without time zone NOT NULL,
    html_variant_id bigint,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: html_variant_successes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.html_variant_successes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: html_variant_successes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.html_variant_successes_id_seq OWNED BY public.html_variant_successes.id;


--
-- Name: html_variant_trials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.html_variant_trials (
    id bigint NOT NULL,
    article_id bigint,
    created_at timestamp without time zone NOT NULL,
    html_variant_id bigint,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: html_variant_trials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.html_variant_trials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: html_variant_trials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.html_variant_trials_id_seq OWNED BY public.html_variant_trials.id;


--
-- Name: html_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.html_variants (
    id bigint NOT NULL,
    approved boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    "group" character varying,
    html text,
    name character varying,
    published boolean DEFAULT false,
    success_rate double precision DEFAULT 0.0,
    target_tag character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: html_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.html_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: html_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.html_variants_id_seq OWNED BY public.html_variants.id;


--
-- Name: identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identities (
    id bigint NOT NULL,
    auth_data_dump text,
    created_at timestamp without time zone NOT NULL,
    provider character varying,
    secret character varying,
    token character varying,
    uid character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.identities_id_seq OWNED BY public.identities.id;


--
-- Name: mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mentions (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    mentionable_id bigint,
    mentionable_type character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: mentions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mentions_id_seq OWNED BY public.mentions.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    chat_action character varying,
    chat_channel_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    edited_at timestamp without time zone,
    message_html character varying NOT NULL,
    message_markdown character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: navigation_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.navigation_links (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    display_only_when_signed_in boolean DEFAULT false,
    icon character varying NOT NULL,
    name character varying NOT NULL,
    "position" integer,
    updated_at timestamp(6) without time zone NOT NULL,
    url character varying NOT NULL
);


--
-- Name: navigation_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.navigation_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: navigation_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.navigation_links_id_seq OWNED BY public.navigation_links.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    author_id bigint,
    content text,
    created_at timestamp without time zone NOT NULL,
    noteable_id bigint,
    noteable_type character varying,
    reason character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: notification_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_subscriptions (
    id bigint NOT NULL,
    config text DEFAULT 'all_comments'::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    notifiable_id bigint NOT NULL,
    notifiable_type character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: notification_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_subscriptions_id_seq OWNED BY public.notification_subscriptions.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    action character varying,
    created_at timestamp without time zone NOT NULL,
    json_data jsonb,
    notifiable_id bigint,
    notifiable_type character varying,
    notified_at timestamp without time zone,
    organization_id bigint,
    read boolean DEFAULT false,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    id bigint NOT NULL,
    application_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    resource_owner_id bigint NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying,
    token character varying NOT NULL
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id bigint NOT NULL,
    application_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    expires_in integer,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL,
    refresh_token character varying,
    resource_owner_id bigint,
    revoked_at timestamp without time zone,
    scopes character varying,
    token character varying NOT NULL
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    id bigint NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    secret character varying NOT NULL,
    uid character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;


--
-- Name: organization_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_memberships (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    organization_id bigint NOT NULL,
    type_of_user character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL,
    user_title character varying
);


--
-- Name: organization_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organization_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organization_memberships_id_seq OWNED BY public.organization_memberships.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id bigint NOT NULL,
    articles_count integer DEFAULT 0 NOT NULL,
    bg_color_hex character varying,
    company_size character varying,
    created_at timestamp without time zone NOT NULL,
    credits_count integer DEFAULT 0 NOT NULL,
    cta_body_markdown text,
    cta_button_text character varying,
    cta_button_url character varying,
    cta_processed_html text,
    dark_nav_image character varying,
    email character varying,
    github_username character varying,
    last_article_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    latest_article_updated_at timestamp without time zone,
    location character varying,
    name character varying,
    nav_image character varying,
    old_old_slug character varying,
    old_slug character varying,
    profile_image character varying,
    profile_updated_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    proof text,
    secret character varying,
    slug character varying,
    spent_credits_count integer DEFAULT 0 NOT NULL,
    story character varying,
    summary text,
    tag_line character varying,
    tech_stack character varying,
    text_color_hex character varying,
    twitter_username character varying,
    unspent_credits_count integer DEFAULT 0 NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    url character varying
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizations_id_seq OWNED BY public.organizations.id;


--
-- Name: page_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_views (
    id bigint NOT NULL,
    article_id bigint,
    counts_for_number_of_views integer DEFAULT 1,
    created_at timestamp without time zone NOT NULL,
    domain character varying,
    path character varying,
    referrer character varying,
    time_tracked_in_seconds integer DEFAULT 15,
    updated_at timestamp without time zone NOT NULL,
    user_agent character varying,
    user_id bigint
);


--
-- Name: page_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.page_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.page_views_id_seq OWNED BY public.page_views.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages (
    id bigint NOT NULL,
    body_html text,
    body_json jsonb,
    body_markdown text,
    created_at timestamp without time zone NOT NULL,
    description character varying,
    is_top_level_path boolean DEFAULT false,
    processed_html text,
    slug character varying,
    social_image character varying,
    template character varying,
    title character varying,
    updated_at timestamp without time zone NOT NULL,
    landing_page boolean DEFAULT false NOT NULL
);


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pages_id_seq OWNED BY public.pages.id;


--
-- Name: pg_search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pg_search_documents (
    id bigint NOT NULL,
    content text,
    searchable_type character varying,
    searchable_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pg_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pg_search_documents_id_seq OWNED BY public.pg_search_documents.id;


--
-- Name: podcast_episode_appearances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.podcast_episode_appearances (
    id bigint NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    featured_on_user_profile boolean DEFAULT false NOT NULL,
    podcast_episode_id bigint NOT NULL,
    role character varying DEFAULT 'guest'::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: podcast_episode_appearances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.podcast_episode_appearances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: podcast_episode_appearances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.podcast_episode_appearances_id_seq OWNED BY public.podcast_episode_appearances.id;


--
-- Name: podcast_episodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.podcast_episodes (
    id bigint NOT NULL,
    any_comments_hidden boolean DEFAULT false,
    body text,
    comments_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    duration_in_seconds integer,
    guid character varying NOT NULL,
    https boolean DEFAULT true,
    image character varying,
    itunes_url character varying,
    media_url character varying NOT NULL,
    podcast_id bigint,
    processed_html text,
    published_at timestamp without time zone,
    quote text,
    reachable boolean DEFAULT true,
    reactions_count integer DEFAULT 0 NOT NULL,
    slug character varying NOT NULL,
    social_image character varying,
    status_notice character varying,
    subtitle character varying,
    summary text,
    title character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    website_url character varying
);


--
-- Name: podcast_episodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.podcast_episodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: podcast_episodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.podcast_episodes_id_seq OWNED BY public.podcast_episodes.id;


--
-- Name: podcast_ownerships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.podcast_ownerships (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    podcast_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: podcast_ownerships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.podcast_ownerships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: podcast_ownerships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.podcast_ownerships_id_seq OWNED BY public.podcast_ownerships.id;


--
-- Name: podcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.podcasts (
    id bigint NOT NULL,
    android_url character varying,
    created_at timestamp without time zone NOT NULL,
    creator_id bigint,
    description text,
    feed_url character varying NOT NULL,
    image character varying NOT NULL,
    itunes_url character varying,
    main_color_hex character varying NOT NULL,
    overcast_url character varying,
    pattern_image character varying,
    published boolean DEFAULT false,
    reachable boolean DEFAULT true,
    slug character varying NOT NULL,
    soundcloud_url character varying,
    status_notice text DEFAULT ''::text,
    title character varying NOT NULL,
    twitter_username character varying,
    "unique_website_url?" boolean DEFAULT true,
    updated_at timestamp without time zone NOT NULL,
    website_url character varying
);


--
-- Name: podcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.podcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: podcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.podcasts_id_seq OWNED BY public.podcasts.id;


--
-- Name: poll_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_options (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    markdown character varying,
    poll_id bigint,
    poll_votes_count integer DEFAULT 0 NOT NULL,
    processed_html character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: poll_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.poll_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.poll_options_id_seq OWNED BY public.poll_options.id;


--
-- Name: poll_skips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_skips (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    poll_id bigint,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: poll_skips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.poll_skips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_skips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.poll_skips_id_seq OWNED BY public.poll_skips.id;


--
-- Name: poll_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_votes (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    poll_id bigint NOT NULL,
    poll_option_id bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: poll_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.poll_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.poll_votes_id_seq OWNED BY public.poll_votes.id;


--
-- Name: polls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polls (
    id bigint NOT NULL,
    article_id bigint,
    created_at timestamp without time zone NOT NULL,
    poll_options_count integer DEFAULT 0 NOT NULL,
    poll_skips_count integer DEFAULT 0 NOT NULL,
    poll_votes_count integer DEFAULT 0 NOT NULL,
    prompt_html character varying,
    prompt_markdown character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: polls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polls_id_seq OWNED BY public.polls.id;


--
-- Name: profile_field_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_field_groups (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description character varying,
    name character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: profile_field_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profile_field_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_field_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profile_field_groups_id_seq OWNED BY public.profile_field_groups.id;


--
-- Name: profile_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_fields (
    id bigint NOT NULL,
    attribute_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description character varying,
    display_area integer DEFAULT 1 NOT NULL,
    input_type integer DEFAULT 0 NOT NULL,
    label public.citext NOT NULL,
    placeholder_text character varying,
    profile_field_group_id bigint,
    show_in_onboarding boolean DEFAULT false NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: profile_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profile_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profile_fields_id_seq OWNED BY public.profile_fields.id;


--
-- Name: profile_pins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_pins (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    pinnable_id bigint,
    pinnable_type character varying,
    profile_id bigint,
    profile_type character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: profile_pins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profile_pins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_pins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profile_pins_id_seq OWNED BY public.profile_pins.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- Name: rating_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rating_votes (
    id bigint NOT NULL,
    article_id bigint,
    context character varying DEFAULT 'explicit'::character varying,
    created_at timestamp without time zone NOT NULL,
    "group" character varying,
    rating double precision,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: rating_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rating_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rating_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rating_votes_id_seq OWNED BY public.rating_votes.id;


--
-- Name: reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reactions (
    id bigint NOT NULL,
    category character varying,
    created_at timestamp without time zone NOT NULL,
    points double precision DEFAULT 1.0,
    reactable_id bigint,
    reactable_type character varying,
    status character varying DEFAULT 'valid'::character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reactions_id_seq OWNED BY public.reactions.id;


--
-- Name: response_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.response_templates (
    id bigint NOT NULL,
    content text NOT NULL,
    content_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    title character varying NOT NULL,
    type_of character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: response_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.response_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: response_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.response_templates_id_seq OWNED BY public.response_templates.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    name character varying,
    resource_id bigint,
    resource_type character varying,
    updated_at timestamp without time zone
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: site_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_configs (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    value text,
    var character varying NOT NULL
);


--
-- Name: site_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.site_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.site_configs_id_seq OWNED BY public.site_configs.id;


--
-- Name: sponsorships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sponsorships (
    id bigint NOT NULL,
    blurb_html text,
    created_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone,
    featured_number integer DEFAULT 0 NOT NULL,
    instructions text,
    instructions_updated_at timestamp without time zone,
    level character varying NOT NULL,
    organization_id bigint,
    sponsorable_id bigint,
    sponsorable_type character varying,
    status character varying DEFAULT 'none'::character varying NOT NULL,
    tagline character varying,
    updated_at timestamp without time zone NOT NULL,
    url character varying,
    user_id bigint
);


--
-- Name: sponsorships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sponsorships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sponsorships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sponsorships_id_seq OWNED BY public.sponsorships.id;


--
-- Name: tag_adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tag_adjustments (
    id bigint NOT NULL,
    adjustment_type character varying,
    article_id bigint,
    created_at timestamp without time zone NOT NULL,
    reason_for_adjustment character varying,
    status character varying,
    tag_id bigint,
    tag_name character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: tag_adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_adjustments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tag_adjustments_id_seq OWNED BY public.tag_adjustments.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id bigint NOT NULL,
    context character varying(128),
    created_at timestamp without time zone,
    tag_id bigint,
    taggable_id bigint,
    taggable_type character varying,
    tagger_id bigint,
    tagger_type character varying
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taggings_id_seq OWNED BY public.taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    alias_for character varying,
    badge_id bigint,
    bg_color_hex character varying,
    category character varying DEFAULT 'uncategorized'::character varying NOT NULL,
    created_at timestamp without time zone,
    hotness_score integer DEFAULT 0,
    keywords_for_search character varying,
    mod_chat_channel_id bigint,
    name character varying,
    pretty_name character varying,
    profile_image character varying,
    requires_approval boolean DEFAULT false,
    rules_html text,
    rules_markdown text,
    short_summary character varying,
    social_image character varying,
    social_preview_template character varying DEFAULT 'article'::character varying,
    submission_template text,
    supported boolean DEFAULT false,
    taggings_count integer DEFAULT 0,
    text_color_hex character varying,
    updated_at timestamp without time zone,
    wiki_body_html text,
    wiki_body_markdown text
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tweets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tweets (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    extended_entities_serialized text DEFAULT '--- {}
'::text,
    favorite_count integer,
    full_fetched_object_serialized text DEFAULT '--- {}
'::text,
    hashtags_serialized character varying DEFAULT '--- []
'::character varying,
    in_reply_to_status_id_code character varying,
    in_reply_to_user_id_code character varying,
    in_reply_to_username character varying,
    is_quote_status boolean,
    last_fetched_at timestamp without time zone,
    media_serialized text DEFAULT '--- []
'::text,
    mentioned_usernames_serialized character varying DEFAULT '--- []
'::character varying,
    profile_image character varying,
    quoted_tweet_id_code character varying,
    retweet_count integer,
    source character varying,
    text character varying,
    tweeted_at timestamp without time zone,
    twitter_id_code character varying,
    twitter_name character varying,
    twitter_uid character varying,
    twitter_user_followers_count integer,
    twitter_user_following_count integer,
    twitter_username character varying,
    updated_at timestamp without time zone NOT NULL,
    urls_serialized text DEFAULT '--- []
'::text,
    user_id bigint,
    user_is_verified boolean
);


--
-- Name: tweets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tweets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tweets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tweets_id_seq OWNED BY public.tweets.id;


--
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_blocks (
    id bigint NOT NULL,
    blocked_id bigint NOT NULL,
    blocker_id bigint NOT NULL,
    config character varying DEFAULT 'default'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_blocks_id_seq OWNED BY public.user_blocks.id;


--
-- Name: user_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_subscriptions (
    id bigint NOT NULL,
    author_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    subscriber_email character varying NOT NULL,
    subscriber_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_subscription_sourceable_id bigint,
    user_subscription_sourceable_type character varying
);


--
-- Name: user_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_subscriptions_id_seq OWNED BY public.user_subscriptions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    apple_created_at timestamp without time zone,
    apple_username character varying,
    articles_count integer DEFAULT 0 NOT NULL,
    available_for character varying,
    badge_achievements_count integer DEFAULT 0 NOT NULL,
    behance_url character varying,
    bg_color_hex character varying,
    blocked_by_count bigint DEFAULT 0 NOT NULL,
    blocking_others_count bigint DEFAULT 0 NOT NULL,
    checked_code_of_conduct boolean DEFAULT false,
    checked_terms_and_conditions boolean DEFAULT false,
    comments_count integer DEFAULT 0 NOT NULL,
    config_font character varying DEFAULT 'default'::character varying,
    config_navbar character varying DEFAULT 'default'::character varying NOT NULL,
    config_theme character varying DEFAULT 'default'::character varying,
    confirmation_sent_at timestamp without time zone,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    credits_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    currently_hacking_on character varying,
    currently_learning character varying,
    display_announcements boolean DEFAULT true,
    display_sponsors boolean DEFAULT true,
    dribbble_url character varying,
    editor_version character varying DEFAULT 'v1'::character varying,
    education character varying,
    email character varying,
    email_badge_notifications boolean DEFAULT true,
    email_comment_notifications boolean DEFAULT true,
    email_community_mod_newsletter boolean DEFAULT false,
    email_connect_messages boolean DEFAULT true,
    email_digest_periodic boolean DEFAULT false NOT NULL,
    email_follower_notifications boolean DEFAULT true,
    email_membership_newsletter boolean DEFAULT false,
    email_mention_notifications boolean DEFAULT true,
    email_newsletter boolean DEFAULT false,
    email_public boolean DEFAULT false,
    email_tag_mod_newsletter boolean DEFAULT false,
    email_unread_notifications boolean DEFAULT true,
    employer_name character varying,
    employer_url character varying,
    employment_title character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    experience_level integer,
    export_requested boolean DEFAULT false,
    exported_at timestamp without time zone,
    facebook_created_at timestamp without time zone,
    facebook_url character varying,
    facebook_username character varying,
    failed_attempts integer DEFAULT 0,
    feed_fetched_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    feed_mark_canonical boolean DEFAULT false,
    feed_referential_link boolean DEFAULT true NOT NULL,
    feed_url character varying,
    following_orgs_count integer DEFAULT 0 NOT NULL,
    following_tags_count integer DEFAULT 0 NOT NULL,
    following_users_count integer DEFAULT 0 NOT NULL,
    github_created_at timestamp without time zone,
    github_repos_updated_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    github_username character varying,
    gitlab_url character varying,
    inbox_guidelines character varying,
    inbox_type character varying DEFAULT 'private'::character varying,
    instagram_url character varying,
    invitation_accepted_at timestamp without time zone,
    invitation_created_at timestamp without time zone,
    invitation_limit integer,
    invitation_sent_at timestamp without time zone,
    invitation_token character varying,
    invitations_count integer DEFAULT 0,
    invited_by_id bigint,
    invited_by_type character varying,
    last_article_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    last_comment_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    last_followed_at timestamp without time zone,
    last_moderation_notification timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    last_notification_activity timestamp without time zone,
    last_onboarding_page character varying,
    last_reacted_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    last_sign_in_ip inet,
    latest_article_updated_at timestamp without time zone,
    linkedin_url character varying,
    location character varying,
    locked_at timestamp without time zone,
    mastodon_url character varying,
    medium_url character varying,
    mobile_comment_notifications boolean DEFAULT true,
    mod_roundrobin_notifications boolean DEFAULT true,
    monthly_dues integer DEFAULT 0,
    mostly_work_with character varying,
    name character varying,
    old_old_username character varying,
    old_username character varying,
    onboarding_package_requested boolean DEFAULT false,
    organization_info_updated_at timestamp without time zone,
    payment_pointer character varying,
    permit_adjacent_sponsors boolean DEFAULT true,
    profile_image character varying,
    profile_updated_at timestamp without time zone DEFAULT '2017-01-01 05:00:00'::timestamp without time zone,
    rating_votes_count integer DEFAULT 0 NOT NULL,
    reaction_notifications boolean DEFAULT true,
    reactions_count integer DEFAULT 0 NOT NULL,
    registered boolean DEFAULT true,
    registered_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    remember_token character varying,
    reputation_modifier double precision DEFAULT 1.0,
    reset_password_sent_at timestamp without time zone,
    reset_password_token character varying,
    saw_onboarding boolean DEFAULT true,
    score integer DEFAULT 0,
    secret character varying,
    sign_in_count integer DEFAULT 0 NOT NULL,
    signup_cta_variant character varying,
    spent_credits_count integer DEFAULT 0 NOT NULL,
    stackoverflow_url character varying,
    stripe_id_code character varying,
    subscribed_to_user_subscriptions_count integer DEFAULT 0 NOT NULL,
    summary text,
    text_color_hex character varying,
    twitch_url character varying,
    twitter_created_at timestamp without time zone,
    twitter_followers_count integer,
    twitter_following_count integer,
    twitter_username character varying,
    unconfirmed_email character varying,
    unlock_token character varying,
    unspent_credits_count integer DEFAULT 0 NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    username character varying,
    website_url character varying,
    welcome_notifications boolean DEFAULT true NOT NULL,
    workshop_expiration timestamp without time zone,
    youtube_url character varying
);


--
-- Name: users_gdpr_delete_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_gdpr_delete_requests (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id integer,
    username character varying
);


--
-- Name: users_gdpr_delete_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_gdpr_delete_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_gdpr_delete_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_gdpr_delete_requests_id_seq OWNED BY public.users_gdpr_delete_requests.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_roles (
    role_id bigint,
    user_id bigint
);


--
-- Name: users_suspended_usernames; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_suspended_usernames (
    username_hash character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: webhook_endpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_endpoints (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    events character varying[] NOT NULL,
    oauth_application_id bigint,
    source character varying,
    target_url character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: webhook_endpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webhook_endpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhook_endpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webhook_endpoints_id_seq OWNED BY public.webhook_endpoints.id;


--
-- Name: welcome_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.welcome_notifications (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: welcome_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.welcome_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: welcome_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.welcome_notifications_id_seq OWNED BY public.welcome_notifications.id;


--
-- Name: ahoy_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events ALTER COLUMN id SET DEFAULT nextval('public.ahoy_events_id_seq'::regclass);


--
-- Name: ahoy_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_messages ALTER COLUMN id SET DEFAULT nextval('public.ahoy_messages_id_seq'::regclass);


--
-- Name: ahoy_visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_visits ALTER COLUMN id SET DEFAULT nextval('public.ahoy_visits_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: api_secrets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_secrets ALTER COLUMN id SET DEFAULT nextval('public.api_secrets_id_seq'::regclass);


--
-- Name: articles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles ALTER COLUMN id SET DEFAULT nextval('public.articles_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: badge_achievements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_achievements ALTER COLUMN id SET DEFAULT nextval('public.badge_achievements_id_seq'::regclass);


--
-- Name: badges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges ALTER COLUMN id SET DEFAULT nextval('public.badges_id_seq'::regclass);


--
-- Name: banished_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banished_users ALTER COLUMN id SET DEFAULT nextval('public.banished_users_id_seq'::regclass);


--
-- Name: blazer_audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_audits ALTER COLUMN id SET DEFAULT nextval('public.blazer_audits_id_seq'::regclass);


--
-- Name: blazer_checks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_checks ALTER COLUMN id SET DEFAULT nextval('public.blazer_checks_id_seq'::regclass);


--
-- Name: blazer_dashboard_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboard_queries ALTER COLUMN id SET DEFAULT nextval('public.blazer_dashboard_queries_id_seq'::regclass);


--
-- Name: blazer_dashboards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboards ALTER COLUMN id SET DEFAULT nextval('public.blazer_dashboards_id_seq'::regclass);


--
-- Name: blazer_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_queries ALTER COLUMN id SET DEFAULT nextval('public.blazer_queries_id_seq'::regclass);


--
-- Name: broadcasts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.broadcasts ALTER COLUMN id SET DEFAULT nextval('public.broadcasts_id_seq'::regclass);


--
-- Name: chat_channel_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships ALTER COLUMN id SET DEFAULT nextval('public.chat_channel_memberships_id_seq'::regclass);


--
-- Name: chat_channels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channels ALTER COLUMN id SET DEFAULT nextval('public.chat_channels_id_seq'::regclass);


--
-- Name: classified_listing_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classified_listing_categories ALTER COLUMN id SET DEFAULT nextval('public.classified_listing_categories_id_seq'::regclass);


--
-- Name: classified_listings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classified_listings ALTER COLUMN id SET DEFAULT nextval('public.classified_listings_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: credits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credits ALTER COLUMN id SET DEFAULT nextval('public.credits_id_seq'::regclass);


--
-- Name: custom_profile_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_profile_fields ALTER COLUMN id SET DEFAULT nextval('public.custom_profile_fields_id_seq'::regclass);


--
-- Name: data_update_scripts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_update_scripts ALTER COLUMN id SET DEFAULT nextval('public.data_update_scripts_id_seq'::regclass);


--
-- Name: devices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices ALTER COLUMN id SET DEFAULT nextval('public.devices_id_seq'::regclass);


--
-- Name: display_ad_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.display_ad_events ALTER COLUMN id SET DEFAULT nextval('public.display_ad_events_id_seq'::regclass);


--
-- Name: display_ads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.display_ads ALTER COLUMN id SET DEFAULT nextval('public.display_ads_id_seq'::regclass);


--
-- Name: email_authorizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_authorizations ALTER COLUMN id SET DEFAULT nextval('public.email_authorizations_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: feedback_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_messages ALTER COLUMN id SET DEFAULT nextval('public.feedback_messages_id_seq'::regclass);


--
-- Name: field_test_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_test_events ALTER COLUMN id SET DEFAULT nextval('public.field_test_events_id_seq'::regclass);


--
-- Name: field_test_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_test_memberships ALTER COLUMN id SET DEFAULT nextval('public.field_test_memberships_id_seq'::regclass);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- Name: follows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows ALTER COLUMN id SET DEFAULT nextval('public.follows_id_seq'::regclass);


--
-- Name: github_issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_issues ALTER COLUMN id SET DEFAULT nextval('public.github_issues_id_seq'::regclass);


--
-- Name: github_repos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_repos ALTER COLUMN id SET DEFAULT nextval('public.github_repos_id_seq'::regclass);


--
-- Name: html_variant_successes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_successes ALTER COLUMN id SET DEFAULT nextval('public.html_variant_successes_id_seq'::regclass);


--
-- Name: html_variant_trials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_trials ALTER COLUMN id SET DEFAULT nextval('public.html_variant_trials_id_seq'::regclass);


--
-- Name: html_variants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variants ALTER COLUMN id SET DEFAULT nextval('public.html_variants_id_seq'::regclass);


--
-- Name: identities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities ALTER COLUMN id SET DEFAULT nextval('public.identities_id_seq'::regclass);


--
-- Name: mentions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions ALTER COLUMN id SET DEFAULT nextval('public.mentions_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: navigation_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.navigation_links ALTER COLUMN id SET DEFAULT nextval('public.navigation_links_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: notification_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.notification_subscriptions_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);


--
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);


--
-- Name: oauth_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);


--
-- Name: organization_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_memberships ALTER COLUMN id SET DEFAULT nextval('public.organization_memberships_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations ALTER COLUMN id SET DEFAULT nextval('public.organizations_id_seq'::regclass);


--
-- Name: page_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views ALTER COLUMN id SET DEFAULT nextval('public.page_views_id_seq'::regclass);


--
-- Name: pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages ALTER COLUMN id SET DEFAULT nextval('public.pages_id_seq'::regclass);


--
-- Name: pg_search_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents ALTER COLUMN id SET DEFAULT nextval('public.pg_search_documents_id_seq'::regclass);


--
-- Name: podcast_episode_appearances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_episode_appearances ALTER COLUMN id SET DEFAULT nextval('public.podcast_episode_appearances_id_seq'::regclass);


--
-- Name: podcast_episodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_episodes ALTER COLUMN id SET DEFAULT nextval('public.podcast_episodes_id_seq'::regclass);


--
-- Name: podcast_ownerships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_ownerships ALTER COLUMN id SET DEFAULT nextval('public.podcast_ownerships_id_seq'::regclass);


--
-- Name: podcasts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcasts ALTER COLUMN id SET DEFAULT nextval('public.podcasts_id_seq'::regclass);


--
-- Name: poll_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_options ALTER COLUMN id SET DEFAULT nextval('public.poll_options_id_seq'::regclass);


--
-- Name: poll_skips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_skips ALTER COLUMN id SET DEFAULT nextval('public.poll_skips_id_seq'::regclass);


--
-- Name: poll_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes ALTER COLUMN id SET DEFAULT nextval('public.poll_votes_id_seq'::regclass);


--
-- Name: polls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls ALTER COLUMN id SET DEFAULT nextval('public.polls_id_seq'::regclass);


--
-- Name: profile_field_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_field_groups ALTER COLUMN id SET DEFAULT nextval('public.profile_field_groups_id_seq'::regclass);


--
-- Name: profile_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_fields ALTER COLUMN id SET DEFAULT nextval('public.profile_fields_id_seq'::regclass);


--
-- Name: profile_pins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_pins ALTER COLUMN id SET DEFAULT nextval('public.profile_pins_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: rating_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rating_votes ALTER COLUMN id SET DEFAULT nextval('public.rating_votes_id_seq'::regclass);


--
-- Name: reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions ALTER COLUMN id SET DEFAULT nextval('public.reactions_id_seq'::regclass);


--
-- Name: response_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.response_templates ALTER COLUMN id SET DEFAULT nextval('public.response_templates_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: site_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_configs ALTER COLUMN id SET DEFAULT nextval('public.site_configs_id_seq'::regclass);


--
-- Name: sponsorships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsorships ALTER COLUMN id SET DEFAULT nextval('public.sponsorships_id_seq'::regclass);


--
-- Name: tag_adjustments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_adjustments ALTER COLUMN id SET DEFAULT nextval('public.tag_adjustments_id_seq'::regclass);


--
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tweets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets ALTER COLUMN id SET DEFAULT nextval('public.tweets_id_seq'::regclass);


--
-- Name: user_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks ALTER COLUMN id SET DEFAULT nextval('public.user_blocks_id_seq'::regclass);


--
-- Name: user_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.user_subscriptions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_gdpr_delete_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_gdpr_delete_requests ALTER COLUMN id SET DEFAULT nextval('public.users_gdpr_delete_requests_id_seq'::regclass);


--
-- Name: webhook_endpoints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoints ALTER COLUMN id SET DEFAULT nextval('public.webhook_endpoints_id_seq'::regclass);


--
-- Name: welcome_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.welcome_notifications ALTER COLUMN id SET DEFAULT nextval('public.welcome_notifications_id_seq'::regclass);


--
-- Name: ahoy_events ahoy_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events
    ADD CONSTRAINT ahoy_events_pkey PRIMARY KEY (id);


--
-- Name: ahoy_messages ahoy_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_messages
    ADD CONSTRAINT ahoy_messages_pkey PRIMARY KEY (id);


--
-- Name: ahoy_visits ahoy_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_visits
    ADD CONSTRAINT ahoy_visits_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: api_secrets api_secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_secrets
    ADD CONSTRAINT api_secrets_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: badge_achievements badge_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_achievements
    ADD CONSTRAINT badge_achievements_pkey PRIMARY KEY (id);


--
-- Name: badges badges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT badges_pkey PRIMARY KEY (id);


--
-- Name: banished_users banished_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banished_users
    ADD CONSTRAINT banished_users_pkey PRIMARY KEY (id);


--
-- Name: blazer_audits blazer_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_audits
    ADD CONSTRAINT blazer_audits_pkey PRIMARY KEY (id);


--
-- Name: blazer_checks blazer_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_checks
    ADD CONSTRAINT blazer_checks_pkey PRIMARY KEY (id);


--
-- Name: blazer_dashboard_queries blazer_dashboard_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboard_queries
    ADD CONSTRAINT blazer_dashboard_queries_pkey PRIMARY KEY (id);


--
-- Name: blazer_dashboards blazer_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboards
    ADD CONSTRAINT blazer_dashboards_pkey PRIMARY KEY (id);


--
-- Name: blazer_queries blazer_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_queries
    ADD CONSTRAINT blazer_queries_pkey PRIMARY KEY (id);


--
-- Name: broadcasts broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.broadcasts
    ADD CONSTRAINT broadcasts_pkey PRIMARY KEY (id);


--
-- Name: chat_channel_memberships chat_channel_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships
    ADD CONSTRAINT chat_channel_memberships_pkey PRIMARY KEY (id);


--
-- Name: chat_channels chat_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channels
    ADD CONSTRAINT chat_channels_pkey PRIMARY KEY (id);


--
-- Name: classified_listing_categories classified_listing_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classified_listing_categories
    ADD CONSTRAINT classified_listing_categories_pkey PRIMARY KEY (id);


--
-- Name: classified_listings classified_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classified_listings
    ADD CONSTRAINT classified_listings_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: credits credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credits
    ADD CONSTRAINT credits_pkey PRIMARY KEY (id);


--
-- Name: custom_profile_fields custom_profile_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_profile_fields
    ADD CONSTRAINT custom_profile_fields_pkey PRIMARY KEY (id);


--
-- Name: data_update_scripts data_update_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_update_scripts
    ADD CONSTRAINT data_update_scripts_pkey PRIMARY KEY (id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: display_ad_events display_ad_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.display_ad_events
    ADD CONSTRAINT display_ad_events_pkey PRIMARY KEY (id);


--
-- Name: display_ads display_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.display_ads
    ADD CONSTRAINT display_ads_pkey PRIMARY KEY (id);


--
-- Name: email_authorizations email_authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_authorizations
    ADD CONSTRAINT email_authorizations_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: feedback_messages feedback_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_messages
    ADD CONSTRAINT feedback_messages_pkey PRIMARY KEY (id);


--
-- Name: field_test_events field_test_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_test_events
    ADD CONSTRAINT field_test_events_pkey PRIMARY KEY (id);


--
-- Name: field_test_memberships field_test_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_test_memberships
    ADD CONSTRAINT field_test_memberships_pkey PRIMARY KEY (id);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: follows follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (id);


--
-- Name: github_issues github_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_issues
    ADD CONSTRAINT github_issues_pkey PRIMARY KEY (id);


--
-- Name: github_repos github_repos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_repos
    ADD CONSTRAINT github_repos_pkey PRIMARY KEY (id);


--
-- Name: html_variant_successes html_variant_successes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_successes
    ADD CONSTRAINT html_variant_successes_pkey PRIMARY KEY (id);


--
-- Name: html_variant_trials html_variant_trials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_trials
    ADD CONSTRAINT html_variant_trials_pkey PRIMARY KEY (id);


--
-- Name: html_variants html_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variants
    ADD CONSTRAINT html_variants_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: mentions mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT mentions_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: navigation_links navigation_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.navigation_links
    ADD CONSTRAINT navigation_links_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: notification_subscriptions notification_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_subscriptions
    ADD CONSTRAINT notification_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: organization_memberships organization_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_memberships
    ADD CONSTRAINT organization_memberships_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: page_views page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: pg_search_documents pg_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents
    ADD CONSTRAINT pg_search_documents_pkey PRIMARY KEY (id);


--
-- Name: podcast_episode_appearances podcast_episode_appearances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_episode_appearances
    ADD CONSTRAINT podcast_episode_appearances_pkey PRIMARY KEY (id);


--
-- Name: podcast_episodes podcast_episodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_episodes
    ADD CONSTRAINT podcast_episodes_pkey PRIMARY KEY (id);


--
-- Name: podcast_ownerships podcast_ownerships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_ownerships
    ADD CONSTRAINT podcast_ownerships_pkey PRIMARY KEY (id);


--
-- Name: podcasts podcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcasts
    ADD CONSTRAINT podcasts_pkey PRIMARY KEY (id);


--
-- Name: poll_options poll_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_pkey PRIMARY KEY (id);


--
-- Name: poll_skips poll_skips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_skips
    ADD CONSTRAINT poll_skips_pkey PRIMARY KEY (id);


--
-- Name: poll_votes poll_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (id);


--
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- Name: profile_field_groups profile_field_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_field_groups
    ADD CONSTRAINT profile_field_groups_pkey PRIMARY KEY (id);


--
-- Name: profile_fields profile_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_fields
    ADD CONSTRAINT profile_fields_pkey PRIMARY KEY (id);


--
-- Name: profile_pins profile_pins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_pins
    ADD CONSTRAINT profile_pins_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: rating_votes rating_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rating_votes
    ADD CONSTRAINT rating_votes_pkey PRIMARY KEY (id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (id);


--
-- Name: response_templates response_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.response_templates
    ADD CONSTRAINT response_templates_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: site_configs site_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_configs
    ADD CONSTRAINT site_configs_pkey PRIMARY KEY (id);


--
-- Name: sponsorships sponsorships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsorships
    ADD CONSTRAINT sponsorships_pkey PRIMARY KEY (id);


--
-- Name: tag_adjustments tag_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_adjustments
    ADD CONSTRAINT tag_adjustments_pkey PRIMARY KEY (id);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tweets tweets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets
    ADD CONSTRAINT tweets_pkey PRIMARY KEY (id);


--
-- Name: user_blocks user_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- Name: user_subscriptions user_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users_gdpr_delete_requests users_gdpr_delete_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_gdpr_delete_requests
    ADD CONSTRAINT users_gdpr_delete_requests_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_suspended_usernames users_suspended_usernames_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_suspended_usernames
    ADD CONSTRAINT users_suspended_usernames_pkey PRIMARY KEY (username_hash);


--
-- Name: users users_username_not_null; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.users
    ADD CONSTRAINT users_username_not_null CHECK ((username IS NOT NULL)) NOT VALID;


--
-- Name: webhook_endpoints webhook_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoints
    ADD CONSTRAINT webhook_endpoints_pkey PRIMARY KEY (id);


--
-- Name: welcome_notifications welcome_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.welcome_notifications
    ADD CONSTRAINT welcome_notifications_pkey PRIMARY KEY (id);


--
-- Name: fk_followables; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk_followables ON public.follows USING btree (followable_id, followable_type);


--
-- Name: fk_follows; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fk_follows ON public.follows USING btree (follower_id, follower_type);


--
-- Name: idx_notification_subs_on_user_id_notifiable_type_notifiable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_notification_subs_on_user_id_notifiable_type_notifiable_id ON public.notification_subscriptions USING btree (user_id, notifiable_type, notifiable_id);


--
-- Name: idx_pins_on_pinnable_id_profile_id_profile_type_pinnable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_pins_on_pinnable_id_profile_id_profile_type_pinnable_type ON public.profile_pins USING btree (pinnable_id, profile_id, profile_type, pinnable_type);


--
-- Name: idx_response_templates_on_content_user_id_type_of_content_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_response_templates_on_content_user_id_type_of_content_type ON public.response_templates USING btree (content, user_id, type_of, content_type);


--
-- Name: index_ahoy_events_on_name_and_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_name_and_time ON public.ahoy_events USING btree (name, "time");


--
-- Name: index_ahoy_events_on_properties; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_properties ON public.ahoy_events USING gin (properties jsonb_path_ops);


--
-- Name: index_ahoy_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_user_id ON public.ahoy_events USING btree (user_id);


--
-- Name: index_ahoy_events_on_visit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_visit_id ON public.ahoy_events USING btree (visit_id);


--
-- Name: index_ahoy_messages_on_feedback_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_messages_on_feedback_message_id ON public.ahoy_messages USING btree (feedback_message_id);


--
-- Name: index_ahoy_messages_on_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_messages_on_to ON public.ahoy_messages USING btree ("to");


--
-- Name: index_ahoy_messages_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_messages_on_token ON public.ahoy_messages USING btree (token);


--
-- Name: index_ahoy_messages_on_user_id_and_mailer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_messages_on_user_id_and_mailer ON public.ahoy_messages USING btree (user_id, mailer);


--
-- Name: index_ahoy_messages_on_user_id_and_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_messages_on_user_id_and_user_type ON public.ahoy_messages USING btree (user_id, user_type);


--
-- Name: index_ahoy_visits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_visits_on_user_id ON public.ahoy_visits USING btree (user_id);


--
-- Name: index_ahoy_visits_on_visit_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ahoy_visits_on_visit_token ON public.ahoy_visits USING btree (visit_token);


--
-- Name: index_api_secrets_on_secret; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_secrets_on_secret ON public.api_secrets USING btree (secret);


--
-- Name: index_api_secrets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_secrets_on_user_id ON public.api_secrets USING btree (user_id);


--
-- Name: index_articles_on_body_markdown_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_body_markdown_trgm ON public.articles USING gin (body_markdown public.gin_trgm_ops);


--
-- Name: index_articles_on_boost_states; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_boost_states ON public.articles USING gin (boost_states);


--
-- Name: index_articles_on_cached_tag_list; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_cached_tag_list ON public.articles USING gin (cached_tag_list public.gin_trgm_ops);


--
-- Name: index_articles_on_canonical_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_articles_on_canonical_url ON public.articles USING btree (canonical_url);


--
-- Name: index_articles_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_collection_id ON public.articles USING btree (collection_id);


--
-- Name: index_articles_on_comment_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_comment_score ON public.articles USING btree (comment_score);


--
-- Name: index_articles_on_featured_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_featured_number ON public.articles USING btree (featured_number);


--
-- Name: index_articles_on_feed_source_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_articles_on_feed_source_url ON public.articles USING btree (feed_source_url);


--
-- Name: index_articles_on_hotness_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_hotness_score ON public.articles USING btree (hotness_score);


--
-- Name: index_articles_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_path ON public.articles USING btree (path);


--
-- Name: index_articles_on_public_reactions_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_public_reactions_count ON public.articles USING btree (public_reactions_count DESC);


--
-- Name: index_articles_on_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_published ON public.articles USING btree (published);


--
-- Name: index_articles_on_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_published_at ON public.articles USING btree (published_at);


--
-- Name: index_articles_on_slug_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_articles_on_slug_and_user_id ON public.articles USING btree (slug, user_id);


--
-- Name: index_articles_on_title_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_title_trgm ON public.articles USING gin (title public.gin_trgm_ops);


--
-- Name: index_articles_on_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_tsv ON public.articles USING gin (tsv);


--
-- Name: index_articles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_user_id ON public.articles USING btree (user_id);


--
-- Name: index_articles_on_user_id_and_title_and_digest_body_markdown; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_articles_on_user_id_and_title_and_digest_body_markdown ON public.articles USING btree (user_id, title, public.digest(body_markdown, 'sha512'::text));


--
-- Name: index_audit_logs_on_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_data ON public.audit_logs USING gin (data);


--
-- Name: index_audit_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: index_badge_achievements_on_badge_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_badge_achievements_on_badge_id_and_user_id ON public.badge_achievements USING btree (badge_id, user_id);


--
-- Name: index_badge_achievements_on_user_id_and_badge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_achievements_on_user_id_and_badge_id ON public.badge_achievements USING btree (user_id, badge_id);


--
-- Name: index_badges_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_badges_on_slug ON public.badges USING btree (slug);


--
-- Name: index_badges_on_title; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_badges_on_title ON public.badges USING btree (title);


--
-- Name: index_banished_users_on_banished_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_banished_users_on_banished_by_id ON public.banished_users USING btree (banished_by_id);


--
-- Name: index_banished_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_banished_users_on_username ON public.banished_users USING btree (username);


--
-- Name: index_blazer_audits_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_audits_on_query_id ON public.blazer_audits USING btree (query_id);


--
-- Name: index_blazer_audits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_audits_on_user_id ON public.blazer_audits USING btree (user_id);


--
-- Name: index_blazer_checks_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_checks_on_creator_id ON public.blazer_checks USING btree (creator_id);


--
-- Name: index_blazer_checks_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_checks_on_query_id ON public.blazer_checks USING btree (query_id);


--
-- Name: index_blazer_dashboard_queries_on_dashboard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboard_queries_on_dashboard_id ON public.blazer_dashboard_queries USING btree (dashboard_id);


--
-- Name: index_blazer_dashboard_queries_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboard_queries_on_query_id ON public.blazer_dashboard_queries USING btree (query_id);


--
-- Name: index_blazer_dashboards_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboards_on_creator_id ON public.blazer_dashboards USING btree (creator_id);


--
-- Name: index_blazer_queries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_queries_on_creator_id ON public.blazer_queries USING btree (creator_id);


--
-- Name: index_broadcasts_on_broadcastable_type_and_broadcastable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_broadcasts_on_broadcastable_type_and_broadcastable_id ON public.broadcasts USING btree (broadcastable_type, broadcastable_id);


--
-- Name: index_broadcasts_on_title_and_type_of; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_broadcasts_on_title_and_type_of ON public.broadcasts USING btree (title, type_of);


--
-- Name: index_chat_channel_memberships_on_chat_channel_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chat_channel_memberships_on_chat_channel_id_and_user_id ON public.chat_channel_memberships USING btree (chat_channel_id, user_id);


--
-- Name: index_chat_channel_memberships_on_user_id_and_chat_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_channel_memberships_on_user_id_and_chat_channel_id ON public.chat_channel_memberships USING btree (user_id, chat_channel_id);


--
-- Name: index_chat_channels_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chat_channels_on_slug ON public.chat_channels USING btree (slug);


--
-- Name: index_classified_listing_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_classified_listing_categories_on_name ON public.classified_listing_categories USING btree (name);


--
-- Name: index_classified_listing_categories_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_classified_listing_categories_on_slug ON public.classified_listing_categories USING btree (slug);


--
-- Name: index_classified_listings_on_classified_listing_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_classified_listings_on_classified_listing_category_id ON public.classified_listings USING btree (classified_listing_category_id);


--
-- Name: index_classified_listings_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_classified_listings_on_organization_id ON public.classified_listings USING btree (organization_id);


--
-- Name: index_classified_listings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_classified_listings_on_user_id ON public.classified_listings USING btree (user_id);


--
-- Name: index_collections_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_organization_id ON public.collections USING btree (organization_id);


--
-- Name: index_collections_on_slug_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collections_on_slug_and_user_id ON public.collections USING btree (slug, user_id);


--
-- Name: index_collections_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_user_id ON public.collections USING btree (user_id);


--
-- Name: index_comments_on_ancestry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_ancestry ON public.comments USING btree (ancestry);


--
-- Name: index_comments_on_ancestry_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_ancestry_trgm ON public.comments USING gin (ancestry public.gin_trgm_ops);


--
-- Name: index_comments_on_body_markdown_user_ancestry_commentable; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_comments_on_body_markdown_user_ancestry_commentable ON public.comments USING btree (public.digest(body_markdown, 'sha512'::text), user_id, ancestry, commentable_id, commentable_type);


--
-- Name: index_comments_on_commentable_id_and_commentable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_id_and_commentable_type ON public.comments USING btree (commentable_id, commentable_type);


--
-- Name: index_comments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_created_at ON public.comments USING btree (created_at);


--
-- Name: index_comments_on_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_score ON public.comments USING btree (score);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_credits_on_purchase_id_and_purchase_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credits_on_purchase_id_and_purchase_type ON public.credits USING btree (purchase_id, purchase_type);


--
-- Name: index_credits_on_spent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credits_on_spent ON public.credits USING btree (spent);


--
-- Name: index_custom_profile_fields_on_label_and_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_profile_fields_on_label_and_profile_id ON public.custom_profile_fields USING btree (label, profile_id);


--
-- Name: index_custom_profile_fields_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_profile_fields_on_profile_id ON public.custom_profile_fields USING btree (profile_id);


--
-- Name: index_data_update_scripts_on_file_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_data_update_scripts_on_file_name ON public.data_update_scripts USING btree (file_name);


--
-- Name: index_devices_on_user_id_and_token_and_platform_and_app_bundle; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_devices_on_user_id_and_token_and_platform_and_app_bundle ON public.devices USING btree (user_id, token, platform, app_bundle);


--
-- Name: index_display_ad_events_on_display_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_display_ad_events_on_display_ad_id ON public.display_ad_events USING btree (display_ad_id);


--
-- Name: index_display_ad_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_display_ad_events_on_user_id ON public.display_ad_events USING btree (user_id);


--
-- Name: index_email_authorizations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_authorizations_on_user_id ON public.email_authorizations USING btree (user_id);


--
-- Name: index_feedback_messages_on_affected_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_messages_on_affected_id ON public.feedback_messages USING btree (affected_id);


--
-- Name: index_feedback_messages_on_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_messages_on_offender_id ON public.feedback_messages USING btree (offender_id);


--
-- Name: index_feedback_messages_on_reporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_messages_on_reporter_id ON public.feedback_messages USING btree (reporter_id);


--
-- Name: index_feedback_messages_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_messages_on_status ON public.feedback_messages USING btree (status);


--
-- Name: index_field_test_events_on_field_test_membership_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_field_test_events_on_field_test_membership_id ON public.field_test_events USING btree (field_test_membership_id);


--
-- Name: index_field_test_memberships_on_experiment_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_field_test_memberships_on_experiment_and_created_at ON public.field_test_memberships USING btree (experiment, created_at);


--
-- Name: index_field_test_memberships_on_participant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_field_test_memberships_on_participant ON public.field_test_memberships USING btree (participant_type, participant_id, experiment);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_follows_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_created_at ON public.follows USING btree (created_at);


--
-- Name: index_follows_on_followable_and_follower; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_follows_on_followable_and_follower ON public.follows USING btree (followable_id, followable_type, follower_id, follower_type);


--
-- Name: index_github_issues_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_github_issues_on_url ON public.github_issues USING btree (url);


--
-- Name: index_github_repos_on_github_id_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_github_repos_on_github_id_code ON public.github_repos USING btree (github_id_code);


--
-- Name: index_github_repos_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_github_repos_on_url ON public.github_repos USING btree (url);


--
-- Name: index_html_variant_successes_on_html_variant_id_and_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_html_variant_successes_on_html_variant_id_and_article_id ON public.html_variant_successes USING btree (html_variant_id, article_id);


--
-- Name: index_html_variant_trials_on_html_variant_id_and_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_html_variant_trials_on_html_variant_id_and_article_id ON public.html_variant_trials USING btree (html_variant_id, article_id);


--
-- Name: index_html_variants_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_html_variants_on_name ON public.html_variants USING btree (name);


--
-- Name: index_identities_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_identities_on_provider_and_uid ON public.identities USING btree (provider, uid);


--
-- Name: index_identities_on_provider_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_identities_on_provider_and_user_id ON public.identities USING btree (provider, user_id);


--
-- Name: index_mentions_on_user_id_and_mentionable_id_mentionable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mentions_on_user_id_and_mentionable_id_mentionable_type ON public.mentions USING btree (user_id, mentionable_id, mentionable_type);


--
-- Name: index_messages_on_chat_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_chat_channel_id ON public.messages USING btree (chat_channel_id);


--
-- Name: index_messages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_user_id ON public.messages USING btree (user_id);


--
-- Name: index_navigation_links_on_url_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_navigation_links_on_url_and_name ON public.navigation_links USING btree (url, name);


--
-- Name: index_notification_subscriptions_on_notifiable_and_config; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_subscriptions_on_notifiable_and_config ON public.notification_subscriptions USING btree (notifiable_id, notifiable_type, config);


--
-- Name: index_notifications_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_created_at ON public.notifications USING btree (created_at);


--
-- Name: index_notifications_on_notifiable_id_notifiable_type_and_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notifiable_id_notifiable_type_and_action ON public.notifications USING btree (notifiable_id, notifiable_type, action);


--
-- Name: index_notifications_on_notifiable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notifiable_type ON public.notifications USING btree (notifiable_type);


--
-- Name: index_notifications_on_notified_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notified_at ON public.notifications USING btree (notified_at);


--
-- Name: index_notifications_on_org_notifiable_action_is_null; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_on_org_notifiable_action_is_null ON public.notifications USING btree (organization_id, notifiable_id, notifiable_type) WHERE (action IS NULL);


--
-- Name: index_notifications_on_org_notifiable_and_action_not_null; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_on_org_notifiable_and_action_not_null ON public.notifications USING btree (organization_id, notifiable_id, notifiable_type, action) WHERE (action IS NOT NULL);


--
-- Name: index_notifications_on_user_notifiable_action_is_null; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_on_user_notifiable_action_is_null ON public.notifications USING btree (user_id, notifiable_id, notifiable_type) WHERE (action IS NULL);


--
-- Name: index_notifications_on_user_notifiable_and_action_not_null; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_on_user_notifiable_and_action_not_null ON public.notifications USING btree (user_id, notifiable_id, notifiable_type, action) WHERE (action IS NOT NULL);


--
-- Name: index_notifications_user_id_organization_id_notifiable_action; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_user_id_organization_id_notifiable_action ON public.notifications USING btree (user_id, organization_id, notifiable_id, notifiable_type, action);


--
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_application_id ON public.oauth_access_grants USING btree (application_id);


--
-- Name: index_oauth_access_grants_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_resource_owner_id ON public.oauth_access_grants USING btree (resource_owner_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_on_user_subscription_sourcebable_type_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_user_subscription_sourcebable_type_and_id ON public.user_subscriptions USING btree (user_subscription_sourceable_type, user_subscription_sourceable_id);


--
-- Name: index_organization_memberships_on_user_id_and_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organization_memberships_on_user_id_and_organization_id ON public.organization_memberships USING btree (user_id, organization_id);


--
-- Name: index_organizations_on_secret; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_secret ON public.organizations USING btree (secret);


--
-- Name: index_organizations_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_slug ON public.organizations USING btree (slug);


--
-- Name: index_page_views_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_article_id ON public.page_views USING btree (article_id);


--
-- Name: index_page_views_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_created_at ON public.page_views USING btree (created_at);


--
-- Name: index_page_views_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_user_id ON public.page_views USING btree (user_id);


--
-- Name: index_pages_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pages_on_slug ON public.pages USING btree (slug);


--
-- Name: index_pg_search_documents_on_searchable_type_and_searchable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pg_search_documents_on_searchable_type_and_searchable_id ON public.pg_search_documents USING btree (searchable_type, searchable_id);


--
-- Name: index_pg_search_documents_on_username_as_tsvector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pg_search_documents_on_username_as_tsvector ON public.pg_search_documents USING gin (to_tsvector('simple'::regconfig, COALESCE(content, ''::text)));


--
-- Name: index_pod_episode_appearances_on_podcast_episode_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pod_episode_appearances_on_podcast_episode_id_and_user_id ON public.podcast_episode_appearances USING btree (podcast_episode_id, user_id);


--
-- Name: index_podcast_episodes_on_guid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_podcast_episodes_on_guid ON public.podcast_episodes USING btree (guid);


--
-- Name: index_podcast_episodes_on_media_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_podcast_episodes_on_media_url ON public.podcast_episodes USING btree (media_url);


--
-- Name: index_podcast_episodes_on_podcast_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_podcast_episodes_on_podcast_id ON public.podcast_episodes USING btree (podcast_id);


--
-- Name: index_podcast_episodes_on_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_podcast_episodes_on_title ON public.podcast_episodes USING btree (title);


--
-- Name: index_podcast_episodes_on_website_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_podcast_episodes_on_website_url ON public.podcast_episodes USING btree (website_url);


--
-- Name: index_podcast_ownerships_on_podcast_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_podcast_ownerships_on_podcast_id_and_user_id ON public.podcast_ownerships USING btree (podcast_id, user_id);


--
-- Name: index_podcasts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_podcasts_on_creator_id ON public.podcasts USING btree (creator_id);


--
-- Name: index_podcasts_on_feed_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_podcasts_on_feed_url ON public.podcasts USING btree (feed_url);


--
-- Name: index_podcasts_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_podcasts_on_slug ON public.podcasts USING btree (slug);


--
-- Name: index_poll_skips_on_poll_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_poll_skips_on_poll_and_user ON public.poll_skips USING btree (poll_id, user_id);


--
-- Name: index_poll_votes_on_poll_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_poll_votes_on_poll_id_and_user_id ON public.poll_votes USING btree (poll_id, user_id);


--
-- Name: index_poll_votes_on_poll_option_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_poll_votes_on_poll_option_and_user ON public.poll_votes USING btree (poll_option_id, user_id);


--
-- Name: index_profile_field_groups_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_profile_field_groups_on_name ON public.profile_field_groups USING btree (name);


--
-- Name: index_profile_fields_on_label; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_profile_fields_on_label ON public.profile_fields USING btree (label);


--
-- Name: index_profile_fields_on_profile_field_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profile_fields_on_profile_field_group_id ON public.profile_fields USING btree (profile_field_group_id);


--
-- Name: index_profile_pins_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profile_pins_on_profile_id ON public.profile_pins USING btree (profile_id);


--
-- Name: index_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_profiles_on_user_id ON public.profiles USING btree (user_id);


--
-- Name: index_rating_votes_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rating_votes_on_article_id ON public.rating_votes USING btree (article_id);


--
-- Name: index_rating_votes_on_user_id_and_article_id_and_context; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rating_votes_on_user_id_and_article_id_and_context ON public.rating_votes USING btree (user_id, article_id, context);


--
-- Name: index_reactions_on_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_category ON public.reactions USING btree (category);


--
-- Name: index_reactions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_created_at ON public.reactions USING btree (created_at);


--
-- Name: index_reactions_on_points; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_points ON public.reactions USING btree (points);


--
-- Name: index_reactions_on_reactable_id_and_reactable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_reactable_id_and_reactable_type ON public.reactions USING btree (reactable_id, reactable_type);


--
-- Name: index_reactions_on_reactable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_reactable_type ON public.reactions USING btree (reactable_type);


--
-- Name: index_reactions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_status ON public.reactions USING btree (status);


--
-- Name: index_reactions_on_user_id_reactable_id_reactable_type_category; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reactions_on_user_id_reactable_id_reactable_type_category ON public.reactions USING btree (user_id, reactable_id, reactable_type, category);


--
-- Name: index_response_templates_on_type_of; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_response_templates_on_type_of ON public.response_templates USING btree (type_of);


--
-- Name: index_response_templates_on_user_id_and_type_of; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_response_templates_on_user_id_and_type_of ON public.response_templates USING btree (user_id, type_of);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- Name: index_roles_on_name_and_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name_and_resource_type_and_resource_id ON public.roles USING btree (name, resource_type, resource_id);


--
-- Name: index_site_configs_on_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_site_configs_on_var ON public.site_configs USING btree (var);


--
-- Name: index_sponsorships_on_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sponsorships_on_level ON public.sponsorships USING btree (level);


--
-- Name: index_sponsorships_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sponsorships_on_organization_id ON public.sponsorships USING btree (organization_id);


--
-- Name: index_sponsorships_on_sponsorable_id_and_sponsorable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sponsorships_on_sponsorable_id_and_sponsorable_type ON public.sponsorships USING btree (sponsorable_id, sponsorable_type);


--
-- Name: index_sponsorships_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sponsorships_on_status ON public.sponsorships USING btree (status);


--
-- Name: index_sponsorships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sponsorships_on_user_id ON public.sponsorships USING btree (user_id);


--
-- Name: index_subscriber_id_and_email_with_user_subscription_source; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscriber_id_and_email_with_user_subscription_source ON public.user_subscriptions USING btree (subscriber_id, subscriber_email, user_subscription_sourceable_type, user_subscription_sourceable_id);


--
-- Name: index_tag_adjustments_on_tag_name_and_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tag_adjustments_on_tag_name_and_article_id ON public.tag_adjustments USING btree (tag_name, article_id);


--
-- Name: index_taggings_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_context ON public.taggings USING btree (context);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id ON public.taggings USING btree (taggable_id);


--
-- Name: index_taggings_on_taggable_id_and_taggable_type_and_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type_and_context ON public.taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: index_taggings_on_taggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_type ON public.taggings USING btree (taggable_type);


--
-- Name: index_taggings_on_tagger_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id ON public.taggings USING btree (tagger_id);


--
-- Name: index_taggings_on_tagger_id_and_tagger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id_and_tagger_type ON public.taggings USING btree (tagger_id, tagger_type);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tags_on_social_preview_template; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_social_preview_template ON public.tags USING btree (social_preview_template);


--
-- Name: index_tags_on_supported; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_supported ON public.tags USING btree (supported);


--
-- Name: index_user_blocks_on_blocked_id_and_blocker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_blocks_on_blocked_id_and_blocker_id ON public.user_blocks USING btree (blocked_id, blocker_id);


--
-- Name: index_user_subscriptions_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_subscriptions_on_author_id ON public.user_subscriptions USING btree (author_id);


--
-- Name: index_user_subscriptions_on_subscriber_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_subscriptions_on_subscriber_email ON public.user_subscriptions USING btree (subscriber_email);


--
-- Name: index_users_on_apple_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_apple_username ON public.users USING btree (apple_username);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_at ON public.users USING btree (created_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_facebook_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_facebook_username ON public.users USING btree (facebook_username);


--
-- Name: index_users_on_feed_fetched_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_feed_fetched_at ON public.users USING btree (feed_fetched_at);


--
-- Name: index_users_on_feed_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_feed_url ON public.users USING btree (feed_url) WHERE ((COALESCE(feed_url, ''::character varying))::text <> ''::text);


--
-- Name: index_users_on_github_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_github_username ON public.users USING btree (github_username);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitations_count ON public.users USING btree (invitations_count);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON public.users USING btree (invited_by_id);


--
-- Name: index_users_on_invited_by_type_and_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_type_and_invited_by_id ON public.users USING btree (invited_by_type, invited_by_id);


--
-- Name: index_users_on_old_old_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_old_old_username ON public.users USING btree (old_old_username);


--
-- Name: index_users_on_old_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_old_username ON public.users USING btree (old_username);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_twitter_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_twitter_username ON public.users USING btree (twitter_username);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: index_users_on_username_as_tsvector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_username_as_tsvector ON public.users USING gin (to_tsvector('simple'::regconfig, COALESCE((username)::text, ''::text)));


--
-- Name: index_users_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_user_id_and_role_id ON public.users_roles USING btree (user_id, role_id);


--
-- Name: index_webhook_endpoints_on_events; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_endpoints_on_events ON public.webhook_endpoints USING btree (events);


--
-- Name: index_webhook_endpoints_on_oauth_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_endpoints_on_oauth_application_id ON public.webhook_endpoints USING btree (oauth_application_id);


--
-- Name: index_webhook_endpoints_on_target_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webhook_endpoints_on_target_url ON public.webhook_endpoints USING btree (target_url);


--
-- Name: index_webhook_endpoints_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_endpoints_on_user_id ON public.webhook_endpoints USING btree (user_id);


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON public.taggings USING btree (taggable_id, taggable_type, tagger_id, context);


--
-- Name: articles tsv_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsv_tsvector_update BEFORE INSERT OR UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('tsv', 'pg_catalog.simple', 'body_markdown', 'cached_tag_list', 'title');


--
-- Name: tweets fk_rails_003928b7f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tweets
    ADD CONSTRAINT fk_rails_003928b7f5 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: page_views fk_rails_00f38b1a99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT fk_rails_00f38b1a99 FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: comments fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: webhook_endpoints fk_rails_083276d374; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoints
    ADD CONSTRAINT fk_rails_083276d374 FOREIGN KEY (oauth_application_id) REFERENCES public.oauth_applications(id);


--
-- Name: podcast_episode_appearances fk_rails_09327c8b91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_episode_appearances
    ADD CONSTRAINT fk_rails_09327c8b91 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: messages fk_rails_1321992401; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_1321992401 FOREIGN KEY (chat_channel_id) REFERENCES public.chat_channels(id);


--
-- Name: page_views fk_rails_13a4e75c00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT fk_rails_13a4e75c00 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: banished_users fk_rails_153ba6df7a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banished_users
    ADD CONSTRAINT fk_rails_153ba6df7a FOREIGN KEY (banished_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: display_ad_events fk_rails_1821fcc2c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.display_ad_events
    ADD CONSTRAINT fk_rails_1821fcc2c7 FOREIGN KEY (display_ad_id) REFERENCES public.display_ads(id) ON DELETE CASCADE;


--
-- Name: mentions fk_rails_1b711e94aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_rails_1b711e94aa FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_subscriptions fk_rails_1ed776f5d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT fk_rails_1ed776f5d9 FOREIGN KEY (subscriber_id) REFERENCES public.users(id);


--
-- Name: audit_logs fk_rails_1f26bc34ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_rails_1f26bc34ae FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: collections fk_rails_217eef6689; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT fk_rails_217eef6689 FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: podcasts fk_rails_23fc7f8ed6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcasts
    ADD CONSTRAINT fk_rails_23fc7f8ed6 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: classified_listings fk_rails_2571500d9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classified_listings
    ADD CONSTRAINT fk_rails_2571500d9c FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: messages fk_rails_273a25a7a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_273a25a7a6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: badge_achievements fk_rails_27820f58ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_achievements
    ADD CONSTRAINT fk_rails_27820f58ce FOREIGN KEY (badge_id) REFERENCES public.badges(id);


--
-- Name: articles fk_rails_2b371e3029; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT fk_rails_2b371e3029 FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE SET NULL;


--
-- Name: notification_subscriptions fk_rails_2bf71acda7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_subscriptions
    ADD CONSTRAINT fk_rails_2bf71acda7 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: oauth_access_grants fk_rails_330c32d8d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_330c32d8d9 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id);


--
-- Name: notes fk_rails_36c9deba43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_36c9deba43 FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: podcast_ownerships fk_rails_3710d65292; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_ownerships
    ADD CONSTRAINT fk_rails_3710d65292 FOREIGN KEY (podcast_id) REFERENCES public.podcasts(id);


--
-- Name: notifications fk_rails_394d9847aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_394d9847aa FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: articles fk_rails_3d31dad1cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT fk_rails_3d31dad1cc FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: poll_skips fk_rails_4046c49c05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_skips
    ADD CONSTRAINT fk_rails_4046c49c05 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: devices fk_rails_410b63ef65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT fk_rails_410b63ef65 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: polls fk_rails_48d9b585ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT fk_rails_48d9b585ee FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: badge_achievements fk_rails_4a2e48ca67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_achievements
    ADD CONSTRAINT fk_rails_4a2e48ca67 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users_roles fk_rails_4a41696df6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT fk_rails_4a41696df6 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_channel_memberships fk_rails_4ba367990a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships
    ADD CONSTRAINT fk_rails_4ba367990a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: html_variants fk_rails_4bb9f66719; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variants
    ADD CONSTRAINT fk_rails_4bb9f66719 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: identities fk_rails_5373344100; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities
    ADD CONSTRAINT fk_rails_5373344100 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: credits fk_rails_5628a713de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credits
    ADD CONSTRAINT fk_rails_5628a713de FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE RESTRICT;


--
-- Name: podcast_ownerships fk_rails_574aee0ec6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_ownerships
    ADD CONSTRAINT fk_rails_574aee0ec6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: organization_memberships fk_rails_57cf70d280; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_memberships
    ADD CONSTRAINT fk_rails_57cf70d280 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ahoy_messages fk_rails_5894d6c55a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_messages
    ADD CONSTRAINT fk_rails_5894d6c55a FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: html_variant_successes fk_rails_58c8775ab2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_successes
    ADD CONSTRAINT fk_rails_58c8775ab2 FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE SET NULL;


--
-- Name: user_subscriptions fk_rails_59b0197af7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT fk_rails_59b0197af7 FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: html_variant_successes fk_rails_5b92043d3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_successes
    ADD CONSTRAINT fk_rails_5b92043d3f FOREIGN KEY (html_variant_id) REFERENCES public.html_variants(id) ON DELETE CASCADE;


--
-- Name: custom_profile_fields fk_rails_701e08633d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_profile_fields
    ADD CONSTRAINT fk_rails_701e08633d FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: organization_memberships fk_rails_715ab7f4fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_memberships
    ADD CONSTRAINT fk_rails_715ab7f4fe FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: sponsorships fk_rails_778bb453b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsorships
    ADD CONSTRAINT fk_rails_778bb453b1 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: articles fk_rails_7809a1a57d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT fk_rails_7809a1a57d FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: webhook_endpoints fk_rails_819fdd0983; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoints
    ADD CONSTRAINT fk_rails_819fdd0983 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: html_variant_trials fk_rails_823a31b2cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_trials
    ADD CONSTRAINT fk_rails_823a31b2cf FOREIGN KEY (html_variant_id) REFERENCES public.html_variants(id) ON DELETE CASCADE;


--
-- Name: poll_votes fk_rails_848ece0184; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_rails_848ece0184 FOREIGN KEY (poll_option_id) REFERENCES public.poll_options(id) ON DELETE CASCADE;


--
-- Name: feedback_messages fk_rails_887c5f31ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_messages
    ADD CONSTRAINT fk_rails_887c5f31ff FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: podcast_episodes fk_rails_893fc9044f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_episodes
    ADD CONSTRAINT fk_rails_893fc9044f FOREIGN KEY (podcast_id) REFERENCES public.podcasts(id) ON DELETE CASCADE;


--
-- Name: classified_listings fk_rails_8ec4e83da0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classified_listings
    ADD CONSTRAINT fk_rails_8ec4e83da0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: credits fk_rails_9001739776; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credits
    ADD CONSTRAINT fk_rails_9001739776 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_blocks fk_rails_9457ce6a10; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT fk_rails_9457ce6a10 FOREIGN KEY (blocked_id) REFERENCES public.users(id);


--
-- Name: poll_skips fk_rails_97ff88c452; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_skips
    ADD CONSTRAINT fk_rails_97ff88c452 FOREIGN KEY (poll_id) REFERENCES public.polls(id) ON DELETE CASCADE;


--
-- Name: api_secrets fk_rails_9aaa384ac8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_secrets
    ADD CONSTRAINT fk_rails_9aaa384ac8 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: collections fk_rails_9b33697360; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT fk_rails_9b33697360 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reactions fk_rails_9f02fc96a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT fk_rails_9f02fc96a0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: taggings fk_rails_9fcd2e236b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT fk_rails_9fcd2e236b FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: ahoy_events fk_rails_a0df956a8d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events
    ADD CONSTRAINT fk_rails_a0df956a8d FOREIGN KEY (visit_id) REFERENCES public.ahoy_visits(id) ON DELETE CASCADE;


--
-- Name: rating_votes fk_rails_a3fec5b316; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rating_votes
    ADD CONSTRAINT fk_rails_a3fec5b316 FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: rating_votes fk_rails_a47bf2c1e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rating_votes
    ADD CONSTRAINT fk_rails_a47bf2c1e2 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: tag_adjustments fk_rails_a49150b7b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_adjustments
    ADD CONSTRAINT fk_rails_a49150b7b2 FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: poll_votes fk_rails_a6e6974b7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_rails_a6e6974b7e FOREIGN KEY (poll_id) REFERENCES public.polls(id) ON DELETE CASCADE;


--
-- Name: response_templates fk_rails_a8702c6917; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.response_templates
    ADD CONSTRAINT fk_rails_a8702c6917 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: tags fk_rails_a9dc141dc9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_a9dc141dc9 FOREIGN KEY (mod_chat_channel_id) REFERENCES public.chat_channels(id) ON DELETE SET NULL;


--
-- Name: poll_options fk_rails_aa85becb42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT fk_rails_aa85becb42 FOREIGN KEY (poll_id) REFERENCES public.polls(id) ON DELETE CASCADE;


--
-- Name: notifications fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_channel_memberships fk_rails_b2bb73e339; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships
    ADD CONSTRAINT fk_rails_b2bb73e339 FOREIGN KEY (chat_channel_id) REFERENCES public.chat_channels(id);


--
-- Name: sponsorships fk_rails_b3190c5fc6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsorships
    ADD CONSTRAINT fk_rails_b3190c5fc6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: poll_votes fk_rails_b64de9b025; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_rails_b64de9b025 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: html_variant_trials fk_rails_ba2bd12f4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.html_variant_trials
    ADD CONSTRAINT fk_rails_ba2bd12f4d FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE SET NULL;


--
-- Name: github_repos fk_rails_bbb82bb7f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_repos
    ADD CONSTRAINT fk_rails_bbb82bb7f1 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: feedback_messages fk_rails_c15ceb2839; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_messages
    ADD CONSTRAINT fk_rails_c15ceb2839 FOREIGN KEY (offender_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: tag_adjustments fk_rails_c4e50e84fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_adjustments
    ADD CONSTRAINT fk_rails_c4e50e84fd FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: display_ad_events fk_rails_c692cbd6e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.display_ad_events
    ADD CONSTRAINT fk_rails_c692cbd6e1 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: display_ads fk_rails_ca571cb23e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.display_ads
    ADD CONSTRAINT fk_rails_ca571cb23e FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: tags fk_rails_d11c10a859; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_d11c10a859 FOREIGN KEY (badge_id) REFERENCES public.badges(id) ON DELETE SET NULL;


--
-- Name: user_blocks fk_rails_d1bf232861; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT fk_rails_d1bf232861 FOREIGN KEY (blocker_id) REFERENCES public.users(id);


--
-- Name: podcast_episode_appearances fk_rails_d9250101ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcast_episode_appearances
    ADD CONSTRAINT fk_rails_d9250101ef FOREIGN KEY (podcast_episode_id) REFERENCES public.podcast_episodes(id);


--
-- Name: badge_achievements fk_rails_da1af2d63c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_achievements
    ADD CONSTRAINT fk_rails_da1af2d63c FOREIGN KEY (rewarder_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: ahoy_visits fk_rails_db648022ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_visits
    ADD CONSTRAINT fk_rails_db648022ad FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: profile_fields fk_rails_df1b1bea83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_fields
    ADD CONSTRAINT fk_rails_df1b1bea83 FOREIGN KEY (profile_field_group_id) REFERENCES public.profile_field_groups(id);


--
-- Name: profiles fk_rails_e424190865; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT fk_rails_e424190865 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: feedback_messages fk_rails_e81fc50c33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_messages
    ADD CONSTRAINT fk_rails_e81fc50c33 FOREIGN KEY (affected_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: tag_adjustments fk_rails_e8f5a32807; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_adjustments
    ADD CONSTRAINT fk_rails_e8f5a32807 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ahoy_messages fk_rails_eb7709e291; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_messages
    ADD CONSTRAINT fk_rails_eb7709e291 FOREIGN KEY (feedback_message_id) REFERENCES public.feedback_messages(id) ON DELETE SET NULL;


--
-- Name: users_roles fk_rails_eb7b4658f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT fk_rails_eb7b4658f8 FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens fk_rails_ee63f25419; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_ee63f25419 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id);


--
-- Name: ahoy_events fk_rails_f1ed9fc4a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events
    ADD CONSTRAINT fk_rails_f1ed9fc4a0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: email_authorizations fk_rails_faf7e663d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_authorizations
    ADD CONSTRAINT fk_rails_faf7e663d1 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: classified_listings fk_rails_fd32b9b45f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classified_listings
    ADD CONSTRAINT fk_rails_fd32b9b45f FOREIGN KEY (classified_listing_category_id) REFERENCES public.classified_listing_categories(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20151224175814'),
('20151224180956'),
('20151226205806'),
('20151231095411'),
('20151231102537'),
('20160101145545'),
('20160101170140'),
('20160104220657'),
('20160104221355'),
('20160104222032'),
('20160104223954'),
('20160104225041'),
('20160105211934'),
('20160111153315'),
('20160115190444'),
('20160120012230'),
('20160124203153'),
('20160124205229'),
('20160125202948'),
('20160126145035'),
('20160126152212'),
('20160128215217'),
('20160129154529'),
('20160131213109'),
('20160131213110'),
('20160131213111'),
('20160131213112'),
('20160131213113'),
('20160131234917'),
('20160201001953'),
('20160201002243'),
('20160201012919'),
('20160201014516'),
('20160202211114'),
('20160202214951'),
('20160203005540'),
('20160203011021'),
('20160203233256'),
('20160206011647'),
('20160211170239'),
('20160214023247'),
('20160226193243'),
('20160304000325'),
('20160304010353'),
('20160304011144'),
('20160309155009'),
('20160310024038'),
('20160317190829'),
('20160317190838'),
('20160318195259'),
('20160322214055'),
('20160323233659'),
('20160324231938'),
('20160329004330'),
('20160401203746'),
('20160418001613'),
('20160428002923'),
('20160503004547'),
('20160505014825'),
('20160510022025'),
('20160517144259'),
('20160517144335'),
('20160518202957'),
('20160525190703'),
('20160525192526'),
('20160602140503'),
('20160610135858'),
('20160610145259'),
('20160610155109'),
('20160703135819'),
('20160713202608'),
('20160726230520'),
('20160801212954'),
('20160809182110'),
('20160810191937'),
('20160819025830'),
('20160905190604'),
('20160908145640'),
('20160908151357'),
('20160926154138'),
('20160926164412'),
('20161013195522'),
('20161018201530'),
('20161124212209'),
('20161208193428'),
('20161211234357'),
('20161212161130'),
('20161213212554'),
('20161216165302'),
('20161219173922'),
('20161223053926'),
('20161226180959'),
('20161228210927'),
('20161229054605'),
('20170105141344'),
('20170110154028'),
('20170110170105'),
('20170119193031'),
('20170127194840'),
('20170206214820'),
('20170206220334'),
('20170208152018'),
('20170209164016'),
('20170213183337'),
('20170216145500'),
('20170228174838'),
('20170302152930'),
('20170303171502'),
('20170303180353'),
('20170309162937'),
('20170310003608'),
('20170317171912'),
('20170325040822'),
('20170330184420'),
('20170330222954'),
('20170403135236'),
('20170411145225'),
('20170502162438'),
('20170505210243'),
('20170517172352'),
('20170521154826'),
('20170523210349'),
('20170524160535'),
('20170531150807'),
('20170531151548'),
('20170602152759'),
('20170607191629'),
('20170610142132'),
('20170613193616'),
('20170615172623'),
('20170615172941'),
('20170616191722'),
('20170619151747'),
('20170620145442'),
('20170620212740'),
('20170622191911'),
('20170626211738'),
('20170627205501'),
('20170706212815'),
('20170711195143'),
('20170717214026'),
('20170718150429'),
('20170718174233'),
('20170719184042'),
('20170719211212'),
('20170725171619'),
('20170727002902'),
('20170727153841'),
('20170802204604'),
('20170804193835'),
('20170809182148'),
('20170821154300'),
('20170828165505'),
('20170829164950'),
('20170829190632'),
('20170831180005'),
('20170831200650'),
('20170905170750'),
('20170912012249'),
('20170920160022'),
('20170921205230'),
('20170921221837'),
('20171002180944'),
('20171002195852'),
('20171003191547'),
('20171003222833'),
('20171004025750'),
('20171012215224'),
('20171013180013'),
('20171019152130'),
('20171019215638'),
('20171020160338'),
('20171024171916'),
('20171024193812'),
('20171026214850'),
('20171030214855'),
('20171103165851'),
('20171104014225'),
('20171106203902'),
('20171110215815'),
('20171110223810'),
('20171116191214'),
('20171116203319'),
('20171204171217'),
('20171229192205'),
('20180103183451'),
('20180107004333'),
('20180110012012'),
('20180111170406'),
('20180115221125'),
('20180130192627'),
('20180131183322'),
('20180202171402'),
('20180208210732'),
('20180209174729'),
('20180210161930'),
('20180212153228'),
('20180213165354'),
('20180303210932'),
('20180304151124'),
('20180316143921'),
('20180316164921'),
('20180316174324'),
('20180321170500'),
('20180328194237'),
('20180328194253'),
('20180427160903'),
('20180502152520'),
('20180502152621'),
('20180502160428'),
('20180502174301'),
('20180502213919'),
('20180507191509'),
('20180508165244'),
('20180508170132'),
('20180508200948'),
('20180516173047'),
('20180516184437'),
('20180522195341'),
('20180531194107'),
('20180601145801'),
('20180601195848'),
('20180603160906'),
('20180604200603'),
('20180606155327'),
('20180608195204'),
('20180609191539'),
('20180612214259'),
('20180622173538'),
('20180624230435'),
('20180629201047'),
('20180703142743'),
('20180705194536'),
('20180707162348'),
('20180713180709'),
('20180716182629'),
('20180728201801'),
('20180806142338'),
('20180816165158'),
('20180821204032'),
('20180824191849'),
('20180826174411'),
('20180905013458'),
('20180924201325'),
('20180924204406'),
('20180928161837'),
('20180930015157'),
('20181001225906'),
('20181003173949'),
('20181005180705'),
('20181005200827'),
('20181008174839'),
('20181010204910'),
('20181016181008'),
('20181019195746'),
('20181020195949'),
('20181020195954'),
('20181026112019'),
('20181026214021'),
('20181111040732'),
('20181116223239'),
('20181117145537'),
('20181120170350'),
('20181127173004'),
('20181129222416'),
('20181130224531'),
('20181219215401'),
('20181227192353'),
('20190109212351'),
('20190115155656'),
('20190121172642'),
('20190121191754'),
('20190129173611'),
('20190129190135'),
('20190206164319'),
('20190206222055'),
('20190216185753'),
('20190227163543'),
('20190227163803'),
('20190305221008'),
('20190306082543'),
('20190315151829'),
('20190315222044'),
('20190318223433'),
('20190326085046'),
('20190327090030'),
('20190329103059'),
('20190401100844'),
('20190401100850'),
('20190401193017'),
('20190401213605'),
('20190402224426'),
('20190404102732'),
('20190405190915'),
('20190409123750'),
('20190410124957'),
('20190412093614'),
('20190415194929'),
('20190417171019'),
('20190417171020'),
('20190420000607'),
('20190425210432'),
('20190430123156'),
('20190501141654'),
('20190501180125'),
('20190501191830'),
('20190502165056'),
('20190504015859'),
('20190504131412'),
('20190521190118'),
('20190524214445'),
('20190525233909'),
('20190525233918'),
('20190525233934'),
('20190531085252'),
('20190531094609'),
('20190531094926'),
('20190603190201'),
('20190606202826'),
('20190607110030'),
('20190611102309'),
('20190611102923'),
('20190611144112'),
('20190611195955'),
('20190612095748'),
('20190612095959'),
('20190612174127'),
('20190614093041'),
('20190616024727'),
('20190616053854'),
('20190617101811'),
('20190617102149'),
('20190619153428'),
('20190624093012'),
('20190625143841'),
('20190626022355'),
('20190626221336'),
('20190628123548'),
('20190702194019'),
('20190703003817'),
('20190704082551'),
('20190704091636'),
('20190704105143'),
('20190705111810'),
('20190705114625'),
('20190708105607'),
('20190709192214'),
('20190710081915'),
('20190711070019'),
('20190711093610'),
('20190713213412'),
('20190713225409'),
('20190717220437'),
('20190717224405'),
('20190723094834'),
('20190801083510'),
('20190801132654'),
('20190818191954'),
('20190819104106'),
('20190822162434'),
('20190827163358'),
('20190906193806'),
('20190910153845'),
('20190918104106'),
('20190925171050'),
('20190925193205'),
('20191016135034'),
('20191025185619'),
('20191025202354'),
('20191031131016'),
('20191106095242'),
('20191106102826'),
('20191108153914'),
('20191203114809'),
('20191203160028'),
('20191203171558'),
('20191210144342'),
('20191215145706'),
('20191220120243'),
('20191223202251'),
('20191226202114'),
('20191227113154'),
('20191227114543'),
('20200106074859'),
('20200117135558'),
('20200117135902'),
('20200119214529'),
('20200120053525'),
('20200125204226'),
('20200205225813'),
('20200211192415'),
('20200212164359'),
('20200213182938'),
('20200221170905'),
('20200221184007'),
('20200222164815'),
('20200224153122'),
('20200225104037'),
('20200226081611'),
('20200226192145'),
('20200226205549'),
('20200226210111'),
('20200227214321'),
('20200303222558'),
('20200304164719'),
('20200304220534'),
('20200308144606'),
('20200311170959'),
('20200324113133'),
('20200324170819'),
('20200326110404'),
('20200326111645'),
('20200329103305'),
('20200331155903'),
('20200403203054'),
('20200405103927'),
('20200407081312'),
('20200407083405'),
('20200407083732'),
('20200407084807'),
('20200407090218'),
('20200407090914'),
('20200407091449'),
('20200409043946'),
('20200409050122'),
('20200411085952'),
('20200412194408'),
('20200420130910'),
('20200426124118'),
('20200427094852'),
('20200427233631'),
('20200501032629'),
('20200504075409'),
('20200511224704'),
('20200514162708'),
('20200514163014'),
('20200514212601'),
('20200515085746'),
('20200519220213'),
('20200520091835'),
('20200520092247'),
('20200520092613'),
('20200520092938'),
('20200520092951'),
('20200521103848'),
('20200521103911'),
('20200521103935'),
('20200521103952'),
('20200521153435'),
('20200525115740'),
('20200525120420'),
('20200525120642'),
('20200525125611'),
('20200526144234'),
('20200526145731'),
('20200526151431'),
('20200526151807'),
('20200527161505'),
('20200530084533'),
('20200601121243'),
('20200602174329'),
('20200604133925'),
('20200605170430'),
('20200605183117'),
('20200608175130'),
('20200609191943'),
('20200609192545'),
('20200609195523'),
('20200612140153'),
('20200615213003'),
('20200616200005'),
('20200617014320'),
('20200617014509'),
('20200617183058'),
('20200618212422'),
('20200702143618'),
('20200706184804'),
('20200707170245'),
('20200707173316'),
('20200707173524'),
('20200710174257'),
('20200712150048'),
('20200716125857'),
('20200717203432'),
('20200717220654'),
('20200719205123'),
('20200720143134'),
('20200720213710'),
('20200721213341'),
('20200723180841'),
('20200723203155'),
('20200725215546'),
('20200726215928'),
('20200727052235'),
('20200727163200'),
('20200731033002'),
('20200731041554'),
('20200803193841'),
('20200804035648'),
('20200805050048'),
('20200805100552'),
('20200805102249'),
('20200806052718'),
('20200806193438'),
('20200809200631'),
('20200811044202'),
('20200813031851'),
('20200813042118'),
('20200814142425'),
('20200814142648'),
('20200817205048'),
('20200818101637'),
('20200818101700'),
('20200818163445'),
('20200818163834'),
('20200818202007'),
('20200819162917'),
('20200820055018'),
('20200820093731'),
('20200820093752'),
('20200821035520'),
('20200822092853'),
('20200826072259'),
('20200826072722'),
('20200826131359'),
('20200826132009'),
('20200826132639'),
('20200827073520'),
('20200828032013'),
('20200828045600'),
('20200901084210'),
('20200902132326'),
('20200902204028'),
('20200904040009'),
('20200904151734'),
('20200910155145'),
('20200910205316'),
('20200911140318'),
('20200914143753'),
('20200914144033'),
('20200914144157'),
('20200914145500'),
('20200917114525'),
('20200917141134'),
('20200917141154'),
('20200917154147'),
('20200917154234'),
('20200917154256'),
('20200917154306'),
('20200918200231'),
('20200921160153'),
('20201001154006'),
('20201002102257'),
('20201002102303'),
('20201002104711'),
('20201005181510'),
('20201007085440'),
('20201007091041'),
('20201009040438'),
('20201012072557'),
('20201017160628'),
('20201019012200'),
('20201107111600'),
('20201114130315'),
('20201114151157'),
('20201119153512'),
('20201203063435'),
('20201208195636'),
('20201221024151'),
('20201221033646'),
('20201222070116'),
('20210105183127'),
('20210108031718'),
('20210111045049'),
('20210111151630'),
('20210120192313'),
('20210121102114'),
('20210125085442'),
('20210129074823'),
('20210131000458'),
('20210201055410'),
('20210216023520'),
('20210219043102'),
('20210304195203'),
('20210310154630'),
('20210312095649'),
('20210312191925'),
('20210319185315'),
('20210322152837'),
('20210323190443'),
('20210324031252'),
('20210324031738'),
('20210325040245'),
('20210325183834'),
('20210326155612'),
('20210326160257'),
('20210326172446'),
('20210329141442'),
('20210329164447');


