-- Stores per-user Discogs OAuth access tokens (written by Edge Functions via service_role)
CREATE TABLE public.discogs_tokens (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  discogs_username TEXT NOT NULL,
  discogs_user_id BIGINT,
  access_token TEXT NOT NULL,
  access_token_secret TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Temporary storage for OAuth 1.0a request tokens during the authorization flow
CREATE TABLE public.discogs_oauth_temp (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  request_token TEXT NOT NULL,
  request_token_secret TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS: users can only read their own tokens (Edge Functions write via service_role)
ALTER TABLE public.discogs_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discogs_oauth_temp ENABLE ROW LEVEL SECURITY;

CREATE POLICY discogs_tokens_select ON public.discogs_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY discogs_tokens_delete ON public.discogs_tokens
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY discogs_oauth_temp_select ON public.discogs_oauth_temp
  FOR SELECT USING (auth.uid() = user_id);
