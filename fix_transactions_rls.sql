-- 1. Make sure the Transactions table is created with all the required columns
CREATE TABLE IF NOT EXISTS public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  party_id uuid references public.parties(id) on delete cascade not null,
  description text,
  amount numeric not null,
  transaction_type text check (transaction_type in ('Got', 'Gave', 'credit', 'debit')),
  payment_mode text check (payment_mode in ('Cash', 'Bank', 'None')) default 'None',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Ensure Row Level Security (RLS) is enabled
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies to prevent conflicts, then re-create them properly
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can insert their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can update their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can delete their own transactions" ON public.transactions;

CREATE POLICY "Users can view their own transactions"
  ON public.transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own transactions"
  ON public.transactions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own transactions"
  ON public.transactions FOR DELETE
  USING (auth.uid() = user_id);

-- 4. Create the Trigger to auto-update Party Balances
CREATE OR REPLACE FUNCTION update_party_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- If inserting a new transaction
  IF TG_OP = 'INSERT' THEN
    IF NEW.transaction_type = 'Got' THEN
      UPDATE public.parties SET amount = amount - NEW.amount WHERE id = NEW.party_id;
    ELSIF NEW.transaction_type = 'Gave' THEN
      UPDATE public.parties SET amount = amount + NEW.amount WHERE id = NEW.party_id;
    END IF;
    
  -- If deleting a transaction
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.transaction_type = 'Got' THEN
      UPDATE public.parties SET amount = amount + OLD.amount WHERE id = OLD.party_id;
    ELSIF OLD.transaction_type = 'Gave' THEN
      UPDATE public.parties SET amount = amount - OLD.amount WHERE id = OLD.party_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS transaction_update_party ON public.transactions;
CREATE TRIGGER transaction_update_party
AFTER INSERT OR DELETE ON public.transactions
FOR EACH ROW EXECUTE PROCEDURE update_party_balance();

-- 5. Create the Trigger to auto-update Profile (Cash/Bank) Cash book balances
CREATE OR REPLACE FUNCTION update_profile_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.transaction_type = 'Got' THEN
      IF NEW.payment_mode = 'Cash' THEN
        UPDATE public.profiles SET cash_in_hand = cash_in_hand + NEW.amount WHERE id = NEW.user_id;
      ELSIF NEW.payment_mode = 'Bank' THEN
        UPDATE public.profiles SET bank_balance = bank_balance + NEW.amount WHERE id = NEW.user_id;
      END IF;
    ELSIF NEW.transaction_type = 'Gave' THEN
      IF NEW.payment_mode = 'Cash' THEN
        UPDATE public.profiles SET cash_in_hand = cash_in_hand - NEW.amount WHERE id = NEW.user_id;
      ELSIF NEW.payment_mode = 'Bank' THEN
        UPDATE public.profiles SET bank_balance = bank_balance - NEW.amount WHERE id = NEW.user_id;
      END IF;
    END IF;
    
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.transaction_type = 'Got' THEN
      IF OLD.payment_mode = 'Cash' THEN
        UPDATE public.profiles SET cash_in_hand = cash_in_hand - OLD.amount WHERE id = OLD.user_id;
      ELSIF OLD.payment_mode = 'Bank' THEN
        UPDATE public.profiles SET bank_balance = bank_balance - OLD.amount WHERE id = OLD.user_id;
      END IF;
    ELSIF OLD.transaction_type = 'Gave' THEN
      IF OLD.payment_mode = 'Cash' THEN
        UPDATE public.profiles SET cash_in_hand = cash_in_hand + OLD.amount WHERE id = OLD.user_id;
      ELSIF OLD.payment_mode = 'Bank' THEN
        UPDATE public.profiles SET bank_balance = bank_balance + OLD.amount WHERE id = OLD.user_id;
      END IF;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS transaction_update_profile ON public.transactions;
CREATE TRIGGER transaction_update_profile
AFTER INSERT OR DELETE ON public.transactions
FOR EACH ROW EXECUTE PROCEDURE update_profile_balance();
