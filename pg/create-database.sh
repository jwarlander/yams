#!/bin/sh

# YAMS database information.
COLLECTD_DB="collectd"
COLLECTD_USER="collectd"
WUI_USER="yams"

# Create the users, don't exit if they already exist.
createuser --no-superuser --no-createrole --login ${COLLECTD_USER}
createuser --no-superuser --no-createrole --login ${WUI_USER}

# Create the database.
createdb --owner=${COLLECTD_USER} collectd "YAMS Data Warehouse"

psql -v ON_ERROR_STOP=1 -d ${COLLECTD_DB} \
		-c "CREATE EXTENSION hstore;" || exit 1

# Create the schemas.
psql -v ON_ERROR_STOP=1 -d ${COLLECTD_DB} \
		-c "CREATE SCHEMA AUTHORIZATION ${COLLECTD_USER};" || exit 1
psql -v ON_ERROR_STOP=1 -d ${COLLECTD_DB} \
		-c "CREATE SCHEMA AUTHORIZATION ${WUI_USER};" || exit 1

psql -v ON_ERROR_STOP=1 -d ${COLLECTD_DB} \
		-c "GRANT USAGE ON SCHEMA ${COLLECTD_USER} TO ${WUI_USER}" || exit 1
psql -v ON_ERROR_STOP=1 -U ${COLLECTD_USER} -d ${COLLECTD_DB} \
		-c "ALTER DEFAULT PRIVILEGES IN SCHEMA ${COLLECTD_USER} GRANT SELECT ON TABLES TO ${WUI_USER};" || exit 1
psql -v ON_ERROR_STOP=1sql -d ${COLLECTD_DB} \
		-c "ALTER DEFAULT PRIVILEGES IN SCHEMA ${COLLECTD_DB}
			GRANT SELECT ON TABLES TO ${WUI_USER};" || exit 1

# Alter user details.
psql -v ON_ERROR_STOP=1 -U ${WUI_USER} -d ${COLLECTD_DB} \
		-c "ALTER USER ${WUI_USER}
			SET search_path TO \"\$user\",${COLLECTD_USER},public;" || exit 1

# Create the default tables.
psql -v ON_ERROR_STOP=1 -U ${COLLECTD_USER} -d ${COLLECTD_DB} << __EOF__
BEGIN;
CREATE TABLE value_list (
  time TIMESTAMP WITH TIME ZONE NOT NULL,
  interval INTEGER NOT NULL,
  host VARCHAR(64) NOT NULL,
  plugin VARCHAR(64) NOT NULL,
  plugin_instance VARCHAR(64),
  type VARCHAR(64) NOT NULL,
  type_instance VARCHAR(64),
  dsnames VARCHAR(512)[] NOT NULL,
  dstypes VARCHAR(8)[] NOT NULL,
  values NUMERIC[] NOT NULL,
  meta HSTORE NOT NULL DEFAULT ''
);
COMMIT;
__EOF__
