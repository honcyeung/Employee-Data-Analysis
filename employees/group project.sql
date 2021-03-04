USE employees;

#1. List of employees with the following information: First name, last name, gender, age, number of years spent in the company, department, the year they joined the department, and their current job title.
SELECT
	first_name AS 'First Name',
	last_name AS 'Last Name',
	gender AS 'Gender',
	TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS Age,
	dept_name AS 'Department',
	demp.from_date AS 'Year of joining the department',
	title AS 'Current Job Title',
CASE WHEN demp.to_date = '9999-01-01' THEN TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) 
	 ELSE TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date)
     END AS 'No. of Serving Years',
CASE WHEN demp.to_date = '9999-01-01' THEN 'Existing employee'
	 ELSE 'Ex-Staff'
     END AS 'Employment Status'
FROM titles AS t1
JOIN employees AS emp ON emp.emp_no = t1.emp_no 
JOIN dept_emp AS demp ON demp.emp_no = emp.emp_no
JOIN departments AS dep ON dep.dept_no = demp.dept_no
LEFT JOIN titles AS t2 ON (t1.emp_no = t2.emp_no AND t1.from_date < t2.from_date)
WHERE t2.from_date IS NULL;


-- finding: the table contains ‘ANCIENT’ data, i.e. ex-staff who left the company 15 years ago….


#2. The number of employees per department.
SELECT 
demp.dept_no,
dept_name,
COUNT(*) 'number of employees'
FROM dept_emp demp
JOIN departments as dep on dep.dept_no = demp.dept_no
GROUP BY dept_no
ORDER BY COUNT(*);


#3. List of employees per department, their positions, and salaries. Make a separate list for each department.
select 
first_name as 'first name',
last_name as 'last name',
dept_name as 'department',
title as 'current position',
salary
from employees as emp
join dept_emp as demp on demp.emp_no = emp.emp_no
join departments as dep on dep.dept_no = demp.dept_no
join titles as t on t.emp_no = emp.emp_no
join salaries as s on s.emp_no = emp.emp_no
where dept_name='Customer Service';



#4. List of the average salary of employees in each job position (title).
select 
title as 'current position',
avg(salary)
from salaries as s
join titles as t on t.emp_no = s.emp_no
group by title;

#5. List of the average age of employees in (i) the company, (ii) each department, (iii) each job position.
select
AVG(TIMESTAMPDIFF(YEAR, birth_date, CURDATE())) 'average age'
from employees;

select
dept_name,
AVG(TIMESTAMPDIFF(YEAR, birth_date, CURDATE())) 'average age'
from employees as emp
join dept_emp as demp on demp.emp_no = emp.emp_no
join departments as dep on dep.dept_no = demp.dept_no
group by dept_name;

select
title,
AVG(TIMESTAMPDIFF(YEAR, birth_date, CURDATE())) 'average age'
from employees as emp
join titles as t on t.emp_no = emp.emp_no
group by title;

#6. What is the ratio of me to women in (i) each department; (ii) each job position (title).
select gender, count(*)
  from employees
 group by gender;
 
select
sum(case when `gender` = 'M' then 1 else 0 end)/count(*) as male_ratio,
sum(case when `gender` = 'F' then 1 else 0 end)/count(*) as female_ratio
from employees;

select
dept_name,
sum(case when `gender` = 'M' then 1 else 0 end) /
sum(case when `gender` = 'F' then 1 else 0 end) as 'ratio of men to women'
from employees as emp
join dept_emp as demp on demp.emp_no = emp.emp_no
join departments as dep on dep.dept_no = demp.dept_no
group by dept_name;

select
title,
sum(case when `gender` = 'M' then 1 else 0 end) /
sum(case when `gender` = 'F' then 1 else 0 end) as 'ratio of men to women'
from employees as emp
join titles as t on t.emp_no = emp.emp_no
group by title;

#7. List of employees with (i) the lowest salary, (ii) the highest salary (iii) above average salary.
SELECT 
first_name as 'fist name',
last_name as 'last name',
dept_name as 'department',
title as 'current position',
salary
FROM employees as emp
join dept_emp as demp on demp.emp_no = emp.emp_no
join departments as dep on dep.dept_no = demp.dept_no
join titles as t on t.emp_no = emp.emp_no
join salaries as s on s.emp_no = emp.emp_no
WHERE salary = (SELECT MIN(salary) FROM salaries);
#the lowest salary=38623

SELECT 
first_name as 'fist name',
last_name as 'last name',
dept_name as 'department',
title as 'current position',
salary
FROM employees as emp
join dept_emp as demp on demp.emp_no = emp.emp_no
join departments as dep on dep.dept_no = demp.dept_no
join titles as t on t.emp_no = emp.emp_no
join salaries as s on s.emp_no = emp.emp_no
WHERE salary = (SELECT MAX(salary) FROM salaries);
#the highest salary=158220

SELECT 
first_name as 'fist name',
last_name as 'last name',
dept_name as 'department',
title as 'current position',
salary
FROM employees as emp
left join dept_emp as demp on demp.emp_no = emp.emp_no
left join departments as dep on dep.dept_no = demp.dept_no
left join titles as t on t.emp_no = emp.emp_no
left join salaries as s on s.emp_no = emp.emp_no
WHERE salary > (SELECT AVG(salary) FROM salaries);

#8. List of employees who joined the company in December.
SELECT *
FROM employees
WHERE to_char(hire_date, 'mon')='dec';

#9. List of the most experienced employees (by the number of years) in each department and the company as a whole.
select 
first_name as 'fist name',
last_name as 'last name',
hire_date as 'hire date',
TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date) 'number of years spent in the company',
dept_name as 'department',
title as 'current job title'
from employees as emp
join dept_emp as demp on demp.emp_no = emp.emp_no
join departments as dep on dep.dept_no = demp.dept_no
join titles as t on t.emp_no = emp.emp_no
order by TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date) DESC;

#10. List of the most recently hired employees (that is, the year the most recent employee was recruited).
SELECT 
first_name as 'fist name',
last_name as 'last name',
dept_name as 'department',
title as 'current position',
hire_date
FROM employees as emp
join dept_emp as demp on demp.emp_no = emp.emp_no
join departments as dep on dep.dept_no = demp.dept_no
join titles as t on t.emp_no = emp.emp_no
WHERE hire_date = (SELECT MAX(hire_date) FROM employees);
# 11 Sarah
list of employees got promoted and/or changed dept
-> reward system??














SELECT
	first_name AS 'First Name',
	last_name AS 'Last Name',
	gender AS 'Gender',
	TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS Age,
	dept_name AS 'Department',
	demp.from_date AS 'Year of joining the department',
	title AS 'Current Job Title',
CASE WHEN demp.to_date = '9999-01-01' THEN TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) 
	 ELSE TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date)
     END AS 'No. of Serving Years',
CASE WHEN demp.to_date = '9999-01-01' THEN 'Existing employee'
	 ELSE 'Ex-Staff'
     END AS 'Employment Status'
FROM titles AS t1
JOIN employees AS emp ON emp.emp_no = t1.emp_no 
JOIN dept_emp AS demp ON demp.emp_no = emp.emp_no
JOIN departments AS dep ON dep.dept_no = demp.dept_no
LEFT JOIN titles AS t2 ON (t1.emp_no = t2.emp_no AND t1.from_date < t2.from_date)
WHERE t2.from_date IS NULL
SELECT
	first_name AS 'First Name',
	last_name AS 'Last Name',
	gender AS 'Gender',
	TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS Age,
	dept_name AS 'Department',
	demp.from_date AS 'Year of joining the department',
	title AS 'Current Job Title',
CASE WHEN demp.to_date = '9999-01-01' THEN TIMESTAMPDIFF(YEAR, demp.from_date, CURDATE()) 
	 ELSE TIMESTAMPDIFF(YEAR, demp.from_date, demp.to_date)
     END AS 'No. of Serving Years',
CASE WHEN demp.to_date = '9999-01-01' THEN 'Existing employee'
	 ELSE 'Ex-Staff'
     END AS 'Employment Status'
FROM titles AS t1
JOIN employees AS emp ON emp.emp_no = t1.emp_no 
JOIN dept_emp AS demp ON demp.emp_no = emp.emp_no
JOIN departments AS dep ON dep.dept_no = demp.dept_no
LEFT JOIN titles AS t2 ON (t1.emp_no = t2.emp_no AND t1.from_date < t2.from_date)
WHERE t2.from_date IS NULL