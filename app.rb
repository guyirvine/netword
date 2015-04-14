require 'sinatra'

require 'FluidDb'
require 'json'

class Netword < Sinatra::Application

before do
end

get '/word/:id' do
  db = FluidDb::Db(ENV['DATABASE_URL'])

  c = params[:id]
  sql = 'SELECT w.id, w.name, w.url FROM word_tbl w WHERE w.id = ?'
  arr = db.queryForArray(sql, [c])

  db.close

  return arr.to_json
end

get '/search/:criteria' do
  db = FluidDb::Db(ENV['DATABASE_URL'])

  c = "%#{params[:criteria]}%".upcase
  sql = 'SELECT id, name, url FROM word_tbl WHERE UPPER(name) LIKE ?'
  rst = db.queryForResultset(sql, [c])

  db.close

  return rst.to_json
end

get '/link/:parentid' do
  db = FluidDb::Db(ENV['DATABASE_URL'])

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
  db = FluidDb::Db(ENV['DATABASE_URL'])

  c = params[:parentid].to_i
  sql = 'SELECT w1.name, w1.url ' \
        'FROM word_tbl w1 ' \
        '  INNER JOIN link_tbl l1 ON ( w1.id = l1.word_1 ) ' \
        'WHERE l1.word_2 = ? ' \
        'UNION ' \
        'SELECT w2.name, w2.url ' \
        'FROM word_tbl w2 ' \
        '  INNER JOIN link_tbl l2 ON ( w2.id = l2.word_2 ) ' \
        'WHERE l2.word_1 = ? ' \
        ''

  rst = db.queryForResultset(sql, [c, c])

  db.close

  return rst.to_json
end

end

