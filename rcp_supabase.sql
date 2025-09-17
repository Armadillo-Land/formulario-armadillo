BEGIN;
CREATE OR REPLACE FUNCTION extensions.armor(bytea)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_armor$function$
;
GRANT EXECUTE ON FUNCTION extensions.armor(bytea) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.armor(bytea) TO postgres;
CREATE OR REPLACE FUNCTION extensions.armor(bytea, text[], text[])
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_armor$function$
;
GRANT EXECUTE ON FUNCTION extensions.armor(bytea, text[], text[]) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.armor(bytea, text[], text[]) TO postgres;
CREATE OR REPLACE FUNCTION extensions.crypt(text, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_crypt$function$
;
GRANT EXECUTE ON FUNCTION extensions.crypt(text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.crypt(text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.dearmor(text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_dearmor$function$
;
GRANT EXECUTE ON FUNCTION extensions.dearmor(text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.dearmor(text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.decrypt(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_decrypt$function$
;
GRANT EXECUTE ON FUNCTION extensions.decrypt(bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.decrypt(bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_decrypt_iv$function$
;
GRANT EXECUTE ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.digest(bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_digest$function$
;
GRANT EXECUTE ON FUNCTION extensions.digest(bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.digest(bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.digest(text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_digest$function$
;
GRANT EXECUTE ON FUNCTION extensions.digest(text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.digest(text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.encrypt(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_encrypt$function$
;
GRANT EXECUTE ON FUNCTION extensions.encrypt(bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.encrypt(bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_encrypt_iv$function$
;
GRANT EXECUTE ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.gen_random_bytes(integer)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_random_bytes$function$
;
GRANT EXECUTE ON FUNCTION extensions.gen_random_bytes(integer) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.gen_random_bytes(integer) TO postgres;
CREATE OR REPLACE FUNCTION extensions.gen_random_uuid()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/pgcrypto', $function$pg_random_uuid$function$
;
GRANT EXECUTE ON FUNCTION extensions.gen_random_uuid() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.gen_random_uuid() TO postgres;
CREATE OR REPLACE FUNCTION extensions.gen_salt(text)
 RETURNS text
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_gen_salt$function$
;
GRANT EXECUTE ON FUNCTION extensions.gen_salt(text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.gen_salt(text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.gen_salt(text, integer)
 RETURNS text
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_gen_salt_rounds$function$
;
GRANT EXECUTE ON FUNCTION extensions.gen_salt(text, integer) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.gen_salt(text, integer) TO postgres;
CREATE OR REPLACE FUNCTION extensions.grant_pg_cron_access()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$function$
;
GRANT EXECUTE ON FUNCTION extensions.grant_pg_cron_access() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.grant_pg_cron_access() TO supabase_admin;
CREATE OR REPLACE FUNCTION extensions.grant_pg_graphql_access()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$function$
;
GRANT EXECUTE ON FUNCTION extensions.grant_pg_graphql_access() TO postgres;
GRANT EXECUTE ON FUNCTION extensions.grant_pg_graphql_access() TO supabase_admin;
CREATE OR REPLACE FUNCTION extensions.grant_pg_net_access()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$function$
;
GRANT EXECUTE ON FUNCTION extensions.grant_pg_net_access() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.grant_pg_net_access() TO supabase_admin;
CREATE OR REPLACE FUNCTION extensions.hmac(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_hmac$function$
;
GRANT EXECUTE ON FUNCTION extensions.hmac(bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.hmac(bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.hmac(text, text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_hmac$function$
;
GRANT EXECUTE ON FUNCTION extensions.hmac(text, text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.hmac(text, text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone)
 RETURNS SETOF record
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pg_stat_statements', $function$pg_stat_statements_1_11$function$
;
GRANT EXECUTE ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone)
 RETURNS record
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pg_stat_statements', $function$pg_stat_statements_info$function$
;
GRANT EXECUTE ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pg_stat_statements_reset(userid oid DEFAULT 0, dbid oid DEFAULT 0, queryid bigint DEFAULT 0, minmax_only boolean DEFAULT false)
 RETURNS timestamp with time zone
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pg_stat_statements', $function$pg_stat_statements_reset_1_11$function$
;
GRANT EXECUTE ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint, minmax_only boolean) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_armor_headers$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_key_id(bytea)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_key_id_w$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_key_id(bytea) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_key_id(bytea) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_decrypt(bytea, bytea)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_encrypt(text, bytea)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_encrypt(text, bytea, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_decrypt(bytea, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_decrypt(bytea, text, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_encrypt(text, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_encrypt(text, text, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_text$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_bytea$function$
;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.pgrst_ddl_watch()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $function$
;
GRANT EXECUTE ON FUNCTION extensions.pgrst_ddl_watch() TO postgres;
GRANT EXECUTE ON FUNCTION extensions.pgrst_ddl_watch() TO supabase_admin;
CREATE OR REPLACE FUNCTION extensions.pgrst_drop_watch()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $function$
;
GRANT EXECUTE ON FUNCTION extensions.pgrst_drop_watch() TO postgres;
GRANT EXECUTE ON FUNCTION extensions.pgrst_drop_watch() TO supabase_admin;
CREATE OR REPLACE FUNCTION extensions.set_graphql_placeholder()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$function$
;
GRANT EXECUTE ON FUNCTION extensions.set_graphql_placeholder() TO postgres;
GRANT EXECUTE ON FUNCTION extensions.set_graphql_placeholder() TO supabase_admin;
CREATE OR REPLACE FUNCTION extensions.uuid_generate_v1()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v1$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v1() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v1() TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_generate_v1mc()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v1mc$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v1mc() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v1mc() TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_generate_v3(namespace uuid, name text)
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v3$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_generate_v4()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v4$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v4() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v4() TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_generate_v5(namespace uuid, name text)
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v5$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_nil()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_nil$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_nil() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_nil() TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_ns_dns()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_dns$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_dns() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_dns() TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_ns_oid()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_oid$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_oid() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_oid() TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_ns_url()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_url$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_url() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_url() TO postgres;
CREATE OR REPLACE FUNCTION extensions.uuid_ns_x500()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_x500$function$
;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_x500() TO dashboard_user;
GRANT EXECUTE ON FUNCTION extensions.uuid_ns_x500() TO postgres;
CREATE OR REPLACE FUNCTION graphql._internal_resolve(query text, variables jsonb DEFAULT '{}'::jsonb, "operationName" text DEFAULT NULL::text, extensions jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE c
AS '$libdir/pg_graphql', $function$resolve_wrapper$function$
;
GRANT EXECUTE ON FUNCTION graphql._internal_resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO anon;
GRANT EXECUTE ON FUNCTION graphql._internal_resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION graphql._internal_resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO postgres;
GRANT EXECUTE ON FUNCTION graphql._internal_resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION graphql._internal_resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO supabase_admin;
CREATE OR REPLACE FUNCTION graphql.comment_directive(comment_ text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
    /*
    comment on column public.account.name is '@graphql.name: myField'
    */
    select
        coalesce(
            (
                regexp_match(
                    comment_,
                    '@graphql\((.+)\)'
                )
            )[1]::jsonb,
            jsonb_build_object()
        )
$function$
;
GRANT EXECUTE ON FUNCTION graphql.comment_directive(comment_ text) TO anon;
GRANT EXECUTE ON FUNCTION graphql.comment_directive(comment_ text) TO authenticated;
GRANT EXECUTE ON FUNCTION graphql.comment_directive(comment_ text) TO postgres;
GRANT EXECUTE ON FUNCTION graphql.comment_directive(comment_ text) TO service_role;
GRANT EXECUTE ON FUNCTION graphql.comment_directive(comment_ text) TO supabase_admin;
CREATE OR REPLACE FUNCTION graphql.exception(message text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
begin
    raise exception using errcode='22000', message=message;
end;
$function$
;
GRANT EXECUTE ON FUNCTION graphql.exception(message text) TO anon;
GRANT EXECUTE ON FUNCTION graphql.exception(message text) TO authenticated;
GRANT EXECUTE ON FUNCTION graphql.exception(message text) TO postgres;
GRANT EXECUTE ON FUNCTION graphql.exception(message text) TO service_role;
GRANT EXECUTE ON FUNCTION graphql.exception(message text) TO supabase_admin;
CREATE OR REPLACE FUNCTION graphql.get_schema_version()
 RETURNS integer
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
    select last_value from graphql.seq_schema_version;
$function$
;
GRANT EXECUTE ON FUNCTION graphql.get_schema_version() TO anon;
GRANT EXECUTE ON FUNCTION graphql.get_schema_version() TO authenticated;
GRANT EXECUTE ON FUNCTION graphql.get_schema_version() TO postgres;
GRANT EXECUTE ON FUNCTION graphql.get_schema_version() TO service_role;
GRANT EXECUTE ON FUNCTION graphql.get_schema_version() TO supabase_admin;
CREATE OR REPLACE FUNCTION graphql.increment_schema_version()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
    perform pg_catalog.nextval('graphql.seq_schema_version');
end;
$function$
;
GRANT EXECUTE ON FUNCTION graphql.increment_schema_version() TO anon;
GRANT EXECUTE ON FUNCTION graphql.increment_schema_version() TO authenticated;
GRANT EXECUTE ON FUNCTION graphql.increment_schema_version() TO postgres;
GRANT EXECUTE ON FUNCTION graphql.increment_schema_version() TO service_role;
GRANT EXECUTE ON FUNCTION graphql.increment_schema_version() TO supabase_admin;
CREATE OR REPLACE FUNCTION graphql.resolve(query text, variables jsonb DEFAULT '{}'::jsonb, "operationName" text DEFAULT NULL::text, extensions jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
declare
    res jsonb;
    message_text text;
begin
  begin
    select graphql._internal_resolve("query" := "query",
                                     "variables" := "variables",
                                     "operationName" := "operationName",
                                     "extensions" := "extensions") into res;
    return res;
  exception
    when others then
    get stacked diagnostics message_text = message_text;
    return
    jsonb_build_object('data', null,
                       'errors', jsonb_build_array(jsonb_build_object('message', message_text)));
  end;
end;
$function$
;
GRANT EXECUTE ON FUNCTION graphql.resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO anon;
GRANT EXECUTE ON FUNCTION graphql.resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION graphql.resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO postgres;
GRANT EXECUTE ON FUNCTION graphql.resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION graphql.resolve(query text, variables jsonb, "operationName" text, extensions jsonb) TO supabase_admin;
CREATE OR REPLACE FUNCTION graphql_public.graphql("operationName" text DEFAULT NULL::text, query text DEFAULT NULL::text, variables jsonb DEFAULT NULL::jsonb, extensions jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE sql
AS $function$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $function$
;
GRANT EXECUTE ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO anon;
GRANT EXECUTE ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO postgres;
GRANT EXECUTE ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO supabase_admin;
CREATE OR REPLACE FUNCTION pgbouncer.get_auth(p_usename text)
 RETURNS TABLE(username text, password text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
    raise debug 'PgBouncer auth request: %', p_usename;

    return query
    select 
        rolname::text, 
        case when rolvaliduntil < now() 
            then null 
            else rolpassword::text 
        end 
    from pg_authid 
    where rolname=$1 and rolcanlogin;
end;
$function$
;
GRANT EXECUTE ON FUNCTION pgbouncer.get_auth(p_usename text) TO pgbouncer;
GRANT EXECUTE ON FUNCTION pgbouncer.get_auth(p_usename text) TO postgres;
GRANT EXECUTE ON FUNCTION pgbouncer.get_auth(p_usename text) TO supabase_admin;
CREATE OR REPLACE FUNCTION public.insertar_personal_completo(p_banco jsonb, p_personal jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_dba_id int;
  v_per_id int;
  v_doc    text := nullif(p_personal->>'per_num_doc','');
begin
  if v_doc is null then
    raise exception 'per_num_doc requerido' using errcode = '23514';
  end if;

  if not exists (
    select 1 from public.autorizados a where a.num_cedula = v_doc
  ) then
    raise exception 'La cédula % no está autorizada para registrarse', v_doc
      using errcode = '42501';
  end if;

  insert into public.datos_bancarios (dba_banco_id, dba_num_cuenta)
  values (
    (p_banco->>'dba_banco_id')::int,
    nullif(p_banco->>'dba_num_cuenta','')
  )
  returning dba_id into v_dba_id;

  insert into public.personal (
    per_pdf_cedula, per_pdf_rut, per_pdf_comprobante_banco, per_pdf_hoja_vida,
    per_tipo_doc, per_num_doc, per_primer_nombre, per_segundo_nombre,
    per_primer_apellido, per_segundo_apellido, per_telefono_llamada,
    per_telefono_whatsapp, per_fecha_nacimiento, per_correo,
    per_direccion_residencia, per_nombre_emergencia, per_telefono_contacto_emergencia,
    per_estatura, per_talla_camiseta, per_talla_pantalon, per_talla_zapatos,
    per_localidad_barrio, per_alergias, per_nivel_ingles,
    per_genero_id, per_ciudad_id, per_eps_id, per_ali_id,
    per_dato_bancario, per_status_personal, per_perfilamiento, per_foto
  )
  values (
    nullif(p_personal->>'per_pdf_cedula',''),
    nullif(p_personal->>'per_pdf_rut',''),
    nullif(p_personal->>'per_pdf_comprobante_banco',''),
    nullif(p_personal->>'per_pdf_hoja_vida',''),
    p_personal->>'per_tipo_doc',
    v_doc,
    p_personal->>'per_primer_nombre',
    nullif(p_personal->>'per_segundo_nombre',''),
    p_personal->>'per_primer_apellido',
    nullif(p_personal->>'per_segundo_apellido',''),
    nullif(p_personal->>'per_telefono_llamada',''),
    p_personal->>'per_telefono_whatsapp',
    (p_personal->>'per_fecha_nacimiento')::date,
    p_personal->>'per_correo',
    p_personal->>'per_direccion_residencia',
    p_personal->>'per_nombre_emergencia',
    p_personal->>'per_telefono_contacto_emergencia',
    (p_personal->>'per_estatura')::smallint,
    p_personal->>'per_talla_camiseta',
    p_personal->>'per_talla_pantalon',
    p_personal->>'per_talla_zapatos',
    p_personal->>'per_localidad_barrio',
    nullif(p_personal->>'per_alergias',''),
    p_personal->>'per_nivel_ingles',
    (p_personal->>'per_genero_id')::int,
    (p_personal->>'per_ciudad_id')::int,
    (p_personal->>'per_eps_id')::int,
    (p_personal->>'per_ali_id')::int,
    v_dba_id,
    (p_personal->>'per_status_personal')::int,
    (p_personal->>'per_perfilamiento')::int,
    nullif(p_personal->>'per_foto','')
  )
  returning per_id into v_per_id;

  return json_build_object('per_id', v_per_id, 'dba_id', v_dba_id);
end;
$function$
;
GRANT EXECUTE ON FUNCTION public.insertar_personal_completo(p_banco jsonb, p_personal jsonb) TO anon;
GRANT EXECUTE ON FUNCTION public.insertar_personal_completo(p_banco jsonb, p_personal jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.insertar_personal_completo(p_banco jsonb, p_personal jsonb) TO postgres;
GRANT EXECUTE ON FUNCTION public.insertar_personal_completo(p_banco jsonb, p_personal jsonb) TO service_role;
CREATE OR REPLACE FUNCTION public.precheck_persona(p_doc text)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
select json_build_object(
  'autorizado', exists (select 1 from public.autorizados a where a.num_cedula = p_doc),
  'existe',     exists (select 1 from public.personal    p where p.per_num_doc  = p_doc)
);
$function$
;
GRANT EXECUTE ON FUNCTION public.precheck_persona(p_doc text) TO anon;
GRANT EXECUTE ON FUNCTION public.precheck_persona(p_doc text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.precheck_persona(p_doc text) TO postgres;
GRANT EXECUTE ON FUNCTION public.precheck_persona(p_doc text) TO service_role;
CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    begin
      new.updated_at := now();
      return new;
    end;
    $function$
;
GRANT EXECUTE ON FUNCTION public.set_updated_at() TO anon;
GRANT EXECUTE ON FUNCTION public.set_updated_at() TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_updated_at() TO postgres;
GRANT EXECUTE ON FUNCTION public.set_updated_at() TO service_role;
CREATE OR REPLACE FUNCTION public.trigger_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$function$
;
GRANT EXECUTE ON FUNCTION public.trigger_set_updated_at() TO anon;
GRANT EXECUTE ON FUNCTION public.trigger_set_updated_at() TO authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_set_updated_at() TO postgres;
GRANT EXECUTE ON FUNCTION public.trigger_set_updated_at() TO service_role;
CREATE OR REPLACE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024))
 RETURNS SETOF realtime.wal_rls
 LANGUAGE plpgsql
AS $function$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_;

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$function$
;
GRANT EXECUTE ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO anon;
GRANT EXECUTE ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO service_role;
GRANT EXECUTE ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$function$
;
GRANT EXECUTE ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO supabase_admin;
CREATE OR REPLACE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[])
 RETURNS text
 LANGUAGE sql
AS $function$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $function$
;
GRANT EXECUTE ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO anon;
GRANT EXECUTE ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO service_role;
GRANT EXECUTE ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime."cast"(val text, type_ regtype)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $function$
;
GRANT EXECUTE ON FUNCTION realtime."cast"(val text, type_ regtype) TO anon;
GRANT EXECUTE ON FUNCTION realtime."cast"(val text, type_ regtype) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime."cast"(val text, type_ regtype) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime."cast"(val text, type_ regtype) TO postgres;
GRANT EXECUTE ON FUNCTION realtime."cast"(val text, type_ regtype) TO service_role;
GRANT EXECUTE ON FUNCTION realtime."cast"(val text, type_ regtype) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime."cast"(val text, type_ regtype) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $function$
;
GRANT EXECUTE ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO anon;
GRANT EXECUTE ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO service_role;
GRANT EXECUTE ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[])
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $function$
;
GRANT EXECUTE ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO anon;
GRANT EXECUTE ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO service_role;
GRANT EXECUTE ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer)
 RETURNS SETOF realtime.wal_rls
 LANGUAGE sql
 SET log_min_messages TO 'fatal'
AS $function$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $function$
;
GRANT EXECUTE ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO anon;
GRANT EXECUTE ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO service_role;
GRANT EXECUTE ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.quote_wal2json(entity regclass)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $function$
;
GRANT EXECUTE ON FUNCTION realtime.quote_wal2json(entity regclass) TO anon;
GRANT EXECUTE ON FUNCTION realtime.quote_wal2json(entity regclass) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.quote_wal2json(entity regclass) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.quote_wal2json(entity regclass) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.quote_wal2json(entity regclass) TO service_role;
GRANT EXECUTE ON FUNCTION realtime.quote_wal2json(entity regclass) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.quote_wal2json(entity regclass) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  BEGIN
    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (payload, event, topic, private, extension)
    VALUES (payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$function$
;
GRANT EXECUTE ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO supabase_admin;
CREATE OR REPLACE FUNCTION realtime.subscription_check_filters()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $function$
;
GRANT EXECUTE ON FUNCTION realtime.subscription_check_filters() TO anon;
GRANT EXECUTE ON FUNCTION realtime.subscription_check_filters() TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.subscription_check_filters() TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.subscription_check_filters() TO postgres;
GRANT EXECUTE ON FUNCTION realtime.subscription_check_filters() TO service_role;
GRANT EXECUTE ON FUNCTION realtime.subscription_check_filters() TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.subscription_check_filters() TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.to_regrole(role_name text)
 RETURNS regrole
 LANGUAGE sql
 IMMUTABLE
AS $function$ select role_name::regrole $function$
;
GRANT EXECUTE ON FUNCTION realtime.to_regrole(role_name text) TO anon;
GRANT EXECUTE ON FUNCTION realtime.to_regrole(role_name text) TO authenticated;
GRANT EXECUTE ON FUNCTION realtime.to_regrole(role_name text) TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.to_regrole(role_name text) TO postgres;
GRANT EXECUTE ON FUNCTION realtime.to_regrole(role_name text) TO service_role;
GRANT EXECUTE ON FUNCTION realtime.to_regrole(role_name text) TO supabase_admin;
GRANT EXECUTE ON FUNCTION realtime.to_regrole(role_name text) TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION realtime.topic()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
select nullif(current_setting('realtime.topic', true), '')::text;
$function$
;
GRANT EXECUTE ON FUNCTION realtime.topic() TO dashboard_user;
GRANT EXECUTE ON FUNCTION realtime.topic() TO postgres;
GRANT EXECUTE ON FUNCTION realtime.topic() TO supabase_realtime_admin;
CREATE OR REPLACE FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea DEFAULT '\x7067736f6469756d'::bytea, nonce bytea DEFAULT NULL::bytea)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE
AS '$libdir/supabase_vault', $function$pgsodium_crypto_aead_det_decrypt_by_id$function$
;
GRANT EXECUTE ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO postgres;
GRANT EXECUTE ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO service_role;
GRANT EXECUTE ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO supabase_admin;
CREATE OR REPLACE FUNCTION vault._crypto_aead_det_encrypt(message bytea, additional bytea, key_id bigint, context bytea DEFAULT '\x7067736f6469756d'::bytea, nonce bytea DEFAULT NULL::bytea)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE
AS '$libdir/supabase_vault', $function$pgsodium_crypto_aead_det_encrypt_by_id$function$
;
GRANT EXECUTE ON FUNCTION vault._crypto_aead_det_encrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO supabase_admin;
CREATE OR REPLACE FUNCTION vault._crypto_aead_det_noncegen()
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE
AS '$libdir/supabase_vault', $function$pgsodium_crypto_aead_det_noncegen$function$
;
GRANT EXECUTE ON FUNCTION vault._crypto_aead_det_noncegen() TO supabase_admin;
CREATE OR REPLACE FUNCTION vault.create_secret(new_secret text, new_name text DEFAULT NULL::text, new_description text DEFAULT ''::text, new_key_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  rec record;
BEGIN
  INSERT INTO vault.secrets (secret, name, description)
  VALUES (
    new_secret,
    new_name,
    new_description
  )
  RETURNING * INTO rec;
  UPDATE vault.secrets s
  SET secret = encode(vault._crypto_aead_det_encrypt(
    message := convert_to(rec.secret, 'utf8'),
    additional := convert_to(s.id::text, 'utf8'),
    key_id := 0,
    context := 'pgsodium'::bytea,
    nonce := rec.nonce
  ), 'base64')
  WHERE id = rec.id;
  RETURN rec.id;
END
$function$
;
GRANT EXECUTE ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres;
GRANT EXECUTE ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;
GRANT EXECUTE ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO supabase_admin;
CREATE OR REPLACE FUNCTION vault.update_secret(secret_id uuid, new_secret text DEFAULT NULL::text, new_name text DEFAULT NULL::text, new_description text DEFAULT NULL::text, new_key_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  decrypted_secret text := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE id = secret_id);
BEGIN
  UPDATE vault.secrets s
  SET
    secret = CASE WHEN new_secret IS NULL THEN s.secret
                  ELSE encode(vault._crypto_aead_det_encrypt(
                    message := convert_to(new_secret, 'utf8'),
                    additional := convert_to(s.id::text, 'utf8'),
                    key_id := 0,
                    context := 'pgsodium'::bytea,
                    nonce := s.nonce
                  ), 'base64') END,
    name = coalesce(new_name, s.name),
    description = coalesce(new_description, s.description),
    updated_at = now()
  WHERE s.id = secret_id;
END
$function$
;
GRANT EXECUTE ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres;
GRANT EXECUTE ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;
GRANT EXECUTE ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO supabase_admin;
COMMIT;