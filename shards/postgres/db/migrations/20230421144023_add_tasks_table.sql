-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
create table tasks(id serial primary key, title text not null, description text, completed boolean default false, completed_at timestamp);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
drop table tasks;
