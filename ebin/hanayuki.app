{application, hanayuki,
 [{description, "The next generation of forum system"},
  {vsn, "0.0.1"},
  {modules, [
             ha_app,
             ha_sup,
             ha_index_sup,
             ha_index,
             ha_sc_server,
             ha_sc_sup,
             ha_database,
             ha_mongo,
             ha_user_sup,
             ha_user,
             ha_thread,
             ha_thread_sup
            ]},
  {registered, [ha_app]},
  {applications, [kernel, stdlib]},
  {mod, {ha_app, []}}
 ]}.