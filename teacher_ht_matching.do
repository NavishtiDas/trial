dis c(username)

if c(username)=="Navishti" {
	global user "C:/Users/Navishti/Box Sync"
	}

cd "$user/RISE Tanzania_Research/2018 Data Collection/Baseline Survey/Cross-Instrument Checks"
global grades_excel "Grade_discrepencies_HTListing_Teacher.xlsx"
global ht_grades "$user/RISE Tanzania_Research/2018 Data Collection/Baseline Survey/Data/EDI FOLDER STRUCTURE - Week 1-2-3-4/Primary/data/RISE_BL_P_HEAD_LISTING/raw/grades.dta"
global teacher_grades "$user/RISE Tanzania_Research/2018 Data Collection/Baseline Survey/Data/EDI FOLDER STRUCTURE - Week 1-2-3-4/Primary/data/RISE_BL_P_Teacher/raw/R10TGrade.dta"

use "$ht_grades", clear

putexcel set "$grades_excel", sheet(Tables, replace) modify


ren teacherID TeacherMemberID
ren grdeyn grdeyn_ht
ren gradesID R10TGradeID
drop Check_grdeyn Check_subject subject

*grade distribution from listing before merge*
recode grdeyn_ht (2=0)
label define yn 0 "NO" 1 "YES"
label values grdeyn_ht yn
bysort SchoolID TeacherMemberID: egen grade_count_ht = total(grdeyn_ht)
label variable grade_count_ht "HT reports no. of grades per teacher (all teachers)"
preserve
duplicates drop SchoolID TeacherMemberID, force
tab grade_count_ht
tab2xl grade_count_ht using $grades_excel, col(8) row(5) missing
restore


*Merging listing and teacher*
merge m:m SchoolID TeacherMemberID R10TGradeID using "$teacher_grades", keepusing(TeacherID grdeyn)
drop if _merge == 1
preserve
keep if _merge == 2
export excel using "teacher_htlisting_unmatched.xlsx", replace firstrow(variables)
restore
drop if _merge == 2
drop _merge
order RegionID DistrictID WardID SchoolID HTTeacherID TeacherMemberID TeacherID R10TGradeID grdeyn_ht grdeyn grade_count_ht

*
recode grdeyn (2=0)
label values grdeyn yn
ren grdeyn grdeyn_teacher
gen grade_diff_yn = 1 if grdeyn_ht != grdeyn_teacher, after(grdeyn_teacher)
replace grade_diff_yn = 0 if grdeyn_ht == grdeyn_teacher
replace grade_diff_yn = . if grdeyn_ht == . | grdeyn_teacher == .


bysort TeacherID: egen grade_count_teacher = total(grdeyn_teacher)

gen count_diff_yn = 1 if grade_count_ht != grade_count_teacher
replace count_diff_yn = 0 if grade_count_ht == grade_count_teacher
replace count_diff_yn = . if grdeyn_ht == . | grdeyn_teacher == .

* for the ones that don't match - grade-wise listing *
preserve
keep if count_diff_yn == 1
drop grade_count_ht grade_count_teacher count_diff_yn
putexcel set "$grades_excel", sheet(Grade-wise_unmatched, replace) modify
putexcel B2 = "HT-Teacher report different no. of grades taught per teacher: Grade-wise listing", font(calibri, 16, black) bold
export excel using "$grades_excel", sheet("Grade-wise_unmatched") sheetmodify firstrow(varlabels) cell(B6)
restore


* for the ones that match in number but not per grade - grade-wise listing *
preserve
keep if count_diff_yn == 0 & grade_diff_yn == 1
drop count_diff_yn
label variable grade_count_ht "HT reports no. of grades per teacher"
label variable grade_count_ht "Teacher reports no. of grades they teach"
putexcel set "$grades_excel", sheet(Grade-wise_differences_matched, replace) modify
putexcel B2 = "HT-Teacher report same no. of total grades but diff. specific grades: Grade-wise listing", font(calibri, 16, black) bold
export excel using "$grades_excel", sheet("Grade-wise_differences_matched") sheetmodify firstrow(varlabels) cell(B6)
restore

*grade distribution from listing after merge*
preserve
duplicates drop TeacherID, force
label variable grade_count_ht "HT reports no. of grades per teacher (interviewed only)"
tab grade_count_ht, missing
tab2xl grade_count_ht using $grades_excel, col(8) row(15) missing

*Tabulating discrepencies in count*
label variable count_diff_yn "HT and Teacher report different no. of grades taught (from HT listing)"
label values count_diff_yn yn
tab count_diff_yn, missing
tab2xl count_diff_yn using $grades_excel, col(8) row(30) missing

*(same table as 2 above)grade distribution from listing from teacher survey for comparison*
use "$teacher_grades", clear 
recode grdeyn (2=0)
bysort TeacherID: egen teacher_grade_count = total(grdeyn)
label variable teacher_grade_count "Teachers report no. of grades they teach"
duplicates drop TeacherID, force
tab teacher_grade_count, missing
tab2xl teacher_grade_count using $grades_excel, col(15) row(15) missing

