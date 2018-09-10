SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[FixLogins]
    @loginLike sysname = '%'
  , @types nvarchar(16) = 'SUG'
  , @createUnused bit = 1
  , @dropUnused bit = 0
  , @doDrop bit = 0
  , @doChangePassword bit = 0
  --
  , @debug tinyint = 0
  , @print tinyint = 0
  , @dryRun bit = 0
AS
SET NOCOUNT ON;

DECLARE @error nvarchar(MAX);

WITH s AS (
    SELECT DEFAULT_DOMAIN()                                                                  AS DomainName
         , @@SERVERNAME                                                                      AS ServerName
         , IIF(p.TYPE = 'S', p.NAME, SUBSTRING(p.NAME, CHARINDEX('\', p.NAME) + 1, 64))      AS Persona
         , p.NAME COLLATE DATABASE_DEFAULT                                                   AS LoginName
         , p.TYPE COLLATE DATABASE_DEFAULT                                                   AS LoginSystemType
         , CONVERT(varchar(172), IIF(p.TYPE = 'S', p.SID, NULL), 1) COLLATE DATABASE_DEFAULT AS LoginSID
         , pp.PasswordHash                                                                   AS LoginPasswordHash
         , pp.PasswordLastSetTimeUtc                                                         AS LoginPasswordLastSetTimeUtc
    FROM sys.server_principals AS p
        OUTER APPLY
    (
        SELECT CONVERT(varchar(514), CAST(LOGINPROPERTY(p.name, 'PasswordHash') AS varbinary(256)), 1)                                         PasswordHash
             , DATEADD(MINUTE, -DATEDIFF(MINUTE, GETUTCDATE(), GETDATE()), CAST(LOGINPROPERTY(p.NAME, 'PasswordLastSetTime') AS datetime2(3))) PasswordLastSetTimeUtc
        WHERE p.TYPE = 'S'
    )                          pp
    WHERE @types LIKE CONCAT('%', p.TYPE, '%')
          AND p.NAME LIKE @loginLike
          AND is_disabled = 0
          AND LEN(p.SID) > 1
          AND p.NAME NOT LIKE '##MS%'
          AND
          (
              p.NAME NOT LIKE 'NT SERVICE\%'
              OR p.TYPE NOT IN ( 'U', 'G' )
          )
          AND
          (
              p.NAME NOT LIKE 'NT AUTHORITY\%'
              OR p.TYPE NOT IN ( 'U', 'G' )
          )
          --AND
          --(
          --    p.NAME LIKE (DEFAULT_DOMAIN() + '\%')
          --    OR p.TYPE NOT IN ( 'U', 'G' )
          --)
          AND
          (
              p.NAME != 'distributor_admin'
              OR p.TYPE NOT IN ( 'S' )
          )
)
SELECT *
INTO #FxLoLo
FROM s;

IF @debug > 1
    SELECT s.*
         , d.*
    FROM
    (
        SELECT *
        FROM dbo.FilteredLoginsEx
        WHERE PriorityRank = 1
              AND LoginName LIKE @loginLike
              AND
              (
                  IsActive = 0
                  OR IsActive = 1
                     AND
                     (
                         @createUnused = 1
                         OR @dropUnused = 1
                         OR DatabaseUsers > 0
                         OR ServerPermissions > 0
                         OR ServerRoleMembers > 0
                     )
              )
    )                           AS s
        FULL OUTER JOIN #FxLoLo AS d
            ON 1 = 1
               AND d.LoginName = s.LoginName;

DECLARE @sLoginName                   sysname = ''
      , @sDomainName                  nvarchar(64)
      , @sServerName                  nvarchar(64)
      , @sPersona                     nvarchar(64)
      , @sLoginSystemType             char(1)
      , @sLoginSID                    varchar(172)
      , @sLoginPasswordHash           varchar(514)
      , @sLoginPasswordLastSetTimeUtc datetime2(3)
      , @sIsActive                    bit
      , @sUsageCount                  int
      --
      , @dLoginName                   nvarchar(128)
      , @dDomainName                  nvarchar(64)
      , @dServerName                  nvarchar(64)
      , @dPersona                     nvarchar(64)
      , @dLoginSystemType             char(1)
      , @dLoginSID                    varchar(172)
      , @dLoginPasswordHash           varchar(514)
      , @dLoginPasswordLastSetTimeUtc datetime2(3)
--
;


WHILE 1 = 1
BEGIN
    WITH d AS (
        SELECT *
        FROM #FxLoLo
    )
       , s AS (
        SELECT *
             , DatabaseUsers + ServerPermissions + ServerRoleMembers AS UsageCount
        FROM dbo.FilteredLoginsEx
        WHERE PriorityRank = 1
              AND LoginName LIKE @loginLike
              AND IsActive IS NOT NULL
    )
    SELECT TOP 1
        @sLoginName                   = s.LoginName
      , @sDomainName                  = s.DomainName
      , @sServerName                  = s.ServerName
      , @sPersona                     = s.Persona
      , @sLoginSystemType             = s.LoginSystemType
      , @sLoginSID                    = s.LoginSID
      , @sLoginPasswordHash           = s.LoginPasswordHash
      , @sLoginPasswordLastSetTimeUtc = s.LoginPasswordLastSetTimeUtc
      , @sIsActive                    = s.IsActive
      , @sUsageCount                  = s.UsageCount
      --
      , @dLoginName                   = d.LoginName
      , @dDomainName                  = d.DomainName
      , @dServerName                  = d.ServerName
      , @dPersona                     = d.Persona
      , @dLoginSystemType             = d.LoginSystemType
      , @dLoginSID                    = d.LoginSID
      , @dLoginPasswordHash           = d.LoginPasswordHash
      , @dLoginPasswordLastSetTimeUtc = d.LoginPasswordLastSetTimeUtc
    FROM s
        LEFT JOIN d
            ON 1 = 1
               AND d.LoginName = s.LoginName
    WHERE s.LoginName > @sLoginName
          AND
          (
              @print > 2
              OR
              (
                  -- no login on server and IsActive in config
                  (
                      s.IsActive = 1
                      AND d.LoginName IS NULL
                      AND
                      (
                          @createUnused = 1
                          OR s.UsageCount > 0
                      )
                  )
                  -- has login but IsActive is FALSE in config
                  OR
                  (
                      s.IsActive = 0
                      AND d.LoginName IS NOT NULL
                  )
                  -- has login and is active but is unused
                  OR
                  (
                      @dropUnused = 1
                      AND s.IsActive = 1
                      AND s.UsageCount = 0
                      AND d.LoginName IS NOT NULL
                  )
                  -- password too old
                  OR
                  (
                      s.IsActive = 1
                      AND
                      (
                          (
                              d.LoginPasswordLastSetTimeUtc < s.LoginPasswordLastSetTimeUtc
                              AND d.LoginPasswordHash != s.LoginPasswordHash
                          )
                          OR
                          (
                              d.LoginSystemType = 'S'
                              AND d.LoginPasswordLastSetTimeUtc IS NULL
                          )
                      )
                  )
              )
          )
    ORDER BY s.LoginName;
    IF @@ROWCOUNT = 0
        BREAK;

    IF @print > 1
    BEGIN
        PRINT CONCAT('@sLoginName						= ', @sLoginName);
        PRINT CONCAT('@dLoginName						= ', @dLoginName);

        PRINT CONCAT('@sDomainName					= ', @sDomainName);
        PRINT CONCAT('@dDomainName					= ', @dDomainName);

        PRINT CONCAT('@sServerName					= ', @sServerName);
        PRINT CONCAT('@dServerName					= ', @dServerName);

        PRINT CONCAT('@sPersona						= ', @sPersona);
        PRINT CONCAT('@dPersona						= ', @dPersona);

        PRINT CONCAT('@sLoginSystemType				= ', @sLoginSystemType);
        PRINT CONCAT('@dLoginSystemType				= ', @dLoginSystemType);

        PRINT CONCAT('@sLoginSID						= ', @sLoginSID);
        PRINT CONCAT('@dLoginSID						= ', @dLoginSID);

        PRINT CONCAT('@sLoginPasswordHash				= ', @sLoginPasswordHash);
        PRINT CONCAT('@dLoginPasswordHash				= ', @dLoginPasswordHash);

        PRINT CONCAT('@sLoginPasswordLastSetTimeUtc	= ', @sLoginPasswordLastSetTimeUtc);
        PRINT CONCAT('@dLoginPasswordLastSetTimeUtc	= ', @dLoginPasswordLastSetTimeUtc);

        PRINT CONCAT('@sIsActive						= ', @sIsActive);

        PRINT CONCAT('@sUsageCount					= ', @sUsageCount);
    END;

    PRINT '';
    DECLARE @sql nvarchar(MAX) = '';

    -- fali - CREATE
    IF @sIsActive = 1
       AND @dLoginName IS NULL
       AND
       (
           @createUnused = 1
           OR @sUsageCount > 0
       )
    BEGIN
        IF @sLoginSystemType = 'S'
            SET @sql = CONCAT('CREATE LOGIN ', QUOTENAME(@sLoginName), ' WITH PASSWORD = ', @sLoginPasswordHash, ' HASHED, SID = ', @sLoginSID, ', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;');
        ELSE
            SET @sql = CONCAT('CREATE LOGIN ', QUOTENAME(@sLoginName), ' FROM WINDOWS;');

        --PRINT @sql;

        IF @dryRun = 0
        BEGIN
            PRINT CONCAT('EXEC: ', @sql);
            BEGIN TRY
                EXEC (@sql);
                SET @error = '';
            END TRY
            BEGIN CATCH
                SET @error = ERROR_MESSAGE();
                THROW;
            END CATCH;
            INSERT INTO dbo.Log
            (
                DomainName
              , ServerName
              , RecordRowGuid
              , StoredProcedure
              , Operation
              , Description
              , Error
            )
            VALUES
            (DEFAULT_DOMAIN(), @@SERVERNAME, NULL, OBJECT_NAME(@@PROCID), N'CREATE LOGIN', @sql, @error);
        END;
        ELSE
            PRINT @sql;
    END;
    ELSE
    -- višak - DROP
    IF @dLoginName IS NOT NULL
       AND
       (
           @sIsActive = 0
           OR
           (
               @dropUnused = 1
               AND @sUsageCount = 0
           )
       )
    BEGIN
        SET @sql = CONCAT('DROP LOGIN ', QUOTENAME(@sLoginName), ';');

        IF ISNULL(@doDrop, 0) = 0
            PRINT CONCAT('SKIP: ', @sql);
        ELSE IF @dryRun = 0
                AND @doDrop = 1
        BEGIN
            PRINT CONCAT('EXEC: ', @sql);
            BEGIN TRY
                EXEC (@sql);
                SET @error = '';
            END TRY
            BEGIN CATCH
                SET @error = ERROR_MESSAGE();
                THROW;
            END CATCH;
            INSERT INTO dbo.LOG
            (
                DomainName
              , ServerName
              , RecordRowGuid
              , StoredProcedure
              , Operation
              , DESCRIPTION
              , ERROR
            )
            VALUES
            (DEFAULT_DOMAIN(), @@SERVERNAME, NULL, OBJECT_NAME(@@PROCID), N'DROP LOGIN', @sql, @error);
        END;
        ELSE
            PRINT @sql;
    END;
    ELSE
    -- noviji password - ALTER
    IF @sIsActive = 1
       AND @sLoginSystemType = 'S'
       AND @sLoginPasswordLastSetTimeUtc > @dLoginPasswordLastSetTimeUtc
       AND @sLoginPasswordHash != @dLoginPasswordHash
    BEGIN
        SET @sql = CONCAT('ALTER LOGIN ', QUOTENAME(@sLoginName), ' WITH PASSWORD = ', @sLoginPasswordHash, ' HASHED, CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;');

        IF ISNULL(@doChangePassword, 0) = 0
            PRINT CONCAT('SKIP: ', @sql);
        ELSE IF @dryRun = 0
                AND @doChangePassword = 1
        BEGIN
            PRINT CONCAT('EXEC: ', @sql);
            BEGIN TRY
                EXEC (@sql);
                SET @error = '';
            END TRY
            BEGIN CATCH
                SET @error = ERROR_MESSAGE();
                THROW;
            END CATCH;
            INSERT INTO dbo.LOG
            (
                DomainName
              , ServerName
              , RecordRowGuid
              , StoredProcedure
              , Operation
              , DESCRIPTION
              , ERROR
            )
            VALUES
            (DEFAULT_DOMAIN(), @@SERVERNAME, NULL, OBJECT_NAME(@@PROCID), N'ALTER LOGIN', @sql, @error);
        END;
        ELSE
            PRINT @sql;
    END;
    ELSE
    -- inače odjeb
    BEGIN
        PRINT 'Skipping!';
    END;

    PRINT '';
END;





GO
