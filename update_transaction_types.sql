-- 1. Drop the existing constraint on transaction_type
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_transaction_type_check;

-- 2. Add the new constraint allowing the new types
ALTER TABLE public.transactions ADD CONSTRAINT transactions_transaction_type_check 
  CHECK (transaction_type IN ('Got', 'Gave', 'To Receive', 'To Give'));

-- 3. Update the trigger function for Party Balances to handle the new types
CREATE OR REPLACE FUNCTION update_party_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- If inserting a new transaction
  IF TG_OP = 'INSERT' THEN
    IF NEW.transaction_type = 'Got' THEN
      UPDATE public.parties SET amount = amount - NEW.amount WHERE id = NEW.party_id;
    ELSIF NEW.transaction_type = 'Gave' THEN
      UPDATE public.parties SET amount = amount + NEW.amount WHERE id = NEW.party_id;
    ELSIF NEW.transaction_type = 'To Receive' THEN
      UPDATE public.parties SET amount = amount + NEW.amount WHERE id = NEW.party_id;
    ELSIF NEW.transaction_type = 'To Give' THEN
      UPDATE public.parties SET amount = amount - NEW.amount WHERE id = NEW.party_id;
    END IF;
    
  -- If deleting a transaction
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.transaction_type = 'Got' THEN
      UPDATE public.parties SET amount = amount + OLD.amount WHERE id = OLD.party_id;
    ELSIF OLD.transaction_type = 'Gave' THEN
      UPDATE public.parties SET amount = amount - OLD.amount WHERE id = OLD.party_id;
    ELSIF OLD.transaction_type = 'To Receive' THEN
      UPDATE public.parties SET amount = amount - OLD.amount WHERE id = OLD.party_id;
    ELSIF OLD.transaction_type = 'To Give' THEN
      UPDATE public.parties SET amount = amount + OLD.amount WHERE id = OLD.party_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- The update_profile_balance trigger does not need changes because
-- 'To Receive' and 'To Give' are credit transactions and do not affect Cash or Bank.
-- It already safely ignores any type that is not 'Got' or 'Gave'.
