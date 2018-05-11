SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[FilteredServerPermissionsEx]
AS
SELECT *
FROM dbo.FilteredServerPermissions AS sp
    OUTER APPLY
(
    SELECT COUNT(1) AS ServerRoles
    FROM dbo.FilteredServerRoles AS sr
    WHERE sr.RoleName = sp.Persona
          AND sr.PriorityRank = 1
          AND sr.IsActive = 1
)                                  AS sr
    OUTER APPLY
(
    SELECT COUNT(1) AS Logins
    FROM dbo.FilteredLogins AS l
    WHERE l.Persona = sp.Persona
          AND l.PriorityRank = 1
          AND l.IsActive = 1
) AS l;

GO
