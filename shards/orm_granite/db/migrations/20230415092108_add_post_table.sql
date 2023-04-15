-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
create table posts (id integer primary key, name text, body text not null);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
drop table posts;
