SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[FilterServerRoleMembers]
(
    @domainName nvarchar(64) = ''
  , @serverName nvarchar(64) = ''
)
RETURNS table
AS
RETURN
(
        SELECT RowId
         , DomainName
         , ServerName
         , RoleName
         , Persona
         , IsActive
         , DENSE_RANK() OVER (PARTITION BY RoleName
                                         , Persona
                              ORDER BY CASE WHEN IsActive = 0 THEN 1 WHEN IsActive = 1 THEN 2 ELSE 3 END
                                     , ServerName DESC
                                     , DomainName DESC
                             )                            AS PriorityRank
         , DENSE_RANK() OVER (ORDER BY RoleName, Persona) AS PriorityGroup
    FROM dbo.ServerRoleMembers
    WHERE 1 = 1
          AND DomainName IN ( '', @domainName)
          AND ServerName IN ( '', @serverName )
);
GO
