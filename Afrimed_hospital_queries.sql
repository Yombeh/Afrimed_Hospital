-- Total completed appointments by each department 
SELECT d.DepartmentName, COUNT(*) AS TotalAppointments
FROM appointments a
JOIN doctors doc ON a.DoctorID = doc.DoctorID
JOIN departments d ON doc.DepartmentID = d.DepartmentID
 WHERE a.status = 'completed'
GROUP BY d.DepartmentName;
  
  
-- counting the number of no shows without a double query
SELECT p.Region,
       COUNT(*) AS TotalAppointments,
       SUM(CASE WHEN a.Status = 'No-show' THEN 1 ELSE 0 END) AS NoShows
FROM appointments a
JOIN patients p ON a.PatientID = p.PatientID
GROUP BY p.Region;

--  Finding the no show Rate 
SELECT p.Region,
       COUNT(*) AS TotalAppointments,
    SUM(CASE WHEN a.Status = 'No-show' THEN 1 ELSE 0 END) AS NoShows,
       (SUM(CASE WHEN a.Status = 'No-show' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS NoShowRate  
FROM appointments a
JOIN patients p ON a.PatientID = p.PatientID
GROUP BY p.Region; 

-- total appointments per month 

SELECT  DATE_FORMAT(a.AppointmentDate, '%Y-%m')  AS AppointmentMonth, COUNT(*) AS TotalAppointments
FROM appointments a
GROUP BY  DATE_FORMAT(a.AppointmentDate, '%Y-%m')
ORDER BY AppointmentMonth;


-- 1. Total revenue by department

-- Path: billing -> appointments -> doctors -> departments
-- -------------------------------------------------------------
SELECT d.DepartmentName, SUM(b.Amount) AS TotalRevenue
FROM billing b
JOIN appointments a ON b.AppointmentID = a.AppointmentID
JOIN doctors doc ON a.DoctorID = doc.DoctorID
JOIN departments d ON doc.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName;