fs = require 'fs'
path = require 'path'
#posix = require 'posix'
posix = require 'fs'
#require('epipebomb')()


global.otto = otto = {}    # our namespace
require './server/misc'      # attaches to global.otto.misc

otto.MUSICROOT_SEARCHLIST =
[
  { dir: '~/Music', strip: 'Music' },
  { dir: '/otto/u', strip: false }
]

otto.SECRET = 'FiiY3Xeiwie3deeGahBiu9ja'  # need to randomly generate this for each install FIXME

otto.OTTO_ROOT = path.dirname(fs.realpathSync(__filename))
if path.basename(otto.OTTO_ROOT) is 'src'
  # remove the src directory from the root path
  otto.OTTO_ROOT = path.dirname(otto.OTTO_ROOT)
if path.basename(otto.OTTO_ROOT) is 'app.asar'
  # remove the electron modules tar-like archive from the root path
  otto.OTTO_ROOT = path.dirname(otto.OTTO_ROOT)
console.log 'OTTO_ROOT', otto.OTTO_ROOT

otto.OTTO_BIN            = otto.OTTO_ROOT    + '/bin'
otto.OTTO_LIB            = otto.OTTO_ROOT    + '/lib'

if process.platform is 'darwin'
  otto.OTTO_VAR = otto.misc.expand_tilde '~/Library/Otto'
else
  otto.OTTO_VAR          = otto.OTTO_ROOT    + '/var'
otto.misc.assert_is_dir_or_create_itSync otto.OTTO_VAR

otto.OTTO_VAR_MPD        = otto.OTTO_VAR     + '/mpd'
otto.OTTO_VAR_MPD_MUSIC  = otto.OTTO_VAR_MPD + '/music'
otto.MPD_EXECUTABLE      = otto.OTTO_BIN     + '/mpd'
otto.misc.assert_is_dir_or_create_itSync otto.OTTO_VAR_MPD
otto.misc.assert_is_dir_or_create_itSync otto.OTTO_VAR_MPD_MUSIC

otto.OTTO_VAR_MONGODB    = otto.OTTO_VAR  + '/mongodb'
otto.MONGOD_EXECUTABLE   = otto.OTTO_BIN  + '/mongod'
otto.misc.assert_is_dir_or_create_itSync otto.OTTO_VAR_MONGODB
# we should probably also test for the BINs


if process.env['USER'] is 'root'
  # safer to not run as root
  # and as root, mpd can't use file:///
  # also: mpd can not use file:/// under Windows at all (not related to root)
  # we need an option for which plain user switch to
  # or we could just exit and recommend people use supervisord
  # (the python process manager, not to be confused with node-supervisor)
  otto.OTTO_SPAWN_AS_UID = posix.getpwnam('jon').uid  # oh boy. FIXME

#if process.env['USER'] is 'root'
#  try
#    safeuser = 'jon'
#    safeuserpw = posix.getpwnam(safeuser)
#    console.log "switching to user '#{safeuser}'"
#    process.setgid safeuserpw.gid
#    process.setuid safeuserpw.uid
#    console.log "new uid: #{process.getuid()}"
#  catch err
#    console.log 'failed to drop root privileges: ' + err


if process.platform is 'darwin'
  try
    posix.setrlimit('nofile', { soft: 10000, hard: 10000 })
  catch error
    #console.log '###'
    #console.log '### setting file limit failed: ' + error
    #console.log '###'


channels_json = otto.OTTO_VAR  + '/channels.json'
if fs.existsSync channels_json
  try
    console.log "loading channels.json file (#{channels_json})"
    otto.channelinfolist = JSON.parse(fs.readFileSync channels_json, 'utf8')
    #console.log 'channelinfolist', otto.channelinfolist
  catch error
    console.log "### error reading channels.json file (#{channeld_json}): #{error}"
    console.log '### using default channels'
    otto.channelinfolist = false

if not otto.channelinfolist
  otto.channelinfolist = [
    {name: 'main',   fullname: 'Main Channel',   type: 'standard', layout: 'standard'}
    {name: 'second', fullname: 'Second Channel', type: 'standard', layout: 'standard'}
    {name: 'third',  fullname: 'Third Channel',  type: 'standard', layout: 'standard'}
  ]


require './server/server'
require './server/events'    # attaches to global.otto.events
require './server/mongod'    # etc...
require './server/mpd'
require './server/db'
require './server/listeners'
require './server/channels'
require './server/loader'
require './server/index'
#require './server/zeroconf'
require './server/main'

# client side
require './client/client'  # must be first
require './client/templates'
require './client/misc'
require './client/player'
require './client/soundfx'
require './client/cubes'


otto.exiting = false

if false
  # auto start up if we were called from the command line
  otto.main ->
    console.log 'otto started'
else
  return otto