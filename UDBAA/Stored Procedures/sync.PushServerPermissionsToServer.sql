SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [sync].[PushServerPermissionsToServer]
    @serverName nvarchar(64)
  , @print tinyint = 0
  , @dryRun bit = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @print > 0
        PRINT CONCAT('@serverName: ', @serverName);

    DECLARE @ctx varbinary(128) = CAST(OBJECT_NAME(@@PROCID) AS varbinary(128));
    SET CONTEXT_INFO @ctx;

    IF @print > 0
    BEGIN
        PRINT '';
        PRINT OBJECT_NAME(@@PROCID);
    END;

    DECLARE @sql    nvarchar(MAX)
          , @proc   nvarchar(MAX)
          , @domain nvarchar(64)
          , @rc     int;

    SET @proc = CONCAT(QUOTENAME(@serverName), '.', QUOTENAME(DB_NAME()), '.sys.sp_executesql');

    IF @print > 0
        PRINT CONCAT('@proc: ', @proc);


    /* prep remote structures */
    SET @sql = '
IF SCHEMA_ID(''tmp'') IS NULL EXEC(''CREATE SCHEMA [tmp]'');

IF OBJECT_ID(''[tmp].[dbo.ServerPermissions]'') IS NOT NULL EXEC(''DROP TABLE [tmp].[dbo.ServerPermissions]'');
SELECT TOP (0) * INTO [tmp].[dbo.ServerPermissions] FROM dbo.ServerPermissions;

SET @domain = DEFAULT_DOMAIN();
'   ;
    IF @print > 1
        PRINT @sql;
    IF @dryRun = 0
        EXEC @proc @sql, N'@domain nvarchar(64) OUT', @domain = @domain OUT;

    IF @print > 0
        PRINT CONCAT('@domain: ', @domain);

    /* push filtered ServerPermissions */
    SET @sql = CONCAT('INSERT INTO ', QUOTENAME(@serverName), '.', QUOTENAME(DB_NAME()), '.[tmp].[dbo.ServerPermissions] SELECT * FROM dbo.ServerPermissions t WHERE t.RowId IN (SELECT RowId FROM dbo.FilterServerPermissions(@domain, @serverName) t); SET @rc = @@ROWCOUNT;');
    IF @print > 1
        PRINT @sql;
    IF @dryRun = 0
        EXEC sys.sp_executesql @sql
                             , N'@domain nvarchar(64), @serverName nvarchar(64), @rc int OUT'
                             , @domain = @domain
                             , @serverName = @serverName
                             , @rc = @rc OUT;
    IF @print > 0
        PRINT CONCAT('pushed: ', @rc);

    /* merge pushed ServerPermissions */
    SET @sql = CONCAT(CAST('' AS nvarchar(MAX)), '
	DECLARE @actions TABLE (act nvarchar(10));

	WITH d AS (
        SELECT *
             , CHECKSUM(*) AS _chk
        FROM dbo.ServerPermissions
    )
       , s AS (
        SELECT *
             , CHECKSUM(*) AS _chk
        FROM [tmp].[dbo.ServerPermissions]
    )
	-- SELECT * FROM s JOIN d ON d.RowId = s.RowId;
    MERGE INTO d
    USING s
    ON d.RowId = s.RowId
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (RowId, DomainName, ServerName, Persona, State, Permission, Target, IsActive) VALUES
               (s.RowId, s.DomainName, s.ServerName, s.Persona, s.State, s.Permission, s.Target, s.IsActive)
    WHEN MATCHED AND d._chk != s._chk THEN
        UPDATE SET d.DomainName = s.DomainName
                 , d.ServerName = s.ServerName

                 , d.Persona = s.Persona

				 , d.State = s.State
                 , d.Permission = s.Permission
				 , d.Target = s.Target

                 , d.IsActive = s.IsActive
    WHEN NOT MATCHED BY SOURCE THEN DELETE
	OUTPUT $action INTO @actions (act)
	;

	SELECT 
		@deleted = ISNULL(SUM(IIF(act = ''DELETE'', 1, 0)), 0), 
		@updated = ISNULL(SUM(IIF(act = ''UPDATE'', 1, 0)), 0), 
		@inserted = ISNULL(SUM(IIF(act = ''INSERT'', 1, 0)), 0)
	FROM 
		@actions

	');
    IF @print > 1
        PRINT @sql;
    
	DECLARE @deleted  int
          , @updated  int
          , @inserted int;

    IF @dryRun = 0
	BEGIN
        EXEC @proc @sql
                 , N'@deleted int OUT, @updated int OUT, @inserted int OUT'
                 , @deleted = @deleted OUT
                 , @updated = @updated OUT
                 , @inserted = @inserted OUT;

		IF @print > 0
		BEGIN
			PRINT CONCAT('@deleted: ', @deleted);
			PRINT CONCAT('@updated: ', @updated);
			PRINT CONCAT('@inserted: ', @inserted);
		END
	END
END;



GO
