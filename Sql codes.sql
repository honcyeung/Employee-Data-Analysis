-- Q1 : 
-- List of employees with the following information: First name, last name, gender, age, number
-- of years spent in the company, department, the year they joined the department, and their current job title
CREATE TABLE comprehensive_employees AS
SELECT 
	emp.emp_no,
    first_name ,
	last_name ,
	gender ,
	TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS Age,
	dept_name AS Department,
	demp.from_date AS Year_of_joining_the_department,
	t1.title AS title,
    demp.from_date,
    demp.to_date,
CASE WHEN demp.to_date = '9999-01-01' THEN TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) 
	 ELSE TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date)
     END AS No_of_Serving_Years,
CASE WHEN demp.to_date = '9999-01-01' THEN 'Existing employee'
	 ELSE 'Ex-Staff'
     END AS Employment_Status
FROM titles AS t1
JOIN employees AS emp ON emp.emp_no = t1.emp_no 
JOIN dept_emp AS demp ON demp.emp_no = emp.emp_no
JOIN departments AS dep ON dep.dept_no = demp.dept_no
LEFT JOIN titles AS t2 ON (t1.emp_no = t2.emp_no AND t1.from_date < t2.from_date)
WHERE t2.from_date IS NULL;

CREATE TABLE integrated_employees AS
SELECT 
		emp_no,
        first_name ,
        last_name ,
        gender,
        Department,
        title,
        Year_of_joining_the_department ,
        No_of_Serving_Years,
        SUM(No_of_Serving_Years) OVER(PARTITION BY emp_no) AS Total_no_of_Serving_Year,
        Employment_Status
FROM comprehensive_employees;

SELECT 
		first_name AS 'First Name',
        last_name AS 'Last Name',
        gender AS 'Gender',
        Department,
        title AS 'Job Title',
        Year_of_joining_the_department AS 'Year of Joining the Department',
        No_of_Serving_Years AS 'Service Years in the Department',
        Total_no_of_Serving_Year AS 'Service Years in the Company'
FROM employees.integrated_employees 
WHERE Employment_Status = 'Existing employee'
LIMIT 10;

-- Q2 : 
-- The number of employees per department
SELECT 
		dept_name AS 'Department',
		COUNT(*) 'Number of employees'
FROM dept_emp AS demp
JOIN departments AS dep 
	ON dep.dept_no = demp.dept_no
WHERE demp.to_date = '9999-01-01' -- exclude ex-staff
GROUP BY demp.dept_no
ORDER BY COUNT(*);

-- Q3 : 
-- List of employees per department, their positions, and salaries
-- 'Sales Department' as an example. Change "WHERE 'dept_name' " to other department names and 
-- and you will see the corresponding list
SELECT  
		first_name AS 'First Name',
        last_name AS 'Last Name',
        gender AS 'Gender',
        title AS 'Current Job Title',
        salary AS 'Salary',
        dept_name AS 'Department',
CASE WHEN demp.to_date = '9999-01-01' THEN TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) 
	 WHEN dma.to_date = '9999-01-01' THEN TIMESTAMPDIFF(YEAR, dma.from_date, dma.to_date)
     WHEN dma.to_date != '9999-01-01' THEN TIMESTAMPDIFF(YEAR, dma.from_date, CURDATE()) 
	 ELSE TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date)
     END AS 'No. of Serving Years'
FROM employees AS emp
LEFT JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
LEFT JOIN dept_manager AS dma
	ON dma.emp_no = emp.emp_no
JOIN departments AS dept
	ON demp.dept_no = dept.dept_no
JOIN salaries AS sala
	ON demp.emp_no = sala.emp_no
JOIN titles AS t
	ON emp.emp_no = t.emp_no
WHERE dept.dept_name = 'Sales' AND (dma.to_date = '9999-01-01' OR demp.to_date = '9999-01-01')AND 
		sala.to_date = '9999-01-01' AND t.to_date = '9999-01-01' 
ORDER BY salary DESC
LIMIt 10;


-- Q4 : 
-- List of the average salary of employees in each job position (title)
SELECT 
		title AS 'Job Title',
        AVG(s.salary) AS 'Average Salary'
FROM titles AS t
JOIN salaries AS s
	ON t.emp_no = s.emp_no
WHERE t.to_date = '9999-01-01'  -- exclude former staff
GROUP BY title
ORDER BY AVG(s.salary) DESC;

-- Q5 :
-- List of the average age of employees in (i) the company, (ii) each department, (iii) each job position.
-- (i) Whole Company: 
SELECT AVG(timestampdiff(YEAR, birth_date, CURDATE())) AS 'Average Age'
FROM employees AS emp
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN dept_manager AS dma
	ON dma.emp_no = emp.emp_no
WHERE demp.to_date = '9999-01-01' OR dma.to_date = '9999-01-01'; -- exclude ex-staff

-- (ii) By Department :
 -- Include manager and exclude ex-staff
SELECT 
		dept_name AS 'Department',
		AVG(timestampdiff(YEAR, birth_date, CURDATE())) AS 'Average Age'
FROM employees AS emp
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN dept_manager AS dma
	ON dma.emp_no = emp.emp_no
JOIN departments AS dept
	ON dept.dept_no = demp.dept_no
WHERE demp.to_date = '9999-01-01' OR dma.to_date = '9999-01-01'
GROUP BY dept.dept_no
ORDER BY AVG(timestampdiff(YEAR, birth_date, CURDATE())) DESC;

-- (iii) By Title : 
SELECT 
		title AS 'Job Title',
		AVG(timestampdiff(YEAR, birth_date, CURDATE())) AS 'Average Age'
FROM employees AS emp
JOIN titles AS t
	ON t.emp_no = emp.emp_no
WHERE t.to_date = '9999-01-01' -- include current job title of existing employee ONLY
GROUP BY title
ORDER BY AVG(timestampdiff(YEAR, birth_date, CURDATE())) DESC;

-- Q6 :
-- What is the ratio of men to women in (i) each department; (ii) each job position (title)
-- (i) By Department : 
SELECT 
		dept_name AS 'Department',
        SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END)/COUNT(*) AS 'Ratio of Men',
        SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END)/COUNT(*) AS 'Ratio of Women',
        SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) /
		SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS 'Ratio of Men to Women'
FROM employees AS emp
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN departments AS dept
	ON dept.dept_no = demp.dept_no
WHERE demp.to_date = '9999-01-01'
GROUP BY dept_name
ORDER BY (SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) /
		SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END)) DESC ;
 
 -- (ii) By title :
SELECT 
		title AS 'Job Position',
        SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END)/COUNT(*) AS 'Ratio of Men',
        SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END)/COUNT(*) AS 'Ratio of Women',
        SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) /
		SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS 'Ratio of Men to Women'
FROM employees AS emp
JOIN titles AS t
	ON t.emp_no = emp.emp_no
WHERE t.to_date = '9999-01-01' -- Exclude ex-staff 
GROUP BY title
ORDER BY (SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) /
		SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END)) DESC ;

-- Q7 :
-- List of employees with (i) the lowest salary, (ii) the highest salary (iii) above average salary
-- (i)  list of top 10 lowest salary:       
SELECT 
		first_name AS 'First Name',
        last_name AS 'Last Name',
        gender AS Gender,
        salary AS Salary,
        title AS 'Current  Position',
        dept_name AS Department,
        TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) AS 'No. of Serving Years in the Department'
FROM employees AS emp
JOIN salaries AS s
	ON emp.emp_no = s.emp_no
JOIN titles AS t
	ON emp.emp_no = t.emp_no
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN departments AS d
	ON demp.dept_no = d.dept_no
WHERE s.to_date = '9999-01-01' AND t.to_date = '9999-01-01'  AND demp.to_date = '9999-01-01'
ORDER BY salary
LIMIT 10;

-- (ii) top 10 highest salary :
SELECT 
		first_name AS 'First Name',
        last_name AS 'Last Name',
        gender AS Gender,
        salary AS Salary,
        title AS 'Current  Position',
        dept_name AS Department,
		TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) AS 'No. of Serving Years in the Department'
FROM employees AS emp
JOIN salaries AS s
	ON emp.emp_no = s.emp_no
JOIN titles AS t
	ON emp.emp_no = t.emp_no
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN departments AS d
	ON demp.dept_no = d.dept_no
WHERE s.to_date = '9999-01-01' AND t.to_date = '9999-01-01' AND demp.to_date = '9999-01-01'
ORDER BY salary DESC
LIMIT 10;


-- Q8 :
SELECT 
		first_name AS 'First Name',
        last_name AS 'Last Name',
        dept_name AS Department,
        title AS 'Current Position',
        hire_date AS 'Hire Date'
FROM employees AS emp
JOIN dept_emp AS demp
	ON demp.emp_no = emp.emp_no
LEFT JOIN dept_manager AS dma
	ON dma.emp_no = emp.emp_no
JOIN departments AS d
	ON d.dept_no = demp.dept_no
JOIN titles AS t
	ON t.emp_no = emp.emp_no
WHERE hire_date LIKE '%12-%' AND demp.to_date = '9999-01-01' AND t.to_date = '9999-01-01'
ORDER BY hire_date
LIMIT 10 ;

-- (iii) Above average salary :
SELECT 
		first_name AS 'First Name',
        last_name AS 'Last Name',
        gender AS Gender,
        salary AS Salary,
        title AS 'Current  Position',
        dept_name AS Department,
		TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) AS 'No. of Serving Years in the Department'
FROM employees AS emp
JOIN salaries AS s
	ON emp.emp_no = s.emp_no
JOIN titles AS t
	ON emp.emp_no = t.emp_no
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN departments AS d
	ON demp.dept_no = d.dept_no
WHERE s.to_date = '9999-01-01' AND t.to_date = '9999-01-01' AND demp.to_date = '9999-01-01'
	AND salary > (SELECT AVG(salary) FROM salaries)
ORDER BY salary 
LIMIT 10;

-- Q8 :
-- List of employees who joined the company in December
SELECT 
		first_name AS 'First Name',
        last_name AS 'Last Name',
        dept_name AS Department,
        title AS 'Current Position',
        hire_date AS 'Hire Date'
FROM employees AS emp
JOIN dept_emp AS demp
	ON demp.emp_no = emp.emp_no
LEFT JOIN dept_manager AS dma
	ON dma.emp_no = emp.emp_no
JOIN departments AS d
	ON d.dept_no = demp.dept_no
JOIN titles AS t
	ON t.emp_no = emp.emp_no
WHERE hire_date LIKE '%12-%' AND demp.to_date = '9999-01-01' AND t.to_date = '9999-01-01'
ORDER BY hire_date
LIMIT 10 ;

-- Q8 extra : no. of employees hired per month
SELECT 
		COUNT(*) AS 'No. of Employees Hired',
        MONTH(hire_date) AS 'Hire Month'
FROM employees AS emp
JOIN dept_emp AS demp
	ON demp.emp_no = emp.emp_no
LEFT JOIN dept_manager AS dma
	ON dma.emp_no = emp.emp_no
JOIN departments AS d
	ON d.dept_no = demp.dept_no
JOIN titles AS t
	ON t.emp_no = emp.emp_no
WHERE demp.to_date = '9999-01-01' AND t.to_date = '9999-01-01'
GROUP BY MONTH(hire_date)
ORDER BY COUNT(*) DESC;

-- Q9 :
-- List of the most experienced employees (by the number of years) in each department and the company as a whole
-- (i) Whole Company : 
SELECT  
		first_name AS 'First Name',
        last_name AS 'Last Name',   
        dept_name AS Department,
        title AS 'Current Position',        
        demp.from_date AS 'Hire Date',
        TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS 'No. of Years Serving in the Company'     
FROM employees AS emp
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN departments AS d
	ON d.dept_no = demp.dept_no
JOIN titles AS t
	ON t.emp_no = emp.emp_no
WHERE demp.to_date = '9999-01-01' AND t.to_date = '9999-01-01' 
ORDER BY TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) DESC, hire_date
LIMIT 10;

-- (ii) by Department :
-- 'Sales Department' as an example. Change "WHERE 'dept_name' " to other department names and 
-- and you will see the corresponding list
SELECT  
		first_name AS 'First Name',
        last_name AS 'Last Name',        
        title AS 'Current Position',
        TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) AS 'No. of Years Serving in the Department',
        demp.from_date AS 'First Day in the Department',
        dept_name AS Department
FROM employees AS emp
JOIN dept_emp AS demp
	ON emp.emp_no = demp.emp_no
JOIN departments AS d
	ON d.dept_no = demp.dept_no
JOIN titles AS t
	ON t.emp_no = emp.emp_no
WHERE demp.to_date = '9999-01-01' AND t.to_date = '9999-01-01' AND dept_name = 'Sales'
ORDER BY TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) DESC, demp.from_date 
LIMIT 10;

-- Q10 :
-- List of the most recently hired employees (that is, the year the most recent employee was recruited)
SELECT  
		first_name AS 'First Name',
        last_name AS 'Last Name', 
        dept_name AS Department,
        title AS 'Last Position',
        hire_date AS 'Hire Date',
        demp.to_date AS 'Resignation Date/ Switching Department Date',
CASE WHEN demp.to_date = '9999-01-01' THEN TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) 
	 ELSE TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date)
     END AS 'No. of Serving Years in the department',   
CASE WHEN t.to_date = '9999-01-01' THEN 'Existing employee'
	 ELSE 'Ex-Staff'
     END AS 'Employment Status'    
FROM employees AS emp
JOIN dept_emp AS demp
	ON demp.emp_no = emp.emp_no
JOIN titles AS t
	ON t.emp_no = emp.emp_no
JOIN departments AS d
	ON d.dept_no = demp.dept_no
-- WHERE demp.to_date = '9999-01-01'
ORDER BY hire_date DESC
LIMIT 10;

-- Q11 
-- list of employees got promoted and/or changed department
-- (i)change department :
SELECT 
		cem1.first_name,
		cem1.last_name,
		cem1.Department 'Previous Department',
		cem2.Department,
		TIMESTAMPDIFF(YEAR, cem1.Year_of_joining_the_department,cem2.Year_of_joining_the_department) 'Years'
FROM comprehensive_employees cem1
JOIN comprehensive_employees cem2 ON (cem2.emp_no = cem1.emp_no AND cem1.Year_of_joining_the_department < cem2.Year_of_joining_the_department)
WHERE cem1.Department <> cem2.Department AND cem2.Employment_Status = 'Existing employee';

-- (ii) get promoted :
SELECT 
		first_name 'First Name',
		last_name 'Last Name',
		t1.title 'Previous Title',
		t2.title 'Title',
		TIMESTAMPDIFF(YEAR, t1.from_date,t2.from_date) 'Years'
FROM titles t1
JOIN titles t2 ON (t1.emp_no = t2.emp_no AND t1.from_date < t2.from_date)
JOIN integrated_employees inte ON inte.emp_no = t2.emp_no
WHERE inte.Employment_Status = 'Existing employee';

-- Q12 :
-- Which department pays the most on average?
SELECT 
		Department,
		AVG(salary) 'Average Salary'
FROM integrated_employees inte 
JOIN salaries AS sal 
	ON sal.emp_no = inte.emp_no
WHERE Employment_Status = 'Existing employee'
GROUP BY Department 
ORDER BY AVG(salary) DESC;

-- Q13 :
-- list of highest salary of each job position(add “gender”)
SELECT 
		title,
		Department,
		Total_no_of_Serving_Year,
		MAX(salary) salary
FROM integrated_employees inte
JOIN salaries AS sal 
	ON sal.emp_no = inte.emp_no
WHERE Employment_Status = 'Existing employee'
GROUP BY title 
ORDER BY salary;

-- Q14:
-- lowest salary of each job position
SELECT 
		title,
		Department,
		gender,
		Total_no_of_Serving_Year,
		MIN(salary) salary
FROM integrated_employees inte
JOIN salaries AS sal 
	ON sal.emp_no = inte.emp_no
WHERE Employment_Status = 'Existing employee'
GROUP BY title
ORDER BY salary;

-- Q15
-- average pay of men vs women
SELECT
		gender,
		AVG(salary) salary
FROM salaries s
JOIN integrated_employees AS inte 
	ON inte.emp_no = s.emp_no
WHERE Employment_Status = 'Existing employee'
GROUP BY gender;

-- Q15
-- Compare the salary between 2 genders with same title and same working years
-- Senior engineers as example
SELECT
	*
FROM (
	SELECT
		AVG(s1.salary) AS 'Salary(men)',
		Total_no_of_Serving_Year
	FROM salaries s1
	JOIN integrated_employees AS inte 
		ON inte.emp_no = s1.emp_no
	LEFT JOIN salaries AS s2 
		ON (s1.emp_no = s2.emp_no AND s1.from_date < s2.from_date)
	WHERE s2.from_date IS NULL AND 
		Employment_Status = 'Existing employee' AND
		title = 'Senior Engineer' AND gender ='M'
	GROUP BY Total_no_of_Serving_Year
	ORDER BY Total_no_of_Serving_Year) AS sal1

JOIN (
	SELECT
		AVG(s1.salary) AS 'Salary(women)',
		Total_no_of_Serving_Year
	FROM salaries AS s1
	JOIN integrated_employees AS inte
		ON inte.emp_no = s1.emp_no
	LEFT JOIN salaries AS s2 
		ON (s1.emp_no = s2.emp_no AND s1.from_date < s2.from_date)
	WHERE s2.from_date IS NULL AND
		Employment_Status = 'Existing employee' AND
		title = 'Senior Engineer' AND gender ='F'
	GROUP BY Total_no_of_Serving_Year
	ORDER BY Total_no_of_Serving_Year) AS sal2 
ON sal1.Total_no_of_Serving_Year = sal2.Total_no_of_Serving_Year;

-- Q16 :
-- list of loyal employees with low salary
SELECT
		first_name 'First Name',
		last_name 'Last Name',
		gender 'Gender',
		title 'Current Position',
		Department,
		Total_no_of_Serving_Year 'No of Years Serving in the Department', 
		s1.salary 'Salary'
FROM salaries s1
JOIN integrated_employees AS inte 
	ON s1.emp_no = inte.emp_no
LEFT JOIN salaries AS s2 
	ON (s1.emp_no = s2.emp_no AND s1.from_date < s2.from_date)
WHERE s2.from_date IS NULL AND Employment_Status = 'Existing employee'
ORDER BY salary;

-- pick the first five employees to check if their salaries decrease 
SELECT * 
FROM employees.salaries
WHERE emp_no IN (253406, 245832, 401786 ,15830 , 230890);
