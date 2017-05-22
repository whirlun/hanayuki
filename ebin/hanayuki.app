{application, hanayuki,
 [{description, "The next generation of forum system"},
  {vsn, "0.0.1"},
  {modules, [
             ha_app,
             ha_mnesia,
             ha_sup,
             index_sup,
             index,
             sc_server,
             sc_sup
            ]},
  {registered, [ha_app]},
  {applications, [kernel, stdlib]},
  {mod, {ha_app, []}}
 ]}.