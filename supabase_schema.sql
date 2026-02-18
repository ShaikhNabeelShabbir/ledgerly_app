-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create Parties Table
create table public.parties (
  id uuid primary key default uuid_generate_v4(),
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
  party_id uuid references public.parties(id) on delete cascade not null,
  description text,
  amount numeric not null,
  transaction_type text check (transaction_type in ('credit', 'debit')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Insert Dummy Data for Parties
insert into public.parties (name, avatar_text, amount, status, due_date) values
('Acme Corp', 'AC', 2500, 'Unpaid', '2023-10-30 00:00:00+00'),
('Tech Solutions', 'TS', 1200, 'Overdue', '2023-10-20 00:00:00+00'),
('John Doe', 'JD', 500, 'Paid', '2023-10-22 00:00:00+00');
