CREATE SEQUENCE word_seq;
CREATE SEQUENCE link_seq;

CREATE TABLE word_tbl (
  id BIGINT NOT NULL DEFAULT NEXTVAL( 'word_seq' ) PRIMARY KEY,
  name VARCHAR NOT NULL,
  description VARCHAR,
  url VARCHAR,
  createdat TIMESTAMP DEFAULT NOW()
);

CREATE TABLE link_tbl (
  id BIGINT NOT NULL DEFAULT NEXTVAL( 'link_seq' ) PRIMARY KEY,
  word_1 BIGINT NOT NULL,
  word_2 BIGINT NOT NULL,
  createdat TIMESTAMP DEFAULT NOW(),
  CONSTRAINT link_word_1_fk FOREIGN KEY ( word_1 ) REFERENCES word_tbl( id ),
  CONSTRAINT link_word_2_fk FOREIGN KEY ( word_2 ) REFERENCES word_tbl( id )
);
