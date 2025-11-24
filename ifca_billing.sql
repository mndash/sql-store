-- Guide
-- Update Year in with current year
Declare @Qcost AS int = 75 -- Quarterly
Declare @Mcost As int =25 --Monthly cost

SELECT IFCA, SUM(Q1_payment + Q2_payment + Q3_payment + Q4_payment) AS Annual_Payment
FROM(

SELECT 
*, 
CASE WHEN FirstReg between '2024-01-01'and'2024-03-31' THEN datediff(month,FirstReg,'2024-4-01')*@Mcost   
 WHEN FirstReg<'2024-01-01' THEN @Qcost  
 END AS Q1_payment,  
CASE WHEN FirstReg between '2024-04-01'and'2024-06-30' THEN datediff(month,FirstReg,'2024-7-01')*@Mcost   
 WHEN FirstReg <'2024-04-01' THEN @Qcost   
 END AS Q2_payment,  
CASE WHEN FirstReg between '2024-07-01'and'2024-09-30' THEN datediff(month,FirstReg,'2024-10-01')*@Mcost   
 WHEN FirstReg <'2024-07-01' THEN @Qcost   
 END AS Q3_payment,  
CASE WHEN FirstReg between '2024-10-01'and'2024-12-31' THEN datediff(month,FirstReg,'2025-01-01')*@Mcost   
     WHEN FirstReg <'2024-10-01' THEN @Qcost   
 END AS Q4_payment
FROM(

SELECT u.LogonID,StaffStdName, Forename, Email, CONVERT(Date, FirstReg) AS FirstReg,count(p.permit)Permits,
case when u.logonid = 'SRP01' then 'SOUTHERN IFCA' else
portname end as IFCA

FROM sfm.dbo.users u
join sfm.dbo.UsersPermits p  on p.LogonID=u.LogonID
join sfm.dbo.port t on t.port = u.Port
WHERE CefasGroup = 'IFCA'
AND DisableUser = 0
AND u.LogonID NOT LIKE 'X%'
AND u.LogonID NOT LIKE 'Z%'
and StaffStdName not like 'keable'
group by u.LogonID,StaffStdName, Forename, Email,FirstReg,portname
having count(p.permit)>1 --what's p.permit
) AS sub
)AS Individual_payment
GROUP BY IFCA
