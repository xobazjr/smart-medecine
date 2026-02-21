import { createClient } from '@supabase/supabase-js'

// IMPORTANT: Make sure you have these in your .env.local file!
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseKey) {
  throw new Error("Missing Supabase URL or Anon Key. Make sure to set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in your .env.local file.");
}

export const supabase = createClient(supabaseUrl, supabaseKey)
