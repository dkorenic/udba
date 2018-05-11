SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[FilterLogins]
(
    @domainName nvarchar(64) = ''
  , @serverName nvarchar(64) = ''
)
RETURNS table
AS
RETURN
(
    SELECT DomainName
         , ServerName
         , Persona
         , LoginName
         , LoginSystemType
         , LoginSID
         , LoginPasswordHash
         , LoginPasswordLastSetTimeUtc
         , IsActive
         , DENSE_RANK() OVER (PARTITION BY Persona
                                         , LoginName
                              ORDER BY CASE WHEN IsActive = 0 THEN 1 WHEN IsActive = 1 THEN 2 ELSE 3 END
                                     , DomainName DESC
                             )                             AS PriorityRank
         , DENSE_RANK() OVER (ORDER BY Persona, LoginName) AS PriorityGroup
    FROM dbo.Logins
    WHERE 1 = 1
          AND DomainName IN ( '', @domainName )
          AND ServerName IN ( '', @serverName )
);
GO
