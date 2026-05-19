/*
====================================================================================
VMS – SALES NOTE – CATCH RECORD AUDIT (NEAREST‑DATE LOGIC)
====================================================================================

PURPOSE
-------
This script performs a compliance and reporting audit for a single fishing vessel
(identified by PLN) over a specified date range.

It is designed to answer the core operational question:

  “This vessel transmitted VMS positions.
   Was fishing activity detected on those dates, and how soon afterwards were
   Sales Notes and Catch Records submitted?”

The script treats VMS data as the activity anchor and measures how reporting
(Sales Notes and Catch Records) aligns in time with observed vessel behaviour.

------------------------------------------------------------------------------------
KEY DESIGN PRINCIPLES
------------------------------------------------------------------------------------
1. VMS IS THE ACTIVITY ANCHOR
   - VMS positions indicate when the vessel was active at sea.
   - All reporting checks are anchored to the VMS date.

2. NEAREST‑DATE LOGIC (NO FIXED +1 / +2 ASSUMPTIONS)
   - For each VMS date, the script identifies:
       - Whether a Catch Record exists on the same date
       - If not, the next Catch Record date after the VMS date
       - The number of days between the VMS date and that Catch Record
   - The same logic is applied to Sales Notes.
   - This avoids hard‑coding reporting windows and instead measures the
     actual delay between activity and reporting.

3. BEHAVIOUR IS AGGREGATED DAILY
   - VMS pings are classified by speed into:
       - Fishing
       - Steaming
       - Idle
   - These are aggregated per VMS date to produce:
       • Total number of VMS points
       • Number of points in each behaviour category
       • Percentage of the day that appears to be fishing
   - Behaviour is summarised once per day to avoid row duplication.

4. DATE SAFETY
   - All date calculations use DATE data types.
   - Dates are formatted (dd/MM/yyyy) only in final output.
   - This avoids locale‑dependent conversion errors.

------------------------------------------------------------------------------------
TEMP TABLES CREATED
------------------------------------------------------------------------------------
#vms_tracks
  - Ping‑level VMS data with behaviour classification.

#DailyBehaviour
  - One row per VMS date with fishing / idle / steaming counts and percentages.

#CR
  - Catch Record headers for the vessel within the period
    (used for nearest‑date matching).

#CR_Detail
  - Detailed Catch Record data by species and weight.

#SN_Detail
  - Detailed Sales Note data by species and weight.

------------------------------------------------------------------------------------
OUTPUTS PRODUCED
------------------------------------------------------------------------------------
1) SUMMARY OUTPUT (PRIMARY)
   - One row per VMS date.
   - Shows:
       - Daily VMS behaviour summary
       - Whether a CR or SN exists on the same date
       - The next CR and SN dates after the VMS date
       - The number of days between VMS activity and reporting

2) DETAILED VMS OUTPUT (COMMENTED OUT)
   - Ping‑level VMS data for investigation purposes only.

3) ALL CATCH RECORD DETAIL
   - Species and weights for all Catch Records in the period.

4) ALL SALES NOTE DETAIL
   - Species and weights for all Sales Notes in the period.

------------------------------------------------------------------------------------
INTENDED USE
------------------------------------------------------------------------------------
This script is intended for:
- Compliance checks
- Post‑activity reporting audits
- Identifying late or missing Sales Notes and Catch Records
- Supporting investigation and assurance work

It is not a decision‑making or enforcement tool on its own, but provides a
transparent and defensible evidence base for further analysis.

====================================================================================

For each VMS date it shows:

- How the vessel behaved (Fishing / Idle / Steaming + %)
- Whether a CR exists on the same date
- The next CR date, if any
- Days between VMS → CR
- Whether an SN exists on the same date
- The next SN date, if any
- Days between VMS → SN
*/

/* =======================
PARAMETERS
======================= */
DECLARE @startdate DATE = '2024-02-01';
DECLARE @enddate   DATE = '2024-02-29';
DECLARE @pln       NVARCHAR(20) = 'WH33';

DECLARE @minFishingSpeed DECIMAL(4,1) = 2.0;
DECLARE @maxFishingSpeed DECIMAL(4,1) = 7.0;

/* =======================
CLEAN UP
======================= */
DROP TABLE IF EXISTS #vms_tracks;
DROP TABLE IF EXISTS #DailyBehaviour;
DROP TABLE IF EXISTS #CR;
DROP TABLE IF EXISTS #CR_Detail;
DROP TABLE IF EXISTS #SN_Detail;

/* =======================
1. VMS TRACKS
======================= */
SELECT
    vr.PLN,
    vp.VesselDwk,
    CONVERT(DATE, vp.EventOccurrence) AS VMSdate,
    vp.EventOccurrence,
    vp.SpeedRecorded,
    vp.Latitude,
    vp.Longitude,
    CASE  
        WHEN vp.SpeedRecorded BETWEEN @minFishingSpeed AND @maxFishingSpeed THEN 'Fishing'
        WHEN vp.SpeedRecorded > @maxFishingSpeed THEN 'Steaming'
        ELSE 'Idle'
    END AS Behaviour
INTO #vms_tracks
FROM ods.VesselPosition vp
JOIN ods.VesselRegistration vr 
    ON vp.VesselDwk = vr.VesselDwk
WHERE CONVERT(DATE, vp.EventOccurrence) BETWEEN @startdate AND @enddate
  AND vr.PLN = @pln
  AND GETDATE() BETWEEN vr.EffectiveFromDateTime AND vr.EffectiveToDateTime;

/* =======================
2. DAILY BEHAVIOUR (KEEP)
======================= */
SELECT
    PLN AS VessReg,
    VMSdate,
    COUNT(*) AS TotalVMSPoints,
    SUM(CASE WHEN Behaviour = 'Fishing'  THEN 1 ELSE 0 END) AS FishingPoints,
    SUM(CASE WHEN Behaviour = 'Idle'     THEN 1 ELSE 0 END) AS IdlePoints,
    SUM(CASE WHEN Behaviour = 'Steaming' THEN 1 ELSE 0 END) AS SteamingPoints,
    ROUND(
        100.0 * SUM(CASE WHEN Behaviour = 'Fishing' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*),0), 2
    ) AS FishingPct
INTO #DailyBehaviour
FROM #vms_tracks
GROUP BY PLN, VMSdate;

/* =======================
3. CR HEADER (FOR SUMMARY)
======================= */
SELECT 
    VR.PLN,
    CONVERT(DATE, FT.EndDatetime) AS CRDate,
    FT.ArrivalPort,
    FT.TripIdentifier
INTO #CR
FROM ODS.FishingTrip FT
JOIN ODS.FishingActivity FA 
    ON FA.TripIdentifier = FT.TripIdentifier
JOIN ODS.VesselRegistration VR 
    ON VR.CFRIdentification = FT.CFRIdentification
WHERE FT.EndDatetime BETWEEN @startdate AND @enddate
  AND FA.ActivityType = 'Fishing_operation'
  AND VR.PLN = @pln;

/* =======================
4. CR DETAIL (SPECIES & WEIGHTS)
======================= */
SELECT
    v.PLN AS VessReg,
    CONVERT(DATE, ft.EndDatetime) AS CRDate,
    c.FAOSpeciesCode,
    c.Weight AS CRWeight_kg,
    sr.LinkedFAOArea
INTO #CR_Detail
FROM ods.FishingTrip ft
JOIN ods.FishingActivity fa 
    ON fa.TripIdentifier = ft.TripIdentifier
JOIN ods.Catch c 
    ON c.TripIdentifier = ft.TripIdentifier
JOIN ods.ICESStatisticalSuRectangle sr 
    ON sr.FisheriesLocationDwk = fa.FisheriesLocationDwk
JOIN ods.VesselRegistration v 
    ON v.CFRIdentification = ft.CFRIdentification
WHERE ft.EndDatetime BETWEEN @startdate AND @enddate
  AND c.CatchType = 'onboard'
  AND fa.ActivityType = 'fishing_operation'
  AND v.PLN = @pln;

/* =======================
5. SN DETAIL (SPECIES & WEIGHTS)
======================= */
SELECT
    vr.PLN AS VessReg,
    CONVERT(DATE, sn.LandingDate) AS LandingDate,
    st.FAOSpeciesCode,
    sp.EnglishName,
    ROUND(SUM(st.Weight),2) AS SaleWeight_kg,
    ROUND(SUM(st.Value),2) AS SaleValue_GBP
INTO #SN_Detail
FROM ods.SalesNote sn
JOIN ods.SalesTakeoverNoteLine st 
    ON sn.SalesNoteDwk = st.SalesNoteDwk
JOIN ods.VesselRegistration vr 
    ON sn.VesselDwk = vr.VesselDwk
JOIN ods.Species sp 
    ON st.SpeciesCodeDwk = sp.SpeciesCodeDwk
WHERE sn.LandingDate BETWEEN @startdate AND @enddate
  AND vr.PLN = @pln
  AND GETDATE() BETWEEN vr.EffectiveFromDateTime AND vr.EffectiveToDateTime
GROUP BY
    vr.PLN,
    sn.LandingDate,
    st.FAOSpeciesCode,
    sp.EnglishName;

/* =======================
6. SUMMARY – NEAREST-DATE LOGIC
======================= */
SELECT
    v.PLN AS VessReg,
    FORMAT(v.VMSdate, 'dd/MM/yyyy') AS VMSdate,

    db.TotalVMSPoints,
    db.FishingPoints,
    db.IdlePoints,
    db.SteamingPoints,
    db.FishingPct,

    CASE WHEN EXISTS (
        SELECT 1 FROM #CR c WHERE c.PLN = v.PLN AND c.CRDate = v.VMSdate
    ) THEN 1 ELSE 0 END AS CR_On_VMSdate,

    FORMAT(cr_next.NextCRDate, 'dd/MM/yyyy') AS Next_CR_Date,
    DATEDIFF(DAY, v.VMSdate, cr_next.NextCRDate) AS Days_VMS_to_CR,

    CASE WHEN EXISTS (
        SELECT 1
        FROM ods.SalesNote sn
        JOIN ods.VesselRegistration vr ON vr.VesselDwk = sn.VesselDwk
        WHERE vr.PLN = v.PLN AND sn.LandingDate = v.VMSdate
    ) THEN 1 ELSE 0 END AS SN_On_VMSdate,

    FORMAT(sn_next.NextSNDate, 'dd/MM/yyyy') AS Next_SN_Date,
    DATEDIFF(DAY, v.VMSdate, sn_next.NextSNDate) AS Days_VMS_to_SN

FROM (
    SELECT DISTINCT PLN, VMSdate FROM #vms_tracks
) v
LEFT JOIN #DailyBehaviour db
    ON db.VessReg = v.PLN AND db.VMSdate = v.VMSdate
OUTER APPLY (
    SELECT MIN(CRDate) AS NextCRDate
    FROM #CR c
    WHERE c.PLN = v.PLN AND c.CRDate >= v.VMSdate
) cr_next
OUTER APPLY (
    SELECT MIN(LandingDate) AS NextSNDate
    FROM #SN_Detail s
    WHERE s.VessReg = v.PLN AND s.LandingDate >= v.VMSdate
) sn_next
ORDER BY v.VMSdate;

/* =======================
OUTPUT 7. ALL CR DETAIL
======================= */
SELECT
    VessReg,
    FORMAT(CRDate, 'dd/MM/yyyy') AS CRDate,
    FAOSpeciesCode,
    CRWeight_kg,
    LinkedFAOArea
FROM #CR_Detail
ORDER BY CRDate, FAOSpeciesCode;

/* =======================
OUTPUT 8. ALL SN DETAIL
======================= */
SELECT
    VessReg,
    FORMAT(LandingDate, 'dd/MM/yyyy') AS LandingDate,
    FAOSpeciesCode,
    EnglishName,
    SaleWeight_kg,
    SaleValue_GBP
FROM #SN_Detail
ORDER BY LandingDate, FAOSpeciesCode;


