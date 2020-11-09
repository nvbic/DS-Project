use ds;
/*
Define cohort, patients with/without Diabetes
Extract demographics information for other patients
Figure out the first onset (diagnosis) time for Diabetes, as I assume all the medication dispensed
and other diagnoses would be before this time.
*/

create temporary table temp_cohort as
select 
    derived.person_id,
    sum(derived.dia_flag) as count_dia,
    case
        when sum(derived.dia_flag) > 0 then 1
        else 0
    end as diabetes
from
    (select 
        co.person_id,
            co.condition_concept_id,
            dia_code.concept_name,
            case
                when dia_code.concept_name != '' then 1
                else 0
            end as dia_flag
    from
        condition_occurrence as co
    left join (select distinct
        condition_concept_id, concept_name, count(*) as ct
    from
        condition_occurrence, concept
    where
        condition_concept_id = concept.concept_id
            and concept_name like '%diabete%'
    group by condition_concept_id
    order by ct desc) as dia_code on co.condition_concept_id = dia_code.condition_concept_id) as derived
group by person_id;

select 
    count(person_id)
from
    temp_cohort
where
    diabetes = 0;/* 159*/
select 
    count(person_id)
from
    temp_cohort
where
    diabetes = 1;/* 771 --- 930 = 159+771*/  
select 
    count(distinct person_id)
from
    condition_occurrence;    /* 930 in total, but 1000 patients*/

/* Patients Demographics */
create temporary table temp_demographics as 
select p.person_id,
	   co1.concept_name as gender,
       co2.concept_name as race,
       co3.concept_name as ethnicity
       from person as p
left join concept as co1 
on p.gender_concept_id = co1.concept_id
left join concept as co2
on p.race_concept_id = co2.concept_id
left join concept as co3
on p.ethnicity_concept_id = co3.concept_id;

/* Ways to determine medicine and diagnoses
--- Drugs used before Diabetes diagnosis date
--- Other diagnoses happened before Diabetes date
*/

/* Find earliest date of diagnosis of Diabetes */
create temporary table temp_diabetes_onset_time as  
select person_id,
       min(condition_start_date) as onset_time
       from
(select co.person_id,
       co.condition_concept_id,
	   dia_code.concept_name,
       co.condition_start_date,
       co.condition_end_date 
       from condition_occurrence as co
	   inner join (select distinct
        condition_concept_id, concept_name, count(*) as ct
    from
        condition_occurrence, concept
    where
        condition_concept_id = concept.concept_id
            and concept_name like '%diabete%'
    group by condition_concept_id
    order by ct desc) as dia_code
    on co.condition_concept_id = dia_code.condition_concept_id) as derived
    group by person_id;

select * from temp_cohort;
select * from temp_diabetes_onset_time;
select * from temp_demographics;
/* Merge this with cohort */
select tc.person_id,
       tc.diabetes,
       td.onset_time,
       tdemo.gender,
       tdemo.race, 
       tdemo.ethnicity
       from temp_cohort as tc
left join temp_diabetes_onset_time as td
on tc.person_id = td.person_id
inner join temp_demographics as tdemo
on tc.person_id = tdemo.person_id
order by tc.person_id;
