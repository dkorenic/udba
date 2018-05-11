SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PickupServerRoles]
    @roleLike sysname = '%'
  , @debug tinyint = 2
  , @print tinyint = 2
  , @dryRun bit = 0
AS
SET NOCOUNT ON;

WITH e AS (
    SELECT p.name AS ExistingRoleName
    FROM sys.server_principals AS p
    WHERE 1 = 1
          AND p.type = 'R'
          AND p.name LIKE @roleLike
          AND p.is_disabled = 0
          AND p.is_fixed_role = 0
          AND LEN(p.sid) > 1
)
   , c AS (
    SELECT *
    FROM dbo.FilteredServerRoles
    WHERE PriorityRank = 1
)
SELECT e.ExistingRoleName
     , c.DomainName
     , c.RoleName
     , c.IsActive
     , c.PriorityRank
     , c.PriorityGroup
INTO #PiSeRoLo
FROM e
    LEFT JOIN c
        ON e.ExistingRoleName = c.RoleName
WHERE 1 = 1
--AND c.RoleName IS NULL
;

IF @debug > 1
    SELECT *
    FROM #PiSeRoLo;
ELSE IF @debug > 0
    SELECT *
    FROM #PiSeRoLo
    WHERE RoleName IS NULL;


IF @dryRun = 0
BEGIN
    INSERT INTO dbo.ServerRoles
    (
        DomainName
      , RoleName
      , IsActive
    )
    --OUTPUT Inserted.*
    SELECT DEFAULT_DOMAIN()
         , s.ExistingRoleName
         , NULL
    FROM #PiSeRoLo AS s
    WHERE s.RoleName IS NULL;
END;


GO
