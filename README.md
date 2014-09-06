DropboxUploadsOrganizer
=======================

Automatically organize files in `Camera Uploads` directory.

Setup
-----
- Create a Dropbox App
- Get an access_token (oauth)
- Define a `DROPBOX_ACCESS_TOKEN` environment variable in `.env`

Deploy
------
- Create Heroku app
- Add [Redis To Go nano](https://addons.heroku.com/redistogo#nano) addon
- Run `heroku config:set DROPBOX_ACCESS_TOKEN={token_here} REDIS_PROVIDER=REDISTOGO_URL` 
- Deploy to Heroku
- Add [Scheduler](https://addons.heroku.com/scheduler) addon
- Schedule task `ruby sort.rb` every 10 minutes

Current rules
-------------
- Move `jpg` to `Pictures/YYYY/MM Month - YYYY/` directory
- Move `quicktime` videos to `Pictures/Videos/` directory

TODO
----
- Handle other file types
- Handle errors (already a dest file with same name, ...)
- Clean (delete empty folders) in `Camera Uploads` after sorting
- Add specs
