-- Run this script in your Supabase SQL Editor to clean up the 'status' column

-- 1. If any policies referenced 'status' (which they shouldn't have based on previous scripts), 
-- you would drop them here, but we can safely proceed to column deletion.

-- 2. Drop the 'status' column from the 'parties' table
ALTER TABLE public.parties DROP COLUMN IF EXISTS status;

-- 3. The column is successfully deleted! No trace left.
