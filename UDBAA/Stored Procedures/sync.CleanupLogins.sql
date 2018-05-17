SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [sync].[CleanupLogins]
AS
SET NOCOUNT ON;

DECLARE @ctx varbinary(128) = CAST(OBJECT_NAME(@@PROCID) AS varbinary(128));
SET CONTEXT_INFO @ctx;


WITH ds AS (
    SELECT DISTINCT
        DomainName
      , ServerName
    FROM dbo.Logins
    WHERE DomainName != ''
          AND ServerName != ''
)
--SELECT *
DELETE l
FROM ds
    CROSS APPLY
(
    SELECT l.RowId
         , l.DomainName
         , l.ServerName
         , l.Persona
         , l.LoginName
         , l.LoginSystemType
         , l.LoginSID
         , l.LoginPasswordHash
         , l.LoginPasswordLastSetTimeUtc
         , l.IsActive
         , DENSE_RANK() OVER (PARTITION BY l.Persona
                                         , l.LoginName
                              ORDER BY CASE WHEN l.IsActive = 0 THEN 1 WHEN l.IsActive = 1 THEN 2 ELSE 3 END
                                     , l.DomainName DESC
                             )                                 AS PriorityRank
         , DENSE_RANK() OVER (ORDER BY l.Persona, l.LoginName) AS PriorityGroup
    FROM dbo.Logins AS l
    WHERE 1 = 1
          AND l.DomainName IN ( '', ds.DomainName )
          AND l.ServerName IN ( '', ds.ServerName )
) AS l
WHERE l.PriorityRank > 1
      AND ds.DomainName = l.DomainName
      AND ds.ServerName = l.ServerName;
/*
ORDER BY ds.DomainName
       , ds.ServerName
       , l.Persona
       , l.LoginName;
*/

GO
