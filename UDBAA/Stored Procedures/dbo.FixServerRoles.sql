SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[FixServerRoles]
    @roleLike sysname = '%'
  , @createUnused bit = 0
  , @dropUnused bit = 0
  --
  , @debug tinyint = 0
  , @print tinyint = 0
  , @dryRun bit = 1
AS
SET NOCOUNT ON;

WITH s AS (
    SELECT default_domain() AS DomainName
         , p.NAME           AS RoleName
         , p.is_fixed_role  AS IsFixed
    FROM sys.server_principals AS p
    WHERE 1 = 1
          AND p.TYPE = 'R'
          AND p.NAME LIKE @roleLike
          AND LEN(p.SID) > 1
)
SELECT *
INTO #FxSeRo
FROM s;

IF @debug > 1
    SELECT *
    FROM #FxSeRo;

IF @debug > 0
    WITH d AS (
        SELECT *
        FROM #FxSeRo
    )
       , s AS (
        SELECT *
             , ServerPermissions + ServerRoleMembers AS UsageCount
        FROM dbo.FilteredServerRolesEx
        WHERE PriorityRank = 1
              AND RoleName LIKE @roleLike
              AND IsActive IS NOT NULL
    )
    SELECT *
    FROM s
        LEFT JOIN d
            ON 1 = 1
               AND d.RoleName = s.RoleName;

DECLARE @sRoleName   nvarchar(64) = ''
      , @sDomainName nvarchar(64)
      , @sIsActive   bit
      , @sUsageCount int
      --
      , @dRoleName   nvarchar(64)
      , @dDomainName nvarchar(64)
      , @dIsFixed    bit
      --
      , @sql         nvarchar(MAX);


WHILE 1 = 1
BEGIN
    WITH d AS (
        SELECT *
        FROM #FxSeRo
    )
       , s AS (
        SELECT *
             , ServerPermissions + ServerRoleMembers AS UsageCount
        FROM dbo.FilteredServerRolesEx
        WHERE PriorityRank = 1
              AND RoleName LIKE @roleLike
              AND IsActive IS NOT NULL
    )
    SELECT TOP 1
        @sRoleName   = s.RoleName
      , @sDomainName = s.DomainName
      , @sIsActive   = s.IsActive
      , @sUsageCount = s.UsageCount
      --
      , @dRoleName   = d.RoleName
      , @dDomainName = d.DomainName
      , @dIsFixed    = d.IsFixed
    FROM s
        LEFT JOIN d
            ON 1 = 1
               AND d.RoleName = s.RoleName
    WHERE s.RoleName > @sRoleName
          AND
          (
              -- no role on server and IsActive in config
              (
                  s.IsActive = 1
                  AND d.RoleName IS NULL
                  AND
                  (
                      @createUnused = 1
                      OR s.UsageCount > 0
                  )
              )
              -- has nonfixed role but IsActive is FALSE in config
              OR
              (
                  s.IsActive = 0
                  AND d.RoleName IS NOT NULL
                  AND d.IsFixed = 0
              )
              -- has role and is active but is unused
              OR
              (
                  @dropUnused = 1
                  AND s.IsActive = 1
                  AND s.UsageCount = 0
                  AND d.RoleName IS NOT NULL
                  AND d.IsFixed = 0
              )
          )
    ORDER BY s.RoleName;
    IF @@ROWCOUNT = 0
        BREAK;

    IF @print > 1
    BEGIN
        PRINT CONCAT('@sRoleName						= ', @sRoleName);
        PRINT CONCAT('@dRoleName						= ', @dRoleName);

        PRINT CONCAT('@sDomainName					= ', @sDomainName);
        PRINT CONCAT('@dDomainName					= ', @dDomainName);

        PRINT CONCAT('@sIsActive						= ', @sIsActive);

        PRINT CONCAT('@sUsageCount					= ', @sUsageCount);
    END;

    -- no role on server and IsActive in config
    IF (@sIsActive = 1 AND @dRoleName IS NULL AND (@createUnused = 1 OR @sUsageCount > 0))
    BEGIN
        SET @sql = CONCAT('CREATE SERVER ROLE ', QUOTENAME(@sRoleName));

        IF @print > 0
            PRINT @sql;

        IF @dryRun = 0
            EXEC (@sql);
    END;
    -- has nonfixed role but IsActive is FALSE in config
    ELSE IF (@sIsActive = 0 AND @dRoleName IS NOT NULL AND @dIsFixed = 0)
    BEGIN
        SET @sql = CONCAT('DROP SERVER ROLE ', QUOTENAME(@sRoleName));

        IF @print > 0
            PRINT @sql;

        IF @dryRun = 0
            EXEC (@sql);
    END;
    -- has role and is active but is unused
    ELSE IF (@dropUnused = 1 AND @sIsActive = 1 AND @sUsageCount = 0 AND @dRoleName IS NOT NULL AND @dIsFixed = 0)
    BEGIN
        SET @sql = CONCAT('DROP SERVER ROLE ', QUOTENAME(@sRoleName));

        IF @print > 0
            PRINT @sql;

        IF @dryRun = 0
            EXEC (@sql);
    END;
    ELSE
    BEGIN
        PRINT 'Skipping!';
    END;

	PRINT '';
END;

GO
