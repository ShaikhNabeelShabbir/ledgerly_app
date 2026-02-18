-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create Parties Table
create table public.parties (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  name text not null,
  avatar_text text,
  amount numeric default 0,
  status text check (status in ('Paid', 'Unpaid', 'Overdue')),
  due_date timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create Transactions Table
create table public.transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  party_id uuid references public.parties(id) on delete cascade not null,
  description text,
  amount numeric not null,
  transaction_type text check (transaction_type in ('credit', 'debit')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.parties enable row level security;
alter table public.transactions enable row level security;

-- Create Policies for Parties
create policy "Users can view their own parties"
  on public.parties for select
  using (auth.uid() = user_id);

create policy "Users can insert their own parties"
  on public.parties for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own parties"
  on public.parties for update
  using (auth.uid() = user_id);

create policy "Users can delete their own parties"
  on public.parties for delete
  using (auth.uid() = user_id);

-- Create Policies for Transactions
create policy "Users can view their own transactions"
  on public.transactions for select
  using (auth.uid() = user_id);

create policy "Users can insert their own transactions"
  on public.transactions for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own transactions"
  on public.transactions for update
  using (auth.uid() = user_id);

create policy "Users can delete their own transactions"
  on public.transactions for delete
  using (auth.uid() = user_id);
