import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { generateOAuthHeader } from "../_shared/oauth.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const consumerKey = Deno.env.get("DISCOGS_CONSUMER_KEY")!;
    const consumerSecret = Deno.env.get("DISCOGS_CONSUMER_SECRET")!;

    // Verify user
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Read oauth_token + oauth_verifier from request body
    const { oauth_token, oauth_verifier } = await req.json();
    if (!oauth_token || !oauth_verifier) {
      return new Response(
        JSON.stringify({ error: "Missing oauth_token or oauth_verifier" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Look up request_token_secret from temp table
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);
    const { data: tempRow, error: tempError } = await adminClient
      .from("discogs_oauth_temp")
      .select("request_token_secret")
      .eq("user_id", user.id)
      .eq("request_token", oauth_token)
      .single();

    if (tempError || !tempRow) {
      return new Response(
        JSON.stringify({ error: "No matching request token found. Please restart the OAuth flow." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Exchange for access token
    const accessTokenUrl = "https://api.discogs.com/oauth/access_token";
    const oauthHeader = generateOAuthHeader(
      "POST",
      accessTokenUrl,
      consumerKey,
      consumerSecret,
      oauth_token,
      tempRow.request_token_secret,
      { oauth_verifier },
    );

    const response = await fetch(accessTokenUrl, {
      method: "POST",
      headers: {
        "Authorization": oauthHeader,
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Needl/1.0",
      },
    });

    if (!response.ok) {
      const body = await response.text();
      return new Response(
        JSON.stringify({ error: "Discogs access token exchange failed", details: body }),
        { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = await response.text();
    const params = new URLSearchParams(body);
    const accessToken = params.get("oauth_token");
    const accessTokenSecret = params.get("oauth_token_secret");

    if (!accessToken || !accessTokenSecret) {
      return new Response(
        JSON.stringify({ error: "Invalid access token response from Discogs" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Get identity (username) from Discogs
    const identityUrl = "https://api.discogs.com/oauth/identity";
    const identityHeader = generateOAuthHeader(
      "GET",
      identityUrl,
      consumerKey,
      consumerSecret,
      accessToken,
      accessTokenSecret,
    );

    const identityResponse = await fetch(identityUrl, {
      headers: {
        "Authorization": identityHeader,
        "User-Agent": "Needl/1.0",
      },
    });

    let discogsUsername = "";
    let discogsUserId: number | null = null;
    if (identityResponse.ok) {
      const identity = await identityResponse.json();
      discogsUsername = identity.username || "";
      discogsUserId = identity.id || null;
    }

    // Upsert access tokens into discogs_tokens
    const { error: upsertError } = await adminClient
      .from("discogs_tokens")
      .upsert({
        user_id: user.id,
        discogs_username: discogsUsername,
        discogs_user_id: discogsUserId,
        access_token: accessToken,
        access_token_secret: accessTokenSecret,
      });

    if (upsertError) {
      return new Response(
        JSON.stringify({ error: "Failed to store access token", details: upsertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Delete temp row
    await adminClient
      .from("discogs_oauth_temp")
      .delete()
      .eq("user_id", user.id);

    return new Response(
      JSON.stringify({ discogs_username: discogsUsername }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
