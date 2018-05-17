SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [sync].[PushLoginsToServer] @serverName nvarchar(64)
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
	/*
    DELETE FROM remote.Logins
    WHERE RemoteDomainName = @domain
          AND RemoteServerName = @serverName;
    SET @sql = 'SELECT DEFAULT_DOMAIN(), @@SERVERNAME, * FROM dbo.Logins';
    INSERT remote.Logins
    EXEC @proc @sql;
	*/


    SET @sql = CONCAT('INSERT INTO ', QUOTENAME(@serverName), '.', QUOTENAME(DB_NAME()), '.[tmp].[Logins] SELECT * FROM dbo.Logins WHERE RowId IN (SELECT RowId FROM dbo.FilterLogins(@domain, @serverName))');
    --PRINT @sql;
    EXEC sys.sp_executesql @sql, N'@domain nvarchar(64), @serverName nvarchar(64)', @domain = @domain, @serverName = @serverName;

    /*
    SET @sql = CONCAT('SELECT * FROM ', QUOTENAME(@serverName), '.', QUOTENAME(DB_NAME()), '.[tmp].[Logins]');
    PRINT @sql;
    EXEC (@sql);
	RETURN;
	*/

    SET @sql = CONCAT(CAST('' AS nvarchar(MAX)), 'WITH d AS (
        SELECT *
             , CHECKSUM(*) AS _chk
        FROM dbo.Logins
    )
       , s AS (
        SELECT *
             , CHECKSUM(*) AS _chk
        FROM [tmp].[Logins]
    )
	-- SELECT * FROM s JOIN d ON d.RowId = s.RowId;
    MERGE INTO d
    USING s
    ON d.RowId = s.RowId
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (RowId, DomainName, ServerName, Persona, LoginName, LoginSystemType, LoginSID, LoginPasswordHash, IsActive, LoginPasswordLastSetTimeUtc) VALUES
               (s.RowId, s.DomainName, s.ServerName, s.Persona, s.LoginName, s.LoginSystemType, s.LoginSID, s.LoginPasswordHash, s.IsActive, s.LoginPasswordLastSetTimeUtc)
    WHEN MATCHED AND d._chk != s._chk THEN
        UPDATE SET d.DomainName = s.DomainName
                 , d.ServerName = s.ServerName
                 , d.Persona = s.Persona
                 , d.LoginName = s.LoginName
                 , d.LoginSystemType = s.LoginSystemType
                 , d.LoginSID = s.LoginSID
                 , d.LoginPasswordHash = s.LoginPasswordHash
                 , d.IsActive = s.IsActive
                 , d.LoginPasswordLastSetTimeUtc = s.LoginPasswordLastSetTimeUtc
    WHEN NOT MATCHED BY SOURCE THEN DELETE
	;');
    --PRINT @sql;
    EXEC @proc @sql;
END;
GO
