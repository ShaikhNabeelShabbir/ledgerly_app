-- 1. Create Profiles Table (for Business Name, Cash, Bank)
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  business_name text default 'Global Traders',
  cash_in_hand numeric default 0,
  bank_balance numeric default 0,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for Profiles
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- 2. Add 'party_type' to parties table (Customer vs Supplier)
alter table public.parties 
add column if not exists party_type text check (party_type in ('Customer', 'Supplier')) default 'Customer';

-- 3. (Optional) Trigger to create profile on user signup
-- You can run this if you want auto-creation, otherwise the app will handle it.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, business_name, cash_in_hand, bank_balance)
  values (new.id, 'My Business', 0, 0);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
