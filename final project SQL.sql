--Q1
--Doctor Workload by Specialty
--BUSINESS REQUIREMENT / RETURN
--For every specialty, the number of appointments booked and the number of distinct doctors who handled them.
--CONDITIONS
--• Consider only appointments with a Status of 'Completed'.
--• Join Doctors to Appointments to attribute each appointment to a specialty.
--BUSINESS RULES
--• A specialty must appear even if it currently has zero completed appointments.
--• Distinct doctor count should reflect only doctors who belong to that specialty, not just doctors who ever worked
--in the hospital.
--SORTING REQUIREMENT
--Order by total completed appointments descending
select d.Specialty,
 count(a.appointment_id) as Total_completed_appointment,
 count(distinct d.doctor_id) as Total_Doctors
from Doctors as d
left join Appointments as a 
on d.Doctor_ID=a.Doctor_ID
and a.Status='Completed'
group by d.Specialty
order by Total_completed_appointment DESC


--Q2
--Patient Visit Frequency Segmentation
--BUSINESS REQUIREMENT / RETURN
--Each patient's full name, total number of appointments, and a segment label describing how frequently they visit.
--CONDITIONS
--• Include only patients who have at least one appointment on record.
--BUSINESS RULES
--• Classify patients into 'Frequent Visitor' (6 or more appointments), 'Regular Visitor' (3 to 5 appointments), and
--'Occasional Visitor' (1 or 2 appointments).
--• The segment label must be computed, not hard-coded per patient.
--SORTING REQUIREMENT
--Order by total appointments descending, then by full name alphabetically
with patient_Report as(
select 
 p.Patient_ID,
 p.Full_Name,
 count(a.appointment_id) as Total_Appointments,
  case
     when count(a.Appointment_ID) >= 6
      then 'Frequent Visitor'
     when COUNT(a.Appointment_ID) BETWEEN 3 AND 5
      then 'Regular Visitor'
     when COUNT(a.Appointment_ID) BETWEEN 1 AND 2
      then 'Occasional Visitor'
 end as Visit_Category
from Patients as p
join appointments as a
on p.Patient_ID=a.Patient_ID
group by 
 p.Patient_ID,
 p.Full_Name
)
select *
from patient_Report
where Total_Appointments>=1
order by Total_Appointments DESC,Full_Name ASC

--Q3
--Revenue Contribution by Payment Method
--BUSINESS REQUIREMENT / RETURN
--Each payment method, the total amount collected through it, and the percentage share it represents of overall
--hospital revenue.
--CONDITIONS
--• Use all recorded payments regardless of date.
--BUSINESS RULES
--• Percentage share must be rounded to two decimal places.
--• The percentages across all payment methods should conceptually add up to 100%.
--SORTING REQUIREMENT
--Order by total amount collected descending
with payment_report as
(
 select
  payment_method,
  sum(amount) as total_amount
 from payments
 group by payment_method
)
select
   payment_method,
   total_amount,
    cast(
        total_amount * 100.0 /
        sum(total_amount) over()
        as decimal(10,2)
    ) as percentage_share

from payment_report
order by total_amount desc;

--Q4
--Doctor No-Show Impact
--BUSINESS REQUIREMENT / RETURN
--For each doctor, the count of appointments with a Status of 'No-Show' alongside their total appointment count and
--the no-show rate as a percentage.
--CONDITIONS
--• Only include doctors who have at least 5 total appointments on record.
--BUSINESS RULES
--• No-show rate = no-show appointments divided by total appointments, expressed as a percentage rounded to
--one decimal place.
--SORTING REQUIREMENT
--Order by no-show rate descending.

select
    d.doctor_id,
    d.doctor_name,
    count(a.appointment_id) as total_appointments,
    count(
        case 
            when a.status='Cancelled'
            then a.appointment_id
        end
    ) as no_show_appointments,
    cast(
 count(case when a.status='Cancelled' then a.appointment_id end)*100.0/ count(a.appointment_id)
      as decimal(10,1)
    ) as Cancelled_rate
from doctors d
join appointments a
on d.doctor_id=a.doctor_id
group by
    d.doctor_id,
    d.doctor_name
having count(a.appointment_id) >= 5
order by Cancelled_rate desc;




--Q5
--Departmental Revenue Snapshot
--BUSINESS REQUIREMENT / RETURN
--For each hospital department, the total revenue generated, the number of unique patients treated, and the
--average revenue collected per patient.
--CONDITIONS
--• Revenue must be linked to a department through the doctor who conducted the associated appointment.
--• Only include payments tied to appointments with a Status of 'Completed'.
--BUSINESS RULES
--• Average revenue per patient = total department revenue divided by the count of unique patients treated in that
--department.
--SORTING REQUIREMENT
--Order by total revenue descending.
select 
    d.Department,
    sum(pa.Amount) as Total_Revenue,
    count(distinct a.Patient_ID) as Total_Patients,
    cast(
        sum(pa.Amount)*1.0/
        count(distinct a.Patient_ID)
        as decimal(10,2)
    ) as Average_Revenue_Per_Patient
from Doctors d
join Appointments a
on d.Doctor_ID=a.Doctor_ID
and a.Status='Completed'
join Payments pa
on a.Appointment_ID=pa.Appointment_ID
group by d.Department
order by Total_Revenue DESC;



--Q6
--Experience vs Appointment Volume
--BUSINESS REQUIREMENT / RETURN
--Each doctor's name, years of experience, and total number of appointments handled, grouped into experience
--tiers.
--CONDITIONS
--• Include all doctors regardless of appointment count.
--BUSINESS RULES
--• Classify doctors into 'Senior' (10+ years), 'Mid-Level' (4 to 9 years), and 'Junior' (0 to 3 years) using
--Years_of_Experience.
--• Doctors with zero appointments should still appear with a count of zero.
--SORTING REQUIREMENT
--Order by experience tier (Senior first, then Mid-Level, then Junior), then by total appointments descending within
--each tier.
select
 d.doctor_id,
 d.Doctor_Name,
 count(a.appointment_id) as total_appointment,
 d.Years_of_Experience,
 case
 when d.Years_of_Experience>=10 then 'Senior'
 when d.Years_of_Experience>=4 then 'Mid-Level'
 else 'Junior'
 end as Experience_Tier
from Doctors as d 
left join Appointments as a on d.Doctor_ID=a.Doctor_ID
and a.Status='Completed'
group by 
d.doctor_id,
d.Doctor_Name,
d.Years_of_Experience
order by
case
 when d.Years_of_Experience>=10 then 1
 when d.Years_of_Experience>=4 then 2
 else 3
end,
total_appointment DESC


--Q7
--Monthly Appointment Volume Trend
--BUSINESS REQUIREMENT / RETURN
--For each calendar month present in the data, the total number of appointments and the number of those that were
--completed versus cancelled versus no-show.
--CONDITIONS
--• Use Appointment_Date to determine the month.
--• Cover every month that has at least one appointment.
--BUSINESS RULES
--• Present month in a readable year-month format.
--• The three status-based counts plus any other statuses should be traceable back to the total.
--SORTING REQUIREMENT
--Order chronologically by month
 select
  format(Appointment_Date,'yyyy-MM') as Appointment_Month,
  count(Appointment_ID) as Total_Appointments,
  count(
    case
     when Status='Completed' then Appointment_ID
    end
  ) as Completed_Appointments,
  
   count(
    case
     when Status='Scheduled' then Appointment_ID
    end
  ) as Scheduled_Appointments,
   count(
    case
     when Status='Cancelled' then Appointment_ID
    end
  ) as Cancelled_Appointments
 from
  Appointments
group by format(Appointment_Date,'yyyy-MM')
order by Appointment_Month


--Q8
--Age Group Visit Pattern
--BUSINESS REQUIREMENT / RETURN
--Medium
--For each patient age group, the number of appointments and a breakdown of how many were 'In-Person' versus
--'Online' (or other recorded visit types).
--CONDITIONS
--• Use the Age column from Patients to determine the age group.
--BUSINESS RULES
--• Define age groups as 'Child' (0–12), 'Teen' (13–19), 'Adult' (20–59), and 'Senior' (60+).
--• An appointment must be linked back to the patient who booked it to determine the age group.
--SORTING REQUIREMENT
--Order age groups in the logical life-stage sequence: Child, Teen, Adult, Senior
with Age_Group as(
select
Patient_id,
 case
 when age>=60 then 'Senior'
 when age>=20 then 'Adult'
 when age>=13 then 'Teen'
 when age>=0 then 'Child'
 end as AgeG
from patients
)
 select 
 ag.AgeG,
 count(a.Appointment_ID) as Total_appointments,
 count(
 case 
 when a.Visit_Type='Follow-up' then a.Appointment_ID
 end
 ) as  Follow_up_appointments,

 count(
 case 
 when a.Visit_Type='Consultation' then a.Appointment_ID
 end
 ) as Consultation_appointments,

  count(
 case 
 when  a.Visit_Type='Emergency' then a.Appointment_ID
 end
 ) as Emergency_appointments,

  count(
 case 
 when  a.Visit_Type='New' then a.Appointment_ID
 end
 ) as New_appointments

 from  Age_Group ag
 join Appointments as a
 on ag.Patient_ID=a.Patient_ID
 group by ag.AgeG
 order by
   case AgeG
    when 'Child' then 1
    when 'Teen' then 2
    when 'Adult' then 3
    when 'Senior' then 4
   end
 --Q9
 --Top Doctor per Department by Revenue
--BUSINESS REQUIREMENT / RETURN
--The single highest revenue-generating doctor within each department, along with their total collected revenue.
--CONDITIONS
--• Revenue is determined from payments tied to that doctor's completed appointments.
--BUSINESS RULES
--• If two doctors in the same department tie on revenue, both should be returned.
--• A department with no revenue-generating doctors should not appear in the result.
--SORTING REQUIREMENT
--Order by department name alphabetically, then by revenue descending within each department.
with Doctors_revenue as
(
  select 
   d.Doctor_ID,
   d.doctor_name,
   d.department,
   sum(p.amount) as Revenue
 from 
 Doctors as d
 left join Appointments as a
 on d.Doctor_ID=a.Doctor_ID and a.Status='Completed'
 left join Payments as p
 on a.Appointment_ID=p.Appointment_ID
 group by 
  d.Doctor_ID,
  d.doctor_name,
  d.department
 ),
 doctor_rank as
 (
  select *,
  dense_rank() over( partition by department order by revenue DESC)as revenue_rank
  from Doctors_revenue
 )
 select *
 from doctor_rank
 where revenue_rank=1
 order by department,revenue DESC

--Q10
--Patient Loyalty Tiering
--BUSINESS REQUIREMENT / RETURN
--Each patient's full name, total number of completed appointments, total amount paid, and a loyalty tier label.
--CONDITIONS
--• Only include patients registered for at least one year based on Registration_Date relative to the most recent
--date in the data.
--BUSINESS RULES
--• Loyalty tiers: 'Platinum' (10+ completed appointments and total paid above 5000), 'Gold' (5 to 9 completed
--appointments), 'Silver' (1 to 4 completed appointments), and 'At Risk' (registered but zero completed
--appointments in the last 12 months).
--• A patient can only belong to one tier.
--SORTING REQUIREMENT
--Order by loyalty tier in the sequence Platinum, Gold, Silver, At Risk, then by total paid descending
with Patient_Report as
(
 select
  p.Patient_ID,
  p.Full_Name,
  p.Registration_Date,
  max(a.Appointment_Date) as last_completed,
  isnull(sum(pay.amount),0) as Total_Paid,
  count(
    case 
     when a.Status='completed'
      then a.Appointment_ID
    end
  ) Completed_Appointments
 from
 Patients as p 
 left join Appointments as a
 on p.Patient_ID=a.Patient_ID
 left join Payments as pay
 on a.Appointment_ID=pay.Appointment_ID
 group by
  p.Patient_ID,
  p.Full_Name,
  p.Registration_Date
) ,
loyalty_Report as
(
 select *,
 case 
  when Completed_Appointments>=10 and Total_Paid>5000
   then 'Platinum'
  when Completed_Appointments between 5 and 9 
   then 'Gold'
  when Completed_Appointments between 1 and 4 
   then 'Silver'
  else 'At Risk'
 end as Loyalty_Tier
 from Patient_Report
 where DATEDIFF(
   YEAR,
   Registration_Date,
   (select max(Registration_Date) from patients)
 )>=1
)
select *
from loyalty_Report
order by 
 case Loyalty_Tier
  when 'Platinum' then 1
  when 'Gold' then 2
  when 'Silver' then 3
  else 4
  end,Total_Paid DESC


--Q11
--Running Monthly Revenue Total
--BUSINESS REQUIREMENT / RETURN
--For each month, the revenue collected that month and a running cumulative total of revenue from the start of the
--data through that month.
--CONDITIONS
--• Base the calculation strictly on the Payments table and Payment_Date.
--BUSINESS RULES
--• The cumulative total for the first month must equal that month's revenue exactly.
--• The final month's cumulative total must equal total hospital revenue to date.
--SORTING REQUIREMENT
--Order chronologically by month
with monthly_revenue  as 
(
  select 
   format(Payment_Date,'yyy-MM') as Months,
   sum(amount) as monthly_revenue 
  from Payments
  group by format(Payment_Date,'yyy-MM') 

)
select *,
 sum(monthly_revenue) 
  over
 (
    order by Months
    rows between unbounded preceding and current row
 ) as Running_Total
from monthly_revenue
order by Months


--Q12
--Above-Average Doctor Workload
--BUSINESS REQUIREMENT / RETURN
--The doctors whose total number of appointments exceeds the hospital-wide average number of appointments per
--doctor.
--CONDITIONS
--• Compute the hospital-wide average using all doctors who have at least one appointment.
--BUSINESS RULES
--• A doctor must strictly exceed the average, not simply meet it.
--• Include the doctor's total appointment count alongside the computed hospital average for reference.
--SORTING REQUIREMENT
--Order by total appointments descending
with Doctor_report as
(
select 
 d.doctor_id,
 d.doctor_name,
 count(a.appointment_id) as Total_appointment
from Doctors as d
left join Appointments as a
on d.Doctor_ID=a.Doctor_ID
group by 
d.Doctor_ID,
d.Doctor_Name
)
select *
from Doctor_report
where Total_appointment>
(
  select 
 AVG(Total_appointment) as Average_appointment
 from Doctor_report
)

order by Total_appointment DESC

--Q13
--Patients with Recurring Diagnoses
--BUSINESS REQUIREMENT / RETURN
--Patients who have been diagnosed with the same condition more than once across different medical records.
--CONDITIONS
--• Compare diagnoses within each patient's own history only.
--BUSINESS RULES
--• A recurring diagnosis means the identical Diagnosis text appears in two or more separate Medical_Records
--rows for that patient.
--• Return the patient name, the diagnosis, and how many times it recurred.
--SORTING REQUIREMENT
--Order by recurrence count descending, then by patient name alphabetically

select
 p.Patient_id,
 p.Full_Name,
 m.diagnosis,
 count(*) as recurrence_count
from Patients as p
join Medical_Records as m
on p.Patient_ID=m.Patient_ID
group by 
p.Patient_ID,
p.Full_Name,
m.Diagnosis
having count(*) > 1
order by 
 recurrence_count DESC,
 p.Full_Name ASC

--Q14
--Payment Collection Gap Analysis
--BUSINESS REQUIREMENT / RETURN
--Completed appointments that have no corresponding payment recorded, grouped by doctor.
--CONDITIONS
--• An appointment is considered unpaid if no row in Payments references its Appointment_ID.
--BUSINESS RULES
--• Only completed appointments should be evaluated for this gap, since cancelled or no-show visits are not
--expected to generate payment.
--• Return each doctor's name and the count of unpaid completed appointments.
---ORTING REQUIREMENT
--Order by unpaid count descending
select 
 d.doctor_name,
 count(*) as unpaid_completed_appointments
from Doctors as d
join Appointments as a 
on d.Doctor_ID=a.Doctor_ID
 and a.status='completed'
left join Payments as p
on a.Appointment_ID=p.Appointment_ID
where p.Payment_ID is null
group by
 d.doctor_name
order by
 unpaid_completed_appointments desc;

--Q15
--Specialty Revenue Share
--BUSINESS REQUIREMENT / RETURN
--Each medical specialty's total revenue and its percentage contribution to overall hospital revenue, alongside its
--rank among all specialties.
--CONDITIONS
--• Base revenue on payments linked to completed appointments.
--BUSINESS RULES
--• Percentage share rounded to two decimal places.
--• Rank 1 should represent the highest-revenue specialty with no gaps in rank numbering even if two specialties
--tie.
--SORTING REQUIREMENT
--Order by rank ascending.
with Specialty_Revenue as
(
  select
   d.Specialty,
   sum(pay.amount) as Revenue
  from Doctors as d
  left join Appointments as a
  on d.Doctor_ID=a.Doctor_ID
  and a.Status='Completed'
  left join Payments as pay
  on a.Appointment_ID=pay.Appointment_ID
  group by
   d.Specialty
)
select *,
cast(Revenue*100.0/sum(revenue) over() as Decimal(10,2)) as Percentage_share,
dense_rank() over( order by Revenue DESC) as Specialty_rank_revenue
from Specialty_Revenue
order by Specialty_rank_revenue



--Q16
--First-Time vs Returning Patient Classification
--BUSINESS REQUIREMENT / RETURN
--For each appointment, a label indicating whether it was the patient's first-ever appointment or a returning visit,
--along with a summary count of first-time versus returning appointments per month.
--CONDITIONS
--• Determine 'first' strictly by the earliest Appointment_Date for that patient.
--BUSINESS RULES
--• Every appointment must be classified as exactly one of 'First Visit' or 'Returning Visit'.
--• The monthly summary should total first-time and returning counts separately.
--SORTING REQUIREMENT
--Order the monthly summary chronologically
with patients_Appointmnets as 
(
  select 
   p.Patient_ID,
   p.Full_Name,
   a.appointment_date,
   a.Appointment_ID
  from Patients as p
  join Appointments as a
  on p.Patient_ID=a.Patient_ID
),
rank_appointments as
(
select *,
dense_rank() over(
    partition by Patient_ID
    order by appointment_date
) as appointments_rank
from patients_Appointmnets
),
appointments_level as
(
select *,
 case
  when appointments_rank=1
   then 'First Visit'
  else 'Returning Visit'
 end as appointments_label
from rank_appointments
)
select
 format(appointment_date,'yyyy-MM'),
 sum(case
 when appointments_label='First Visit' 
  then 1
 else 0 end) as First_visit,
 sum(case
 when appointments_label='Returning Visit' 
  then 1
 else 0 end) as Returning_visit
from 
 appointments_level
group by format(appointment_date,'yyyy-MM')
order by format(appointment_date,'yyyy-MM')

--Q17
--Department Staffing vs Demand
--BUSINESS REQUIREMENT / RETURN
--For each department, the number of doctors assigned versus the number of appointments handled, plus an
--average appointments-per-doctor figure.
--CONDITIONS
--• Only completed and scheduled appointments count toward demand; cancelled appointments should be
--excluded.
--BUSINESS RULES
--• A department with doctors but zero appointments should show an average of zero rather than an error.
--• Flag any department whose average appointments-per-doctor is more than double the hospital-wide average
--as 'Overloaded'.
--SORTING REQUIREMENT
--Order by average appointments-per-doctor descending
with Department_report as 
(
select 
d.Department,
count(distinct d.doctor_id) as Doctors_assigned,
count(a.appointment_id) as appointments_handled,
cast(count(a.appointment_id)/nullif(count(distinct d.doctor_id),0) as decimal(10,2) ) as AVG_per_Doctor
from Doctors as d
left join Appointments as a
on d.Doctor_ID=a.Doctor_ID and a.Status in ('completed','scheduled')
group by 
d.Department
)
select *,
 case 
  when AVG_per_Doctor>2*(sum(appointments_handled)over()/sum(Doctors_assigned) over() )
   then 'Overloaded'
  else  'Normal'
 end as Workload_Status
from Department_report
order by AVG_per_Doctor DESC

--Q18
--Patient Risk Classification
--BUSINESS REQUIREMENT / RETURN
--Each patient's name, number of distinct diagnoses recorded, number of appointments in the last 6 months relative
--to the most recent date in the data, and a computed risk level.
--CONDITIONS
--• Only patients with at least one medical record should be evaluated.
--BUSINESS RULES
--• Risk level is 'High' if the patient has 3 or more distinct diagnoses and at least 2 visits in the last 6 months,
--'Medium' if only one of those two conditions is met, and 'Low' otherwise.
--SORTING REQUIREMENT
--Order by risk level (High, then Medium, then Low), then by distinct diagnosis count descending

with max_date as
(
    select max(appointment_date) as latest_date
    from appointments
),
patient_report as(
select 
    p.patient_id,
    p.full_name,
    count(distinct mr.Diagnosis) as diagnosis_record,
    count(distinct case
        when a.appointment_date >= dateadd(month, -6, m.latest_date)
        then a.appointment_id
    end) as appointments_last_6months
from patients as p
left join appointments as a
    on p.patient_id = a.patient_id
left join medical_records as mr
    on p.patient_id = mr.patient_id
cross join max_date as m
group by 
    p.patient_id,
    p.full_name
),
risk_level as
(
select *,
case  
 when diagnosis_record>=3 and appointments_last_6months>=2
  then 'High'
 when diagnosis_record>=3 or appointments_last_6months>=2
  then 'Medium'
 else 'low'
end Risk_Level
from patient_report
)
select *
from risk_level
where diagnosis_record>=1
order by 
 case Risk_Level
  when 'High'
   then 1
     when 'Medium'
   then 2
     when 'low'
   then 3
   end ,diagnosis_record DESC



--Q19
--Monthly Revenue Report with Growth Rate
--BUSINESS REQUIREMENT / RETURN
--For each month, total revenue, the prior month's revenue, and the percentage growth or decline compared to the
--prior month.
--CONDITIONS
--• The very first month in the data will naturally have no prior month to compare against.
--BUSINESS RULES
--• Growth rate = (current month revenue - prior month revenue) divided by prior month revenue, expressed as a
--percentage rounded to one decimal place.
--• Handle the first month's missing comparison gracefully rather than causing a calculation error.
--SORTING REQUIREMENT
--Order chronologically by month

with montly_revenue as
(
select
 format(a.appointment_date,'yyyy-MM') as months,
 sum(pay.amount) as Revenue
from Appointments as a 
left join Payments as pay
on a.Appointment_ID=pay.Appointment_ID
group by format(a.appointment_date,'yyyy-MM')
),
prior_revenue as
(
 select *,
 lag(revenue)over(order by months) as Prior_month_revenue
 from montly_revenue
)
select *,
 cast(
  (revenue-Prior_month_revenue)*100.0/nullif(Prior_month_revenue,0) as decimal(10,1)
 ) as percentage_growth
from prior_revenue

--Q20
--Quarterly Appointment Status Report
--BUSINESS REQUIREMENT / RETURN
--For each quarter, the count of appointments broken down by Status (Completed, Cancelled, No-Show,
--Scheduled, etc.) alongside the completion rate as a percentage.
--CONDITIONS
--• Derive the quarter from Appointment_Date.
--BUSINESS RULES
--• Completion rate = completed appointments divided by total appointments for that quarter, rounded to one
--decimal place.
--• All statuses appearing in the data during a quarter must be represented in that quarter's row or breakdown.
--SORTING REQUIREMENT
--Order chronologically by quarter.
with quarters as
(
select
 appointment_id,
 status,
 concat(
    year(appointment_date),
    '-q',
    datepart(quarter, appointment_date)
        ) as quarter
from appointments
),
quarter_report as
(
 select
  quarter,
  count(case
          when status = 'completed'
           then appointment_id
        end) as completed_appointments,
  count(case
            when status = 'cancelled'
            then appointment_id
        end) as cancelled_appointments,
  count(case
            when status = 'no-show'
            then appointment_id
        end) as no_show_appointments,

        count(case
            when status = 'scheduled'
            then appointment_id
        end) as scheduled_appointments,

        count(*) as total_appointments

    from quarters
    group by quarter
)
select *,
    cast(
        completed_appointments * 100.0 /
        nullif(total_appointments, 0)
        as decimal(10,1)
    ) as completion_rate
from quarter_report
order by quarter;

