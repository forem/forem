import querystring;
sub vcl_recv {
    # return this URL with only the parameters that match this regular expression
    if (req.url !~ "/admin/" && req.url !~ "/search/" && req.url !~ "/bulk_show") {
      set req.url = querystring.regfilter_except(req.url, "^(a_id|args|article_id|article_ids|articles|asc|callback_url|category|chat_channel_id|client_id|code|collection_id|commentable_id|commentable_type|confirmation_token|created_at|end|email|filter|followable_id|followable_type|forem_owner_secret|fork_id|i|key|message_offset|name|oauth_token|oauth_verifier|offset|onboarding|org_id|organization_id|p|page|per_page|p_id|prefill|preview|purchaser|q|reactable_ids|redirect_uri|reported_url|reporter_username|response_type|scope|search|signature|sort|source_id|source_type|start|state|status|tag|tag_list|top|type_of|url|username|invitation_token|reset_password_token|ut|verb|invitation_slug)$");
    }
}
