
********************************************************************************
/* Preliminaries */
********************************************************************************
	clear
	set more off

*path information

	*global root "C:\Users\tcoli\Box Sync\RISE Tanzania_Research\Papers\School inspectors"
	global root "C:\Users\navishti\Box Sync\RISE Tanzania_Research\Papers\School inspectors"
	global raw "$root\dta\raw"
	global temp "$root\dta\temp"
	global final "$root\dta\final"
	global report "$root\Regional Visits\Compliance Reports\"
********************************************************************************	
	
use "$final/sample_with_notes.dta", clear



use "C:\Users\navishti\Box Sync\RISE Tanzania_Research\Data\Master Key\data\final\Merged Data\EMIS-NECTA-ALL-PRIMARY.dta"
save "$temp\masterkeycopy.dta", replace

use "$temp\masterkeycopy.dta", clear

********************************************************************************

// Merging Replacement List with Masterkey//
use "$final/sample_with_notes.dta"
preserve
keep new_school_tbv
keep if new_school_tbv != "" // List of replacement schools created//
gen new_school_tbv_u = upper(new_school_tbv)
gen pr_school = " PR. SCHOOL"
egen final_new_school = concat (new_school_tbv_u pr_school)
keep final_new_school // List of replacement schools with string variable matching master created//
rename final_new_school necta_centrename2016
merge 1:m necta_centrename2016 using "$temp\masterkeycopy.dta", keep (match)
keep necta_centrename2016 necta_districtname2016 necta_regionname2016 NECTAcode2016 EMIScode2016 // Required info for replacement schools//
save "C:\Users\Navishti\Documents\MPP\RISE\Replacement School Merged With Masterkey.dta"

// Preparing replacement list combined with masterkey to merge with notes sheet//
gen word = word(necta_centrename2016, 2)
replace word = " " if word == "PR."
split necta_centrename2016
egen school = concat (necta_centrename20161 word), punct (" ")
drop word necta_centrename20161 necta_centrename20162 necta_centrename20163 necta_centrename20164
replace school = strproper(school)
rename school new_school_tbv // Final list of replacement scools to match with notes sheet//
replace necta_districtname2016 = lower(necta_districtname2016)
rename necta_districtname2016 rep_district // List of districts in lower case, for consistency
replace necta_regionname2016 = lower(necta_regionname2016)
rename necta_regionname2016 region // Final list of regions to match with notes sheet. Imp secondary variable to match on, since same school name appears in multiple regions. Assumption: Replacement school in same region as sampled school, this is not true for district though//
rename NECTAcode2016 rep_nectaid
rename EMIScode2016 rep_emis
keep rep_nectaid region rep_district new_school_tbv rep_emis
order rep_nectaid region rep_district new_school_tbv rep_emis
save "C:\Users\Navishti\Box Sync\RISE Tanzania_Research\Papers\School inspectors\dta\temp\Replacement School Merged With Masterkey.dta", replace

//Merging with notes sheet//




