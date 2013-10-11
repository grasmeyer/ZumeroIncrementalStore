.load zumero

SELECT zumero_internal_auth_create(
    'http://localhost:8080',
    'zumero_users_admin',
    NULL,
    NULL,
    NULL,
    'admin',
    'YOUR_PASSWORD',
    zumero_internal_auth_scheme('zumero_users_admin'),
    zumero_named_constant('acl_who_any_authenticated_user'),
    zumero_internal_auth_scheme('zumero_users_admin'),
    zumero_named_constant('acl_who_any_authenticated_user')
    );

BEGIN TRANSACTION;

SELECT zumero_define_acl_table('main');

-- Don't let anyone do anything with this dbfile
INSERT INTO z_acl (scheme,who,tbl,op,result) VALUES (
    '', 
    zumero_named_constant('acl_who_anyone'), 
    '', 
    '*',
    zumero_named_constant('acl_result_deny')
    );

-- except admins
INSERT INTO z_acl (scheme,who,tbl,op,result) VALUES (
    zumero_internal_auth_scheme('zumero_users_admin'), 
    zumero_named_constant('acl_who_any_authenticated_user'), 
    '', 
    '*',
    zumero_named_constant('acl_result_allow')
    );

-- explicitly mention create_dbfile, for clarity of this example
INSERT INTO z_acl (scheme,who,tbl,op,result) VALUES (
    zumero_internal_auth_scheme('zumero_users_admin'), 
    zumero_named_constant('acl_who_any_authenticated_user'), 
    '', 
    zumero_named_constant('acl_op_create_dbfile'), 
    zumero_named_constant('acl_result_allow'));

COMMIT TRANSACTION;

SELECT zumero_sync('main','http://localhost:8080', 'zumero_config', NULL, NULL, NULL);

-- Set up zeauth table
select zumero_internal_auth_create(
'http://localhost:8080', 
'zauth', 
zumero_internal_auth_scheme('zumero_users_admin'), 
'admin', 
'YOUR_PASSWORD', 
NULL, 
NULL, 
'', 
zumero_named_constant('acl_who_anyone'), 
zumero_internal_auth_scheme('zumero_users_admin'), 
zumero_named_constant('acl_who_specific_user') || 'admin'
);

select zumero_internal_auth_add_user(
'http://localhost:8080', 
'zauth', 
NULL, 
NULL, 
NULL, 
'user', 
'userpass'
);

select zumero_sync(
'main', 
'http://localhost:8080', 
'zumero_config', 
zumero_internal_auth_scheme('zumero_users_admin'), 
'admin', 
'YOUR_PASSWORD'
);

INSERT INTO z_acl (scheme,who,tbl,op,result) VALUES (
zumero_internal_auth_scheme('zauth'), 
zumero_named_constant('acl_who_any_authenticated_user'), 
'', 
'*', 
zumero_named_constant('acl_result_allow')
);

select zumero_sync(
'main', 
'http://localhost:8080', 
'zumero_config', 
zumero_internal_auth_scheme('zumero_users_admin'), 
'admin', 
'YOUR_PASSWORD'
);