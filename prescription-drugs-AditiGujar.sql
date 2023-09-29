--Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, sum(total_claim_count) as total_claims
from prescription
GROUP by npi
ORDER by total_claims DESC;

SELECT * FROM prescriber

--Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims

SELECT nppes_provider_first_name as first_name,nppes_provider_last_org_name as last_name,
specialty_description, sum(total_claim_count) as total_claims
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY first_name,last_name,specialty_description
ORDER BY total_claims DESC


--Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description as spec_desc, sum(total_claim_count) as total_claims
from prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY spec_desc
ORDER BY total_claims DESC

--Which specialty had the most total number of claims for opioids?
SELECT specialty_description as spec_desc, sum(total_claim_count) as total_claims
from prescriber
INNER JOIN prescription USING(npi)
--ON prescriber.npi = prescription.npi
INNER  JOIN drug USING(drug_name)
WHERE opioid_drug_flag = 'Y' 
GROUP BY spec_desc
ORDER BY total_claims DESC



-- **Challenge Question:** Are there any specialties that appear in the prescriber table that have 
--no associated prescriptions in the prescription table?

SELECT specialty_description
from prescriber
WHERE npi NOT IN (select distinct npi from prescription)



SELECT specialty_description
from prescriber
WHERE NOT exists (SELECT 1
				  from prescription
				  WHERE prescriber.npi = prescription.npi)



select specialty_description
from prescriber ps left outer join prescription pb on ps.npi = pb.npi 
where pb.npi is null


--For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?


SELECT specialty_description as spec_desc, sum(total_claim_count) as spec_claims,
(Select sum(total_claim_count) from prescription) as all_spec_claims, (sum(total_claim_count)/(Select sum(total_claim_count) from prescription)*100)

from prescriber
INNER JOIN prescription USING(npi)
INNER  JOIN drug USING(drug_name)
WHERE opioid_drug_flag = 'Y' 
--ORDER BY total_claim DESC

--Which drug (generic_name) had the highest total drug cost

SELECT generic_name,max(total_drug_cost) as drug_cost
from prescription
INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY drug_cost DESC
LIMIT 1




--Which drug (generic_name) has the hightest total cost per day?

SELECT generic_name, round(avg(total_drug_cost/total_day_supply),2) as drug_cost
from prescription
INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY drug_cost DESC

--For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
--says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' else 'neither' end as drug_type
from drug
order by drug_name

--Building off of the query you wrote for part a, 
--determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 

SELECT sum(total_drug_cost),
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' else 'neither' end as drug_type
from drug
INNER JOIN prescription USING (drug_name)
GROUP by drug_type
order by drug_type ASC


-- many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT count(cbsa)
FROM cbsa
WHERE cbsaname ILIKE '%TN'



-- Which cbsa has the largest combined population? Which has the smallest? Report the 
--CBSA name and total population
SELECT *
FROM cbsa

SELECT * from drug

SELECT cbsaname as cbsa_name, min(population) as small_pop,max(population)as large_pop ,sum(population) as total_pop
FROM cbsa
INNER JOIN population
on cbsa.fipscounty = population.fipscounty
GROUP BY cbsa_name
ORDER by cbsa_name desc

/*whthat is the largest (in terms of population) county which is not included in a CBSA? 
Report the county name and population.What is the largest (in terms of population) 
county which is not included in a CBSA? Report the county name and population.
SELECT * from population */

SELECT * from fips_county
SELECT* FROM cbsa
SELECT * FROM population

SELECT county, population
FROM fips_county
INNER JOIN population USING(fipscounty)
WHERE fipscounty not in (SELECT distinct fipscounty from cbsa)
ORDER BY population DESC
LIMIT 1

--Find all rows in the prescription table where total_claims is at least 3000. 
--Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
from prescription
WHERE total_claim_count >= 3000



--For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name,total_claim_count, opioid_drug_flag as opioid
from prescription
INNER JOIN drug USING (drug_name)
WHERE total_claim_count > 3000 and opioid_drug_flag = 'Y'


--Add another column to you answer from the previous part which gives the 
--prescriber first and last name associated with each row.
SELECT nppes_provider_last_org_name as last_name, nppes_provider_first_name as first_name,drug_name,total_claim_count, opioid_drug_flag as opioid 
from prescription
INNER JOIN drug USING (drug_name)
INNER JOIN prescriber USING(npi)
WHERE total_claim_count > 3000 and opioid_drug_flag = 'Y'



--The goal of this exercise is to generate a full list of all pain management specialists 
--in Nashville and the number of claims they had for each opioid. 
--**Hint:** The results from all 3 parts will have 637 rows.
--a. First, create a list of all npi/drug_name combinations for pai.n management 
--specialists (specialty_description = 'Pain Managment') in the city of Nashville
--(nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
--**Warning:** Double-check your query before running it. You will only need to use the prescriber
--and drug tables since you don't need the claims numbers yet.


SELECT npi,drug_name
from prescriber
cross JOIN drug 
where specialty_description Ilike 'Pain Management%' and nppes_provider_city = 'NASHVILLE' 
and drug.opioid_drug_flag = 'Y'

--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
--whether or not the prescriber had any claims. You should report the npi, 
--the drug name, and the number of claims (total_claim_count).

WITH nashville_data AS (SELECT npi,opioid_drug_flag,drug_name
FROM prescriber
CROSS JOIN drug
WHERE nppes_provider_city = 'NASHVILLE'
	  AND specialty_description = 'Pain Management'
	  AND opioid_drug_flag = 'Y')
SELECT npi,opioid_drug_flag,COALESCE(total_claim_count,0),drug_name
FROM nashville_data
LEFT JOIN prescription USING (npi, drug_name)


--How many npi numbers appear in the prescriber table but not in the prescription table?


SELECT *
from prescription

SELECT *
from prescriber
where npi not IN (select DISTINCT npi from prescription)

SELECT count(npi)
from prescriber
where not EXISTS (select npi from prescription
					 WHERE prescriber.npi = prescription.npi)



--a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT *
from prescriber

SELECT *
from drug


SELECT *
FROM prescription

SELECT generic_name, sum(total_claim_count)as drug_cost
FROM prescription
INNER join drug using(drug_name)
INNER join prescriber using(npi)
WHERE specialty_description = 'Family Practice'
GROUP by generic_name
ORDER by drug_cost DESC
LIMIT 5

--B. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name, sum(total_claim_count)as drug_cost
FROM prescription
INNER join drug using(drug_name)
INNER join prescriber using(npi)
WHERE specialty_description = 'Cardiology'
GROUP by generic_name
ORDER by drug_cost DESC
LIMIT 5


--Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what 
--you did for parts a and b into a single query to answer this question.

SELECT part_a.generic_name,part_a.FP_dcost,part_b.cardi_cost, (part_a.FP_dcost +part_b.cardi_cost) as total_cost
FROM 
(SELECT generic_name, sum(total_claim_count)as FP_dcost
FROM prescription
INNER join drug using(drug_name)
INNER join prescriber using(npi)
WHERE specialty_description = 'Family Practice'
GROUP by generic_name) as part_a
INNER JOIN 
(SELECT generic_name, sum(total_claim_count)as cardi_cost
FROM prescription
INNER join drug using(drug_name)
INNER join prescriber using(npi)
WHERE specialty_description = 'Cardiology'
GROUP by generic_name) as part_b
USING(generic_name)
ORDER by total_cost desc
LIMIT 5




---First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
--Report the npi, the total number of claims, and include a column showing the city.
SELECT *
from prescriber

SELECT *
FROM prescription

SELECT nppes_provider_first_name as provider_name, npi, sum(total_claim_count)as total_claim
FROM prescription
INNER join prescriber using(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP by npi,provider_name
ORDER by total_claim DESC
LIMIT 5


---, report the same for Memphis.

SELECT nppes_provider_first_name as provider_name, npi, sum(total_claim_count)as total_claim
FROM prescription
INNER join prescriber using(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP by npi,provider_name
ORDER by total_claim DESC
LIMIT 5


----Combine your results from a and b, along with the results for Knoxville and Chattanooga.








----Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths

SELECT *
FROM overdose_deaths

SELECT county,sum(overdose_deaths)
FROM overdose_deaths
inner join fips_county
on fips_county.fipscounty ::int =overdose_deaths.fipscounty
WHERE overdose_deaths >(Select avg(overdose_deaths) from overdose_deaths)
GROUP by county
ORDER by county ASC 



--Write a query that finds the total population of Tennessee.
SELECT *
from fips_county

SELECT *
from population

SELECT state, sum(population)
FROM population
INNER join fips_county 
on fips_county.fipscounty = population.fipscounty
WHERE state = 'TN'
GROUP by State


--Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, 
--and the percentage of the total population of Tennessee that is contained in that county.
SELECT *
FROM population

SELECT state,county,round(100* population/sum(population) over(),1) as percent
FROM population
INNER join fips_county 
on fips_county.fipscounty = population.fipscounty
WHERE state = 'TN'
GROUP by State,county, population 

ORDER BY percent DESC

