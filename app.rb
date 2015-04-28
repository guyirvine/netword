require 'sinatra'

require 'FluidDb'
require 'json'

class Netword < Sinatra::Application
  before do
  end

  helpers do
    def get_children(db, id)
      sql = 'SELECT w1.id ' \
            'FROM word_tbl w1 ' \
            '  INNER JOIN link_tbl l1 ON ( w1.id = l1.word_1 ) ' \
            'WHERE l1.word_2 = ? ' \
            'UNION ' \
            'SELECT w2.id ' \
            'FROM word_tbl w2 ' \
            '  INNER JOIN link_tbl l2 ON ( w2.id = l2.word_2 ) ' \
            'WHERE l2.word_1 = ? ' \
            ''

      db.queryForResultset(sql, [id, id])
    end

    def get_word(db, id)
      sql = 'SELECT w.id, w.name, w.url, w.tagged, w.showlevels ' \
            'FROM word_tbl w ' \
            'WHERE w.id = ? ' \
            ''
      db.queryForArray(sql, [id])
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
        el['children'].push child
      end
      [el, ids]
    end
  end

  get '/word/:id' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))

    c = params[:id]
    sql = 'SELECT w.id, w.name, w.url, w.tagged, w.showlevels FROM word_tbl w WHERE w.id = ?'
    arr = db.queryForArray(sql, [c])

    db.close

    return arr.to_json
  end

  post '/delete/:id' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    db.execute('DELETE FROM link_tbl WHERE word_1 = ?', [params[:id]])
    db.execute('DELETE FROM link_tbl WHERE word_2 = ?', [params[:id]])
    db.execute('DELETE FROM word_tbl WHERE id = ?', [params[:id]])
    db.close
  end

  post '/tag/:id' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    db.execute('UPDATE word_tbl SET tagged = true WHERE id = ?', [params[:id]])
    db.close
  end

  post '/untag/:id' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    db.execute('UPDATE word_tbl SET tagged = false WHERE id = ?', [params[:id]])
    db.close
  end

  post '/singlelevel/:id' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    db.execute('UPDATE word_tbl SET showlevels = 1 WHERE id = ?', [params[:id]])
    db.close
  end

  post '/multilevel/:id' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    db.execute('UPDATE word_tbl SET showlevels = 2 WHERE id = ?', [params[:id]])
    db.close
  end


  post '/word' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))

    request.body.rewind
    word = request.body.read

    sql = 'INSERT INTO word_tbl( name ) VALUES ( ? )'
    db.execute(sql, [word])

    id = db.queryForValue("SELECT CURRVAL( 'word_seq' )")

    db.close

    return id
  end

  post '/link' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))

    request.body.rewind
    data = JSON.parse request.body.read

    sql = 'INSERT INTO link_tbl( word_1, word_2 ) VALUES ( ?, ? )'
    db.execute(sql, [data['word_1'], data['word_2']])

    id = db.queryForValue("SELECT CURRVAL( 'link_seq' )")

    db.close

    return id
  end

  get '/search/:criteria' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))

    c = "%#{params[:criteria]}%".upcase
    sql = 'SELECT id, name, url FROM word_tbl WHERE UPPER(name) LIKE ?'
    rst = db.queryForResultset(sql, [c])

    db.close

    return rst.to_json
  end

  get '/link/:parentid' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))

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

    db.close

    return rst.to_json
  end

  get '/children/:parentid' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))

    c = params[:parentid].to_i
    sql = 'SELECT w1.id, w1.name, w1.url ' \
          'FROM word_tbl w1 ' \
          '  INNER JOIN link_tbl l1 ON ( w1.id = l1.word_1 ) ' \
          'WHERE l1.word_2 = ? ' \
          'UNION ' \
          'SELECT w2.id, w2.name, w2.url ' \
          'FROM word_tbl w2 ' \
          '  INNER JOIN link_tbl l2 ON ( w2.id = l2.word_2 ) ' \
          'WHERE l2.word_1 = ? ' \
          ''

    rst = db.queryForResultset(sql, [c, c])

    db.close

    return rst.to_json
  end

  get '/descendants/:parentid' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    rst, _ = get_descendents(db, 0, params[:parentid].to_i, [params[:parentid].to_i])
    db.close

    return rst.to_json
  end

  get '/tagged' do
    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))

    sql = 'SELECT w.id, w.name, w.url ' \
          'FROM word_tbl w ' \
          'WHERE w.tagged = true ' \
          ''

    rst = db.queryForResultset(sql)

    db.close

    return rst.to_json
  end

  post '/loadwords' do
    request.body.rewind
    data = JSON.parse request.body.read

    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    data['words'].split("\n").each do |word|
      word.strip!
      next if word == ''

      sql = 'INSERT INTO word_tbl( name ) VALUES ( ? )'
      db.execute(sql, [word])

      sql = "INSERT INTO link_tbl( word_1, word_2 ) VALUES ( ?, CURRVAL( 'word_seq' ) )"
      db.execute(sql, [data['id']])
    end

    p data

    return 'id'
  end

  post '/updateword/:id' do
    request.body.rewind
    data = request.body.read

    db = FluidDb::Db(ENV['DATABASE_URL'].sub('postgres', 'pgsql'))
    db.execute 'UPDATE word_tbl SET name = ? WHERE id = ? ', [data, params[:id]]
    db.close
  end
end
