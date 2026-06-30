-- ============================================================
-- Whisperia: 00_setup_user.sql
-- Run this script as SYSDBA to set up the 'utsa' user
-- ============================================================
-- Connect: sqlplus sys/password@localhost:1521/XEPDB1 as sysdba
-- ============================================================

-- Grant necessary privileges to the utsa user
ALTER USER utsa QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION TO utsa;
GRANT CREATE TABLE TO utsa;
GRANT CREATE SEQUENCE TO utsa;
GRANT CREATE TRIGGER TO utsa;
GRANT CREATE PROCEDURE TO utsa;
GRANT CREATE VIEW TO utsa;
GRANT CREATE TYPE TO utsa;

-- Confirm grants
SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE = 'UTSA';
