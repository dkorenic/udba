SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[FixServerRoleMembers]
    @debug tinyint = 0
  , @print tinyint = 0
  , @dryRun bit = 0
  , @doRemove bit = 0
AS
SET NOCOUNT ON;

DECLARE @roleName         sysname = ''
      , @memberName       sysname
      , @isActive         bit
      , @countRoleMembers int
      , @countRoles       int
      , @countMembers     int
      , @sql              nvarchar(MAX);

IF @debug > 0
    WITH d AS (
        SELECT r.name AS RoleName
             --, srm.*
             , m.name AS MemberName
        FROM sys.server_role_members             AS srm
            JOIN sys.server_principals           AS r
                ON r.principal_id = srm.role_principal_id
            JOIN dbo.InterestingServerPrincipals AS m
                ON srm.member_principal_id = m.principal_id
        WHERE 1 = 1
    )
       , c AS (
        SELECT srm.RoleName
             , srm.Persona                                                                                                                    AS Persona
             , srm.IsActive                                                                                                                   AS [srm.IsActive]
             , l.LoginName
             , l.IsActive                                                                                                                     AS [l.IsActive]
             --
             , COALESCE(l.LoginName, srm.Persona)                                                                                             AS MemberName
             , CAST(CASE WHEN srm.IsActive = 1 AND l.IsActive = 1 THEN 1 WHEN srm.IsActive = 0 OR l.IsActive = 0 THEN 0 ELSE NULL END AS bit) AS IsActive
        FROM dbo.FilteredServerRoleMembers AS srm
            LEFT JOIN dbo.FilteredLogins   AS l
                ON l.Persona = srm.Persona
                   AND l.PriorityRank = 1
        WHERE 1 = 1
              AND srm.PriorityRank = 1
    )
    SELECT c.RoleName
         , c.Persona
         , c.[srm.IsActive]
         , c.LoginName
         , c.[l.IsActive]
         , c.MemberName
         , c.IsActive
         --
         , d.CountRoleMembers
         , r.CountRoles
         , m.CountMembers
    FROM c
        OUTER APPLY
    (SELECT COUNT(1) AS CountRoleMembers FROM d WHERE c.RoleName = d.RoleName AND d.MemberName = c.MemberName) AS d
        OUTER APPLY
    (SELECT COUNT(1) AS CountRoles FROM sys.server_principals AS r WHERE c.RoleName = r.name) AS r
        OUTER APPLY
    (SELECT COUNT(1) AS CountMembers FROM sys.server_principals AS m WHERE c.MemberName = m.name) AS m
    WHERE 1 = 1
    ORDER BY c.RoleName
           , c.MemberName;

WHILE 1 = 1
BEGIN
    WITH d AS (
        SELECT r.name AS RoleName
             , m.name AS MemberName
        FROM sys.server_role_members             AS srm
            JOIN sys.server_principals           AS r
                ON r.principal_id = srm.role_principal_id
            JOIN dbo.InterestingServerPrincipals AS m
                ON srm.member_principal_id = m.principal_id
        WHERE 1 = 1
    )
       , c AS (
        SELECT srm.RoleName
             , srm.Persona                                                                                                                    AS Persona
             , srm.IsActive                                                                                                                   AS [srm.IsActive]
             , l.LoginName
             , l.IsActive                                                                                                                     AS [l.IsActive]
             --
             , COALESCE(l.LoginName, srm.Persona)                                                                                             AS MemberName
             , CAST(CASE WHEN srm.IsActive = 1 AND l.IsActive = 1 THEN 1 WHEN srm.IsActive = 0 OR l.IsActive = 0 THEN 0 ELSE NULL END AS bit) AS IsActive
        FROM dbo.FilteredServerRoleMembers AS srm
            LEFT JOIN dbo.FilteredLogins   AS l
                ON l.Persona = srm.Persona
                   AND l.PriorityRank = 1
        WHERE 1 = 1
              AND srm.PriorityRank = 1
    )
    --SELECT * FROM d;
    SELECT TOP 1
        @roleName         = c.RoleName
      , @memberName       = c.MemberName
      , @isActive         = c.IsActive
      , @countRoleMembers = d.CountRoleMembers
      , @countRoles       = r.CountRoles
      , @countMembers     = m.CountMembers
    FROM c
        OUTER APPLY
    (SELECT COUNT(1) AS CountRoleMembers FROM d WHERE c.RoleName = d.RoleName AND d.MemberName = c.MemberName) AS d
        OUTER APPLY
    (SELECT COUNT(1) AS CountRoles FROM sys.server_principals AS r WHERE c.RoleName = r.name) AS r
        OUTER APPLY
    (SELECT COUNT(1) AS CountMembers FROM sys.server_principals AS m WHERE c.MemberName = m.name) AS m
    WHERE 1 = 1
          AND
          (
              c.RoleName > @roleName
              OR
              (
                  c.RoleName = @roleName
                  AND c.MemberName > @memberName
              )
          )
          AND
          (
              1 = 0
              OR
              (
                  c.IsActive = 1
                  AND d.CountRoleMembers = 0
              )
              OR
              (
                  c.IsActive = 0
                  AND d.CountRoleMembers > 0
              )
          )
    --AND r.CountRoles > 0
    --AND m.CountMembers > 0
    ORDER BY c.RoleName
           , c.MemberName;
    IF @@ROWCOUNT = 0
        BREAK;

    IF @print > 1
    BEGIN
        PRINT CONCAT('@roleName:	', @roleName);
        PRINT CONCAT('@memberName:	', @memberName);
        PRINT CONCAT('@isActive:	', @isActive);
    END;

    IF @isActive = 1
       AND @countMembers > 0
       AND @countRoles > 0
    BEGIN
        SET @sql = CONCAT('ALTER SERVER ROLE ', QUOTENAME(@roleName), ' ADD MEMBER ', QUOTENAME(@memberName), ';');

        IF @print > 0
            PRINT @sql;

        IF @dryRun = 0
            EXEC (@sql);
    END;
    ELSE IF @isActive = 0
    BEGIN
        SET @sql = CONCAT('ALTER SERVER ROLE ', QUOTENAME(@roleName), ' DROP MEMBER ', QUOTENAME(@memberName), ';');

        IF @print > 0
            PRINT @sql;

        IF @dryRun = 0
           AND @doRemove = 1
        BEGIN
            PRINT CONCAT('EXEC: ', @sql);
            EXEC (@sql);
        END;
        ELSE
            PRINT CONCAT('SKIP: ', @sql);
    END;
    ELSE IF @isActive = 1
            AND @countMembers = 0
            AND @print > 0
    BEGIN
        PRINT CONCAT('Skipping. Missing login: ', @memberName);
    END;
    ELSE IF @isActive = 1
            AND @countRoles = 0
            AND @print > 0
    BEGIN
        PRINT CONCAT('Skipping. Missing role: ', @roleName);
    END;

END;




GO
