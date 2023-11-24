drop database if exists arj;
create database arj;

-- Root permissions
create user if not exists 'root'@'%' identified by 'root';
grant usage on *.* to 'root'@'%';
grant all privileges on *.* to 'root'@'%';

flush privileges;
