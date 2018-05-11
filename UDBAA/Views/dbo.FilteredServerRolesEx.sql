SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/***************************************************************************************
* 
*	Data from dbo.ServerRoles filtered for current domain and server with added usage counts,
*	ranked by priority rules (IsActive=FALSE, IsActive=TRUE, IsActive IS UNKNOWN).
*
***************************************************************************************/
CREATE VIEW [dbo].[FilteredServerRolesEx]
AS
SELECT *
FROM dbo.FilteredServerRoles AS sr
    OUTER APPLY
(
    SELECT COUNT(1) AS ServerPermissions
    FROM dbo.FilteredServerPermissions AS sp
    WHERE sp.Persona = sr.RoleName
          AND sp.PriorityRank = 1
          AND sp.IsActive = 1
)                            AS sp
    OUTER APPLY
(
    SELECT COUNT(1) AS ServerRoleMembers
    FROM dbo.FilteredServerRoleMembers AS srm
        JOIN dbo.FilteredLogins        AS l
            ON l.Persona = srm.Persona
    WHERE srm.RoleName = sr.RoleName
          AND srm.PriorityRank = 1
          AND srm.IsActive = 1
          AND l.PriorityRank = 1
          AND l.IsActive = 1
) AS srm;

GO
