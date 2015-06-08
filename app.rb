require 'sinatra'
require 'sinatra/cross_origin'

require 'FluidDb'
require 'json'
require 'diplomat'

configure do
  enable :cross_origin
end

before do
  faraday = Faraday.new(:url => 'http://consul.service.consul:8500', :proxy => '')
  kv = Diplomat::Kv.new(faraday)
  @networddb = FluidDb::Db(kv.get('netword-db'))
end

after do
  @networddb.close
end

helpers do
  def insert_accesslog(db, key, word_id)
    sql = "INSERT INTO accesslog_tbl( id, key, word_id, accessedat ) VALUES ( NEXTVAL( 'accesslog_seq' ), ?, ?, NOW() )"
    db.execute(sql, [key, word_id])
  end

  def insert_accesslog_rst(db, key, rst)
    rst.each do |row|
      insert_accesslog(db, key, row['id'].to_i)
    end
  end

  def get_children(db, id)
    sql = 'SELECT w1.id, l1.id AS link_id ' \
          'FROM word_tbl w1 ' \
          '  INNER JOIN link_tbl l1 ON ( w1.id = l1.word_1 ) ' \
          'WHERE l1.word_2 = ? ' \
          'UNION ' \
          'SELECT w2.id, l2.id AS link_id ' \
          'FROM word_tbl w2 ' \
          '  INNER JOIN link_tbl l2 ON ( w2.id = l2.word_2 ) ' \
          'WHERE l2.word_1 = ? ' \
          ''

    rst = db.queryForResultset(sql, [id, id])
    insert_accesslog_rst(db, 'children', rst)
    rst
  end

  def get_word(db, id)
    sql = 'SELECT w.id, w.name, w.url, w.tagged, w.showlevels ' \
          'FROM word_tbl w ' \
          'WHERE w.id = ? ' \
          ''

    row = db.queryForArray(sql, [id])
    insert_accesslog(db, 'get_word', id)

    row
  end

  def get_descendents(db, depth, id, ids)
    el = get_word(db, id)
    el['depth'] = depth
    el['children'] = []
    get_children(db, id).each do |row|
      child_id = row['id'].to_i
      next if ids.include?(child_id)
      ids.push child_id
      child, ids = get_descendents(db, depth + 1, child_id, ids)
      child['link_id'] = row['link_id']
      el['children'].push child
    end
    [el, ids]
  end
end

get '/' do
  send_file settings.public_folder + '/index.htm'
end

get '/word/:id' do
  db = @networddb

  c = params[:id].to_i
  sql = 'SELECT w.id, w.name, w.url, w.tagged, w.showlevels FROM word_tbl w WHERE w.id = ?'
  arr = db.queryForArray(sql, [c])
  insert_accesslog(db, 'word', c)

  return arr.to_json
end

post '/delete/:id' do
  db = @networddb
  db.execute('DELETE FROM link_tbl WHERE word_1 = ?', [params[:id]])
  db.execute('DELETE FROM link_tbl WHERE word_2 = ?', [params[:id]])
  db.execute('DELETE FROM accesslog_tbl WHERE word_id = ?', [params[:id]])
  db.execute('DELETE FROM word_tbl WHERE id = ?', [params[:id]])

end

post '/deletelink/:id' do
  db = @networddb
  db.execute('DELETE FROM link_tbl WHERE id = ?', [params[:id]])

end

post '/tag/:id' do
  db = @networddb
  db.execute('UPDATE word_tbl SET tagged = true WHERE id = ?', [params[:id]])

end

post '/untag/:id' do
  db = @networddb
  db.execute('UPDATE word_tbl SET tagged = false WHERE id = ?', [params[:id]])

end

post '/singlelevel/:id' do
  db = @networddb
  db.execute('UPDATE word_tbl SET showlevels = 1 WHERE id = ?', [params[:id]])

end

post '/multilevel/:id' do
  db = @networddb
  db.execute('UPDATE word_tbl SET showlevels = 2 WHERE id = ?', [params[:id]])

end

post '/word' do
  db = @networddb

  request.body.rewind
  word = request.body.read

  sql = 'INSERT INTO word_tbl( name ) VALUES ( ? )'
  db.execute(sql, [word])

  id = db.queryForValue("SELECT CURRVAL( 'word_seq' )")



  return id
end

post '/link' do
  db = @networddb

  request.body.rewind
  data = JSON.parse request.body.read

  sql = 'INSERT INTO link_tbl( word_1, word_2 ) VALUES ( ?, ? )'
  db.execute(sql, [data['word_1'], data['word_2']])

  id = db.queryForValue("SELECT CURRVAL( 'link_seq' )")



  return id
end

get '/search/:criteria' do
  db = @networddb

  c = "%#{params[:criteria]}%".upcase
  sql = 'SELECT id, name, url FROM word_tbl WHERE UPPER(name) LIKE ?'
  rst = db.queryForResultset(sql, [c])
  insert_accesslog_rst(db, 'search', rst)



  return rst.to_json
end

get '/link/:parentid' do
  db = @networddb

  c = params[:parentid].to_i
  sql = 'SELECT l1.word_1 AS id ' \
        'FROM link_tbl l1 ' \
        'WHERE l1.word_2 = ? ' \
        'UNION ' \
        'SELECT l2.word_2 AS id ' \
        'FROM link_tbl l2 ' \
        'WHERE l2.word_1 = ? ' \
        ''

  rst = db.queryForResultset(sql, [c, c])
  insert_accesslog_rst(db, 'link', rst)



  return rst.to_json
end

get '/children/:parentid' do
  db = @networddb

  c = params[:parentid].to_i
  sql = 'SELECT l1.id As link_id, w1.id, w1.name, w1.url ' \
        'FROM word_tbl w1 ' \
        '  INNER JOIN link_tbl l1 ON ( w1.id = l1.word_1 ) ' \
        'WHERE l1.word_2 = ? ' \
        'UNION ' \
        'SELECT l2.id As link_id, w2.id, w2.name, w2.url ' \
        'FROM word_tbl w2 ' \
        '  INNER JOIN link_tbl l2 ON ( w2.id = l2.word_2 ) ' \
        'WHERE l2.word_1 = ? ' \
        ''

  rst = db.queryForResultset(sql, [c, c])
  insert_accesslog_rst(db, 'children', rst)



  return rst.to_json
end

get '/descendants/:parentid' do
  db = @networddb
  rst, _ = get_descendents(db, 0, params[:parentid].to_i, [params[:parentid].to_i])


  return rst.to_json
end

get '/tagged' do
  db = @networddb

  sql = 'SELECT w.id, w.name, w.url ' \
        'FROM word_tbl w ' \
        'WHERE w.tagged = true ' \
        ''

  rst = db.queryForResultset(sql)
  insert_accesslog_rst(db, 'tagged', rst)



  return rst.to_json
end

post '/loadwords' do
  request.body.rewind
  data = JSON.parse request.body.read

  level_one_id = data['id'].to_i
  level_two_id = nil
  db = @networddb
  data['words'].split("\n").each do |word|
    w = word.strip
    next if w == ''

    sql = 'INSERT INTO word_tbl( name ) VALUES ( ? )'
    db.execute(sql, [w])

    id = db.queryForValue("SELECT CURRVAL( 'word_seq' )")
    parent_id = ((word[0] == ' ' || word[0] == "\t") && !level_two_id.nil?) ? level_two_id : level_one_id
    sql = 'INSERT INTO link_tbl( word_1, word_2 ) VALUES ( ?, ? )'
    db.execute(sql, [parent_id, id])

    level_two_id = id unless (word[0] == ' ' || word[0] == "\t")
  end

  p data

  return 'id'
end

post '/updateword/:id' do
  request.body.rewind
  data = request.body.read

  db = @networddb
  db.execute 'UPDATE word_tbl SET name = ? WHERE id = ? ', [data, params[:id]]

end

post '/seturl/:id' do
  request.body.rewind
  data = request.body.read

  p "seturl: #{data}"

  db = @networddb
  db.execute 'UPDATE word_tbl SET url = ? WHERE id = ? ', [data, params[:id]]

end

post '/addext' do
  db = @networddb

  request.body.rewind
  data = JSON.parse request.body.read

  sql = 'INSERT INTO word_tbl( name, url, tagged ) VALUES ( ?, ?, true )'
  db.execute(sql, [data['word'], data['url']])


end

options '/addext' do
  response.headers['Allow'] = 'POST,OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  response.headers['Access-Control-Allow-Origin'] = 'chrome-extension://mimggjmblkmdldpnkndbkcinbpfkhgaf'

  200
end
