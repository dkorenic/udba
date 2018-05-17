SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [sync].[GetLoginsFromServer] @serverName nvarchar(64)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ctx varbinary(128) = CAST(OBJECT_NAME(@@PROCID) AS varbinary(128));
    SET CONTEXT_INFO @ctx;

    DECLARE @sql    nvarchar(MAX)
          , @proc   nvarchar(MAX)
          , @domain nvarchar(64);

    SET @proc = CONCAT(QUOTENAME(@serverName), '.', QUOTENAME(DB_NAME()), '.sys.sp_executesql');

    /* prep remote structures */
    SET @sql = '
IF SCHEMA_ID(''tmp'') IS NULL EXEC(''CREATE SCHEMA [tmp]'');
IF OBJECT_ID(''[tmp].[Logins]'') IS NOT NULL EXEC(''DROP TABLE [tmp].[Logins]'');
SELECT TOP (0) * INTO [tmp].[Logins] FROM dbo.Logins;

SET @domain = DEFAULT_DOMAIN();
'   ;
    EXEC @proc @sql, N'@domain nvarchar(64) OUT', @domain = @domain OUT;


    /* get remote data */
    DELETE FROM remote.Logins
    WHERE RemoteDomainName = @domain
          AND RemoteServerName = @serverName;

    SET @sql = 'SELECT DEFAULT_DOMAIN(), @@SERVERNAME, * FROM dbo.Logins';
    INSERT remote.Logins
    EXEC @proc @sql;

    /* persist new records */
    WITH r AS (
        SELECT RowId
             , DomainName
             , ServerName
             , Persona
             , LoginName
             , LoginSystemType
             , LoginSID
             , LoginPasswordHash
             , IsActive
             , LoginPasswordLastSetTimeUtc
        FROM remote.Logins
        WHERE RemoteDomainName = @domain
              AND RemoteServerName = @serverName
              AND DomainName = @domain
              AND ServerName = @serverName
    )
    INSERT INTO dbo.Logins
    SELECT r.*
    FROM r
        LEFT JOIN dbo.Logins AS c
            ON c.RowId = r.RowId
               -- join by PK is here to resolve duplicates
               OR
               (
                   c.DomainName = r.DomainName
                   AND c.ServerName = r.ServerName
                   AND c.Persona = r.Persona
                   AND c.LoginName = r.LoginName
               )
    WHERE c.RowId IS NULL;

    /* persist pasword changes */
    WITH r AS (
        SELECT *
        FROM remote.Logins
        WHERE RemoteDomainName = @domain
              AND RemoteServerName = @serverName
    )
    UPDATE c
    SET c.LoginPasswordHash = r.LoginPasswordHash
      , c.LoginPasswordLastSetTimeUtc = r.LoginPasswordLastSetTimeUtc
    FROM r
        JOIN dbo.Logins AS c
            ON c.RowId = r.RowId
    WHERE r.LoginPasswordHash != c.LoginPasswordHash
          AND r.LoginPasswordLastSetTimeUtc > c.LoginPasswordLastSetTimeUtc;

END;
GO
