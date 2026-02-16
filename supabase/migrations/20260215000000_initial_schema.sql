-- profiles (auto-created on signup via trigger)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  discogs_token TEXT,
  discogs_username TEXT,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- owned_albums
CREATE TABLE public.owned_albums (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artist TEXT NOT NULL,
  album TEXT NOT NULL,
  release_date TEXT NOT NULL DEFAULT '',
  discogs_id BIGINT,
  discogs_instance_id BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- wanted_albums
CREATE TABLE public.wanted_albums (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artist TEXT NOT NULL,
  album TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique indexes to prevent duplicates per user
CREATE UNIQUE INDEX idx_owned_unique ON public.owned_albums (user_id, lower(artist), lower(album), release_date);
CREATE UNIQUE INDEX idx_wanted_unique ON public.wanted_albums (user_id, lower(artist), lower(album));

-- Performance indexes
CREATE INDEX idx_owned_user ON public.owned_albums (user_id);
CREATE INDEX idx_wanted_user ON public.wanted_albums (user_id);

-- RLS policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.owned_albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wanted_albums ENABLE ROW LEVEL SECURITY;

-- profiles: users can read/update their own profile
CREATE POLICY profiles_select ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY profiles_update ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- owned_albums: full CRUD scoped to own user
CREATE POLICY owned_select ON public.owned_albums FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY owned_insert ON public.owned_albums FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY owned_update ON public.owned_albums FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY owned_delete ON public.owned_albums FOR DELETE USING (auth.uid() = user_id);

-- wanted_albums: full CRUD scoped to own user
CREATE POLICY wanted_select ON public.wanted_albums FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY wanted_insert ON public.wanted_albums FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY wanted_update ON public.wanted_albums FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY wanted_delete ON public.wanted_albums FOR DELETE USING (auth.uid() = user_id);

-- Trigger: auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
