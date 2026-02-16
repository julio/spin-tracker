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

    // Read request: { method, path, query? }
    const { method: apiMethod, path, query } = await req.json();
    if (!path) {
      return new Response(
        JSON.stringify({ error: "Missing path parameter" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Look up user's tokens
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);
    const { data: tokens, error: tokensError } = await adminClient
      .from("discogs_tokens")
      .select("access_token, access_token_secret")
      .eq("user_id", user.id)
      .single();

    if (tokensError || !tokens) {
      return new Response(
        JSON.stringify({ error: "Discogs account not connected" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Build target URL
    let targetUrl = `https://api.discogs.com${path}`;
    if (query) {
      const separator = targetUrl.includes("?") ? "&" : "?";
      targetUrl += `${separator}${query}`;
    }

    const httpMethod = (apiMethod || "GET").toUpperCase();

    // Sign request with OAuth
    const oauthHeader = generateOAuthHeader(
      httpMethod,
      targetUrl,
      consumerKey,
      consumerSecret,
      tokens.access_token,
      tokens.access_token_secret,
    );

    // Forward to Discogs
    const discogsResponse = await fetch(targetUrl, {
      method: httpMethod,
      headers: {
        "Authorization": oauthHeader,
        "User-Agent": "Needl/1.0",
        "Content-Type": "application/json",
      },
    });

    const responseBody = await discogsResponse.text();

    return new Response(responseBody, {
      status: discogsResponse.status,
      headers: {
        ...corsHeaders,
        "Content-Type": discogsResponse.headers.get("Content-Type") || "application/json",
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
