-- 1. Modify the existing Transactions table to include payment mode (Cash/Bank) and specific types
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS payment_mode TEXT CHECK (payment_mode IN ('Cash', 'Bank', 'None')) DEFAULT 'None';

-- Update transaction_type constraint to be more descriptive for a ledger
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_transaction_type_check;
ALTER TABLE public.transactions
ADD CONSTRAINT transactions_transaction_type_check CHECK (transaction_type IN ('Got', 'Gave'));

-- 2. Create the Trigger to auto-update Party Balances (amount column) whenever a transaction is added/deleted
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

-- Drop trigger if it exists and recreate
DROP TRIGGER IF EXISTS transaction_update_party ON public.transactions;
CREATE TRIGGER transaction_update_party
AFTER INSERT OR DELETE ON public.transactions
FOR EACH ROW EXECUTE PROCEDURE update_party_balance();

-- 3. Create the Trigger to auto-update Profile (Cash/Bank) Cash book balances
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

-- Drop trigger if it exists and recreate
DROP TRIGGER IF EXISTS transaction_update_profile ON public.transactions;
CREATE TRIGGER transaction_update_profile
AFTER INSERT OR DELETE ON public.transactions
FOR EACH ROW EXECUTE PROCEDURE update_profile_balance();
