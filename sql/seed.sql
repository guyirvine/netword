INSERT INTO word_tbl( name ) VALUES ( 'Governance' );
INSERT INTO word_tbl( name ) VALUES ( 'Contextual Consistency' );
INSERT INTO word_tbl( name, url ) VALUES ( 'Dan North', 'http://dannorth.net/' );
INSERT INTO word_tbl( name ) VALUES ( 'Author' );

INSERT INTO link_tbl( word_1, word_2 ) VALUES ( 1, 2 );

INSERT INTO link_tbl( word_1, word_2 ) VALUES ( 3, 1 );
INSERT INTO link_tbl( word_1, word_2 ) VALUES ( 3, 2 );

INSERT INTO link_tbl( word_1, word_2 ) VALUES ( 4, 3 );
