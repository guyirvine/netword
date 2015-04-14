dropdb netword
createdb netword
psql -f create_tables.sql netword
psql -f seed.sql netword
