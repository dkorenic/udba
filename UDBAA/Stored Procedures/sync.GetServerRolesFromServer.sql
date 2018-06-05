SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [sync].[GetServerRolesFromServer] @serverName nvarchar(64)
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

IF OBJECT_ID(''[tmp].[dbo.ServerRoles]'') IS NOT NULL EXEC(''DROP TABLE [tmp].[dbo.ServerRoles]'');
SELECT TOP (0) * INTO [tmp].[dbo.ServerRoles] FROM dbo.ServerRoles;

SET @domain = DEFAULT_DOMAIN();
'   ;
    EXEC @proc @sql, N'@domain nvarchar(64) OUT', @domain = @domain OUT;


    /* get remote data */
    DELETE FROM remote.ServerRoles
    WHERE RemoteDomainName = @domain
          AND RemoteServerName = @serverName;

    SET @sql = 'SELECT DEFAULT_DOMAIN(), @@SERVERNAME, * FROM dbo.ServerRoles';
    INSERT remote.ServerRoles
    EXEC @proc @sql;

    /* persist new records */
    WITH r AS (
        SELECT RowId
             , DomainName
             , RoleName
             , IsActive
        FROM remote.ServerRoles
        WHERE RemoteDomainName = @domain
              AND RemoteServerName = @serverName
              AND DomainName = @domain
    )
    INSERT INTO dbo.ServerRoles
    SELECT r.*
    FROM r
        LEFT JOIN dbo.ServerRoles AS c
            ON c.RowId = r.RowId
               -- join by PK is here to resolve duplicates
               OR
               (
                   c.DomainName = r.DomainName
                   AND c.RoleName = r.RoleName
               )
    WHERE c.RowId IS NULL;

END;

GO
