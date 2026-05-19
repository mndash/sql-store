VMS – Sales Note – Catch Record Audit
Nearest Date Logic Explanation
________________________________________
1. Overview
This script performs a reporting and compliance audit for a single fishing vessel over a specified date range.
The vessel is identified by its PLN, and the audit period is controlled by start and end date parameters.
The objective of the script is to assess how reporting activity (Sales Notes and Catch Records) aligns in time with observed vessel activity derived from VMS (Vessel Monitoring System) data.
The script does not assume that reporting occurs on fixed dates (such as “+1” or “+2” days).
Instead, it measures the actual time delay between VMS activity and subsequent reporting.
________________________________________
2. Conceptual Approach
2.1 VMS as the Activity Anchor
VMS position reports are treated as the ground truth for vessel activity at sea.
Each calendar date on which VMS pings are received is considered a VMS activity date.
All reporting checks are anchored to this date.
In simple terms:
“What did the vessel appear to be doing on this day, and when did it report that activity?”
________________________________________
2.2 Behaviour Classification
Each VMS ping is classified into one of three behavioural categories based on recorded speed:
•	Fishing – speed between defined fishing thresholds
•	Steaming – speed above the fishing threshold
•	Idle – speed below the fishing threshold
These classifications are not used individually.
Instead, they are aggregated per VMS date to provide a daily behavioural summary.
This produces, for each VMS date:
•	Total number of VMS pings
•	Number of pings classified as Fishing, Steaming, and Idle
•	Percentage of the day that appears to be Fishing
This aggregation avoids duplication and ensures that behaviour is assessed once per day, not once per ping.
________________________________________
3. Nearest Date Reporting Logic
3.1 Rationale
Traditional audit logic often assumes that:
•	Sales Notes must be submitted on specific days (e.g. +1 or +2)
•	Catch Records must align exactly with landing dates
In practice, reporting can occur earlier or later.
This script therefore uses nearest date logic, which answers:
•	Was reporting done on the same day as the activity?
•	If not, how long after the activity did reporting occur?
This approach is:
•	More transparent
•	More defensible
•	More flexible for policy changes
________________________________________
3.2 Catch Record (CR) Assessment
For each VMS date, the script determines:
1.	Whether a Catch Record exists on the same date
This is recorded as a binary indicator (CR_On_VMSdate).
2.	The next Catch Record date after the VMS date
This is the earliest Catch Record date that occurs on or after the VMS date.
3.	The number of days between the VMS date and the Catch Record date
This measures the reporting delay.
If no Catch Record exists after the VMS date, the result is left blank (NULL), making the absence explicit.
________________________________________
3.3 Sales Note (SN) Assessment
The same logic is applied to Sales Notes.
For each VMS date, the script determines:
1.	Whether a Sales Note exists on the same date
2.	The next Sales Note landing date after the VMS date
3.	The number of days between the VMS date and the Sales Note
This allows the script to identify:
•	Same day reporting
•	Late reporting
•	Missing reporting
Without making assumptions about acceptable delays.
________________________________________
4. Use of OUTER APPLY
The script uses OUTER APPLY to implement nearest date logic.
OUTER APPLY allows a subquery to be evaluated once per VMS date, using the current VMS date as input.
For each VMS date:
•	The subquery searches the reporting table
•	Filters records to those on or after the VMS date
•	Returns the earliest matching date
If no matching record exists:
•	The VMS date is still retained
•	The reporting date is returned as NULL
This behaviour is essential for audit work, as it preserves evidence of missing reporting rather than removing those rows.
________________________________________
5. Temporary Tables Used
The script uses temporary tables to separate concerns and make the logic clear and auditable:
•	#vms_tracks
Ping level VMS data with behaviour classification.
•	#DailyBehaviour
One row per VMS date containing daily behaviour statistics.
•	#CR
Catch Record headers used for nearest date matching.
•	#CR_Detail
Detailed Catch Record data including species and weights.
•	#SN_Detail
Detailed Sales Note data including species, weights, and values.
Using temporary tables allows:
•	Reuse of datasets
•	Multiple outputs from the same data
•	Clear separation between logic layers
________________________________________
6. Outputs Produced
6.1 Summary Output (Primary)
The main output contains one row per VMS date and shows:
•	Daily fishing behaviour summary
•	Whether a Catch Record exists on the same date
•	The next Catch Record date
•	Days between VMS activity and Catch Record
•	Whether a Sales Note exists on the same date
•	The next Sales Note date
•	Days between VMS activity and Sales Note
This output is intended for compliance review and assurance reporting.
________________________________________
6.2 Detailed VMS Output (Optional)
A detailed ping level VMS output is included but commented out.
This is intended for:
•	Investigation
•	Spatial or temporal analysis
•	Case review
It is not required for routine reporting.
________________________________________
6.3 Catch Record Detail Output
A full list of Catch Records for the vessel during the period, including:
•	Landing date
•	Species
•	Weights
•	FAO area
This allows reconciliation between activity and declared catches.
________________________________________
6.4 Sales Note Detail Output
A full list of Sales Notes for the vessel during the period, including:
•	Landing date
•	Species
•	Weights
•	Values
This supports economic and reporting validation.
________________________________________
7. Intended Use and Limitations
This script is intended to support:
•	Compliance monitoring
•	Post activity audits
•	Identification of late or missing reporting
•	Evidence based investigations
It does not make enforcement decisions by itself.
Instead, it provides a transparent, reproducible evidence base to support further review.
________________________________________
8. Summary
In summary, this script:
•	Anchors all analysis on observed vessel activity
•	Measures reporting delays rather than assuming them
•	Aggregates behaviour sensibly at a daily level
•	Preserves missing data for audit transparency
•	Produces clear, defensible outputs suitable for compliance work
________________________________________
If you want, I can:
•	Convert this into a formal PDF style audit note
•	Produce a short executive summary
•	Add a worked example page using real output rows






1️⃣ What OUTER APPLY actually is (plain English)
OUTER APPLY is like a LEFT JOIN to a subquery that is evaluated row by row.
For each row coming from the left side (v, which is one row per VMSdate):
•	SQL Server runs the subquery inside OUTER APPLY
•	The subquery can reference columns from that current row
•	If the subquery finds a result → you get it
•	If it finds nothing → you still keep the VMS row, and the columns return NULL
That “row by row evaluation” is exactly why OUTER APPLY is ideal for “nearest date” logic.
________________________________________
2️⃣ What rows exist before OUTER APPLY runs
This part defines the driving dataset:
SQL
FROM (
SELECT DISTINCT
PLN,
VMSdate
FROM #vms_tracks
) v
Show more lines
At this point you have:
•	One row per vessel per VMS date
•	Example:
PLN	VMSdate
abc	2024 02 11
abc	2024 02 12
abc	2024 02 13
Every OUTER APPLY that follows is executed once per row above.
________________________________________
3️⃣ First OUTER APPLY: Catch Record logic
SQL
OUTER APPLY (
SELECT MIN(cr.CRDate) AS NextCRDate
FROM #CR cr
WHERE cr.PLN = v.PLN
AND cr.CRDate >= v.VMSdate
) cr_next
``
Show more lines
What this does for one VMSdate
For the current row (say VMSdate = 2024 02 13):
•	Look in #CR
•	Filter to: 
o	Same vessel (cr.PLN = v.PLN)
o	CR dates on or after the VMS date
•	From those rows: 
o	Take the earliest (minimum) CRDate
So logically this answers:
“Starting from this VMS date, when is the next Catch Record that appears?”
Why MIN() is important
Without MIN() you might get multiple CR rows.
MIN() collapses them to one nearest future date.
Why OUTER APPLY (not JOIN)
If no CR exists after that VMSdate:
•	OUTER APPLY still keeps the VMS row
•	NextCRDate becomes NULL
That is exactly what you want for auditing.
________________________________________
4️⃣ Second OUTER APPLY: Sales Note logic
SQL
OUTER APPLY (
SELECT MIN(sn.LandingDate) AS NextSNDate
FROM ods.SalesNote sn
JOIN ods.VesselRegistration vr
ON vr.VesselDwk = sn.VesselDwk
WHERE vr.PLN = v.PLN
AND sn.LandingDate >= v.VMSdate
AND GETDATE() BETWEEN vr.EffectiveFromDateTime AND vr.EffectiveToDateTime
) sn_next
Show more lines
This works exactly the same way, but against Sales Notes.
For each VMSdate:
•	Look at all Sales Notes for the vessel
•	Keep only those: 
o	On or after the VMS date
o	With valid vessel registration
•	Pick the earliest landing date after the VMS date
This answers:
“What is the closest Sales Note date after this VMS activity?”
Again:
•	If no SN exists → NextSNDate = NULL
•	The VMS row is still kept
________________________________________
5️⃣ Why OUTER APPLY is better than the old +1 / +2 join
Your old logic:
SQL
s.LandingDate IN (VMSdate + 1, VMSdate + 2)

Show more lines
That assumes compliance windows.
The new logic:
SQL
MIN(Date) WHERE Date >= VMSdate

Show more lines
That measures reality.
OUTER APPLY lets SQL Server do this per VMSdate, which you cannot do cleanly with a normal join.
________________________________________
6️⃣ Why not LEFT JOIN instead?
You could write something like:
SQL
LEFT JOIN #CR cr ON cr.PLN = v.PLN AND cr.CRDate >= v.VMSdate
Show more lines
But that would:
•	Return multiple rows per VMSdate
•	Force extra grouping
•	Make the logic harder to read and maintain
OUTER APPLY + MIN():
•	Guarantees one row per VMSdate
•	Keeps the logic explicit and auditable
________________________________________
7️⃣ What happens when there is no CR or SN
This is crucial for audits.
Scenario	Result
No CR on or after VMSdate	NextCRDate = NULL
No SN on or after VMSdate	NextSNDate = NULL
VMSdate still appears	✅ Yes
That allows you to later flag:
•	Missing CR
•	Missing SN
•	Excessive delay
Without losing the VMS activity row.
________________________________________
8️⃣ Mental model (easy way to remember)
Think of OUTER APPLY as:
“For this specific VMSdate, run a small query to find the best matching future record.”
That’s exactly what you’re doing.
________________________________________
✅ Summary (one paragraph version you can reuse)
OUTER APPLY is used to evaluate a subquery once for each VMS date.
It allows the query to find the nearest future Catch Record or Sales Note date relative to the VMS date, while still returning the VMS date even when no matching record exists. This makes it ideal for audit logic where reporting delays must be measured rather than assumed.

