// ============================================================
// Hosneara Transport Agency — Supabase Config
// এখানে তোমার Supabase প্রজেক্টের URL আর anon key বসাও।
// Supabase Dashboard → Project Settings → API থেকে পাবে।
// ============================================================

const SUPABASE_URL = "https://tgjyqadskmopvbdqaybi.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRnanlxYWRza21vcHZiZHFheWJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxNzAwMjIsImV4cCI6MjA5OTc0NjAyMn0.dFI-L9K8hxQxLrLpvYw9Pbr19RtaTyet-04dm7SggEk";

// গ্লোবালি অ্যাক্সেসযোগ্য supabase client — সব পেজে এটাই ব্যবহার হবে
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
