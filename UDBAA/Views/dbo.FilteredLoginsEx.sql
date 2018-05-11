SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/***************************************************************************************
* 
*	Data from dbo.Logins filtered for current domain and server with added usage counts,
*	ranked by priority rules (IsActive=FALSE, IsActive=TRUE, IsActive IS UNKNOWN).
*
***************************************************************************************/
CREATE VIEW [dbo].[FilteredLoginsEx]
AS
SELECT *
FROM dbo.FilteredLogins AS l
    OUTER APPLY
(
    SELECT COUNT(1) AS DatabaseUsers
    FROM dbo.FilteredDatabaseUsers AS du
    WHERE du.Persona = l.Persona
          AND du.PriorityRank = 1
          AND du.IsActive = 1
)                       AS du
    OUTER APPLY
(
    SELECT COUNT(1) AS ServerPermissions
    FROM dbo.FilteredServerPermissions AS sp
    WHERE sp.Persona = l.Persona
          AND sp.PriorityRank = 1
          AND sp.IsActive = 1
) AS sp
    OUTER APPLY
(
    SELECT COUNT(1) AS ServerRoleMembers
    FROM dbo.FilteredServerRoleMembers AS srm
    WHERE srm.Persona = l.Persona
          AND srm.PriorityRank = 1
          AND srm.IsActive = 1
) AS srm;

GO
