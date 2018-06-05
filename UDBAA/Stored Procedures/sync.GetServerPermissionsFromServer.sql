SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [sync].[GetServerPermissionsFromServer]
    @serverName nvarchar(64)
  , @print tinyint = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ctx varbinary(128) = CAST(OBJECT_NAME(@@PROCID) AS varbinary(128));
    SET CONTEXT_INFO @ctx;

    DECLARE @sql    nvarchar(MAX)
          , @proc   nvarchar(MAX)
          , @domain nvarchar(64)
          , @rc     int;

    SET @proc = CONCAT(QUOTENAME(@serverName), '.', QUOTENAME(DB_NAME()), '.sys.sp_executesql');

    IF @print > 0
    BEGIN
        PRINT '';
        PRINT OBJECT_NAME(@@PROCID);
        PRINT CONCAT('@serverName: ', @serverName);
        PRINT CONCAT('@proc: ', @proc);
    END;


    /* prep remote structures */
    SET @sql = '
IF SCHEMA_ID(''tmp'') IS NULL EXEC(''CREATE SCHEMA [tmp]'');

IF OBJECT_ID(''[tmp].[dbo.ServerPermissions]'') IS NOT NULL EXEC(''DROP TABLE [tmp].[dbo.ServerPermissions]'');
SELECT TOP (0) * INTO [tmp].[dbo.ServerPermissions] FROM dbo.ServerPermissions;

SET @domain = DEFAULT_DOMAIN();
'   ;
    EXEC @proc @sql, N'@domain nvarchar(64) OUT', @domain = @domain OUT;
    IF @print > 1
        PRINT @sql;

    IF @print > 0
        PRINT CONCAT('@domain: ', @domain);

    /* get remote data */
    DELETE FROM remote.ServerPermissions
    WHERE RemoteDomainName = @domain
          AND RemoteServerName = @serverName;

    SET @sql = 'SELECT DEFAULT_DOMAIN(), @@SERVERNAME, * FROM dbo.ServerPermissions';
    INSERT remote.ServerPermissions
    EXEC @proc @sql;
    SET @rc = @@ROWCOUNT;
    IF @print > 0
        PRINT CONCAT('get records: ', @rc);

    /* persist new records */
    WITH r AS (
        SELECT RowId
             , DomainName
             , ServerName
             , Persona
             , Permission
             , IsActive
        FROM remote.ServerPermissions
        WHERE RemoteDomainName = @domain
              AND RemoteServerName = @serverName
              AND DomainName = @domain
              AND ServerName = @serverName
    )
    INSERT INTO dbo.ServerPermissions
    SELECT r.*
    FROM r
        LEFT JOIN dbo.ServerPermissions AS c
            ON c.RowId = r.RowId
               -- join by PK is here to resolve duplicates
               OR
               (
                   c.DomainName = r.DomainName
                   AND c.ServerName = r.ServerName
                   AND c.Persona = r.Persona
                   AND c.Permission = r.Permission
               )
    WHERE c.RowId IS NULL;
    SET @rc = @@ROWCOUNT;

    IF @print > 0
        PRINT CONCAT('new records: ', @rc);

END;

GO
