/*
********************************************************************************
********************************************************************************
Data-Driven Analysis of Timely Education Policy Topics
Understanding How School-Specific Supplemental Fundraising Organizations Exacerbate Inequitable Resource Distribution

Data cleaning
********************************************************************************
********************************************************************************
*/
**ADJUST THIS
global path "C:/Users/LRestrepo/Documents/Clair_Folder"/******

Input orgs data from NCCS
source: https://nccs-data.urban.org/data.php?ds=core
most recent data dictionary: https://nccs-data.urban.org/dd2.php?close=1&form=Core+2013+PC
data guide: https://nccs-data.urban.org/NCCS-data-guide.pdf
ntee codes: https://nccs.urban.org/publication/irs-activity-codes

manual checking to look at 990: https://projects.propublica.org/nonprofits/
*******/
cd "${path}/Data Input"

capture mkdir "${path}/Figures"
capture mkdir "${path}/Data Intermediate"

import delimited coreco.core2017pc.csv, clear


keep if state == "IL"

gen keep_ind = 0
//before dropping schools, some PTAs coded under those NTEEs
replace keep_ind = 1 if (name == "GENEVA MIDDLE SCHOOL NORTH PARENT TEACHER ORGANIZATION" | name == "FRIENDS OF RAY SCHOOL" | name == "GENEVA MIDDLE SCHOOL NORTH PARENT TEACHER ORGANIZATION" | name == "NAPERVILLE CENTRAL HIGH SCHOOL ATHLETIC BOOSTERS CLUB" | name == "CHAMPAIGN CENTRAL BAND BOOSTERS INC" | name == "MURPHYSBORO COMMUNITY SCHOOL DISTRICT 186 EDUCATIONAL FOUNDATIO" | name == "ILLINOIS CONGRESS OF PARENTS TEACHERS NORTHWOOD JR HIGH PTA" | name == "RIVERWOOD ELEMENTARY SCHOOL PTO" | name == "WEST NORTHFIELD SCHOOL DISTRICT NO 31 FOUNDATION" | name == "DUNDEE MIDDLE SCHOOL PARENTASSOCIATION INC" | name == "EDGEWOOD MIDDLE SCHOOL PARENTTEACHER ORGANIZATION" | name == "LEMONT HIGH SCHOOL EDUCATIONALFOUNDATION" | name == "EAST HIGH SCHOOL BOOSTER CLUB OF ROCKFORD" | name == "SCHAUMBURG HIGH SCHOOL VERY INTERSTED PARENTS CLUB" | name == "CRYSTAL LAKE SOUTH HIGH SCHOOL BOOSTERS" | name == "DISTRICT 214 EDUCATION FOUNDATION" | name == "LEYDEN HIGH SCHOOLS FOUNDATION" | name == "BUFFALO GROVE HIGH SCHOOL CHORAL GUILD BUFFALO GROVE HIGH SCHOOL" | name == "BOOSTERS CLUB OF THE HINSDALE TOWNSHIP HIGH SCHOOL" | name == "NAPERVILLE NORTH HIGH SCHOOL BOOSTERS CLUB" | name == "CARL SANDBURG HIGH SCHOOL PARENT FACUALTY STUDENT ASSOCIATION" | name == "JOLIET TOWNSHIP HIGH SCHOOLS FOUNDATION" | name == "JANE ADDAMS MIDDLE SCHOOL PTG")

//drop schools themselves, libraries, dedicated memorial scholarships
drop if nteefinal == "B25" //Secondary & High Schools
drop if nteefinal == "B20" //Elementary & Secondary Schools
drop if nteefinal == "B29" //Charter Schools
drop if nteefinal == "B21" //Preschools
drop if nteefinal == "B28" //Special Education
drop if nteefinal == "B41" //Two-Year Colleges
drop if nteefinal == "B42" //Undergraduate Colleges
drop if nteefinal == "B43" //Universities
drop if regexm(name, "UNIVERSITY")
drop if nteefinal == "B50" //Graduate & Professional Schools
drop if nteefinal == "B60" //Adult Education
drop if nteefinal == "B70" //Libraries
drop if nteefinal == "B83" //Student Sororities & Fraternities
drop if nteefinal == "B84" //Alumni Associations
drop if regexm(name, "LIBRAR") | regexm(sec_name, "LIBRAR") //library funds
drop if regexm(name, "SCHOLARSHIP") //scholarship funds
drop if regexm(name, "MEMORIAL") //memorial funds (often scholarship)
drop if nteefinal == "B40" //Higher Education
drop if regexm(name, "HIGHER ED") //only looking at k-12
drop if nteefinal == "B82" //Scholarships & Student Financial Aid


gen nameOriginal = name //save this off given some re-assignment based on more-specific second name

replace name = subinstr(name, "ILLINOIS CONGRESS OF PARENTS TEACHERS", "", 1)

//update to use second name if file under IL congress of PTAs (and use that as primary name)
replace name = sec_name if name == "ILLINOIS CONGRESS OF PARENTS TEACHERS" & nteefinal1 == "B"
replace name = sec_name if name == "ILLIONIS CONGRESS OF PARENTS TEACHERS" & nteefinal1 == "B"
replace name = sec_name if name == "ILLINOIS CONGRESS OF PARENTS AND TEACHERS" & nteefinal1 == "B"
replace name = sec_name if regexm(name, "ILLINOIS CONGRESS OF PARENTS") & !missing(sec_name)
replace name = sec_name if regexm(name, "ILLINIOS CONGRESS OF PARENTS") & !missing(sec_name)
replace name = sec_name if sec_name == "WHITNEY YOUNG BOYS BASKETBALL"
replace name = sec_name if sec_name == "HUNTLEY GRID IRON CLUB INC"
replace name = sec_name if sec_name == "NORMAL COMMUNITY WEST HS BOOSTER CL"
replace name = sec_name if sec_name == "BELLEVILLE EAST ATHLETIC BOOSTER CL"
replace name = sec_name if sec_name == "WASHINGTON COMM HS BAND BOOSTERS"
replace name = sec_name if sec_name == "SP BOOSTER CLUB INC"
replace name = sec_name if sec_name == "OHS BAND BOOSTERS INC"
replace name = sec_name if sec_name == "LANE TECH FOOTBALL BOOSTERS"
replace name = sec_name if sec_name == "PAYTON BOOSTER ASSOCIATION INC"
replace name = sec_name if sec_name == "IVC ATHLETIC BOOSTERS GHOST BOOSTER"
replace name = sec_name if sec_name == "BURLINGTON CENTRAL ATHLETIC BOOSTER"


//update ambiguous names (based on manual search)
replace name = "MARK SHERIDAN MATH SCIENCE" if name == "REACH FOR THE STARS NFP"
replace name = "SAINT JOSEPH OGDEN HIGH SCHOOL" if name == "SJO FAN CLUB"
replace name = "EVANSTON TOWNSHIP HIGH SCHOOL" if name == "E T H S BOOSTERS CLUB"
replace name = "MCLEAN COUNTY" if name == "BEYOND THE BOOKS EDUCATIONAL FOUNDATION"
replace name = "NEOGA HIGH SCHOOL" if name == "NEOGA BOOSTER CLUB"
replace name = "CARMI-WHITE COUNTY HIGH SCHOOL" if name == "BULLDOG BOOSTERS INC"
replace name = "HERRIN HIGH SCHOOL" if name == "ROBERT N BREWER EDUCATIONAL TR"
replace name = "EDAWARDSVILLE HIGH SCHOOL" if name == "EHS TRAP CLUB"
replace name = "SOUTH ELEMENTARY SCHOOL" if name == "SUPPORTERS OF SOUTH NFP"
replace name = "WHEATON NORTH HIGH SCHOOL" if name == "FALCON BOOSTER CLUB"
replace name = "WEST ELEMENTARY SCHOOL" if name == "WEST PARENT ORGANIZATION"
replace name = "MAINE SOUTH HIGH SCHOOL" if sec_name == "THE MSHS MUSIC BOOSTER ORGANIZATION"
replace name = "CHARLSTON CUSD 1" if name == "THE TROJAN BOOSTER CLUB"
replace name = "MORRIS ELEMENTARY SCHOOL DISTRICT" if name == "BRAVES BOOSTER CLUB" & nteefinal == "B12"
replace name = "QUINCY PUBLIC SCHOOL DISTRICT" if name == "SHOP FOR SCHOOLS NFP"
replace name = "WEST CHICAGO COMMUNITY HIGH SCHOOL" if name == "WILDCAT BOOSTER CLUB"
replace name = "HUNTLY HIGH SCHOOL" if name == "FABULOUS INC"
replace name = "PRINCETON HIGH SCHOOL" if name == "EUNICE ZEARING TR FBO BOARD OF EDUCATION PRINCETON HIGH SCHOOL"
replace name = "MENDON COMMUNITY UNIT SCHOOL DISTRICT 4" if name == "FRIENDS OF UNIT 4"
replace name = "WAUCONDA HIGH SCHOOL" if name == "WAUCONDA BOOSTERS INC"
replace name = "EAST RICHLAND COMMUNITY SCHOOL DISTRICT" if name == "EAST RICHLAND FOUNDATION FOR ACADEMIC EXCELLENCE INC"
replace name = "ALEXANDER HAMILTON ELEMENTARY SCHOOL" if name == "HAMILTON ACTION TEAM"
replace name = "WALTER PAYTON COLLEGE PREP" if name == "PAYTON INIATIVE FOR EDUCATION"
replace name = "LA SALLE-PERU TWP HIGH SCHOOL" if name == "LASALLE-PERU TOWNSHIP HIGH SCHOOL FOUNDATION FOR ED ENRICHMENT"
replace name = "BELVIDERE NORTH HIGH SCHOOL" if name == "BLUE THUNDER BOOSTERS INC"
replace name = "BARRINGTON HIGH SCHOOL" if name == "BHS QUARTERBACK CLUB INC"

//a few additional updates for orgs that file under broader umbrella
replace name = sec_name if name == "DISTRICT 57 EDUCATION FOUNDATION" & nteefinal1 == "B"
replace name = sec_name if regexm(name, "DISTRICT 90") & nteefinal1 == "B"
replace name = "Comm H S Dist 99 - North H S" if name == "TROJAN BOOSTERS CLUB"
replace name = sec_name if name == "SAINT CHARLES BOOSTER CLUB"
replace name = sec_name if sec_name == "LE GYMNASTICS BOOSTERS INC"

replace name = subinstr(name, "ILLINOIS", "", 1) if name == "GRACE MCWAYNE PARENT TEACHER ORGANIZATION OF BATAVIA ILLINOIS"

//manual review of names, removing those that do not fit
keep if !regexm(name, "PARK DISTRICT")
keep if !regexm(name, "ROTARY DISTRICT")
keep if !regexm(name, "FIRE PROTECTION")
keep if !regexm(name, "FOREST PRESERVE")
keep if !regexm(name, "BASEBALL LEAGUE")
keep if !regexm(name, "DISTRICT GOLF")
keep if name != "RIVER DISTRICT"
keep if !regexm(name, "HISTORIC")
keep if !regexm(name, "ARTS DISTRICT")
keep if !regexm(name, "HOSPITAL")
keep if !regexm(name, "SOIL AND WATER")
keep if !regexm(name, "FIRECHIEFS")
keep if !regexm(name, "LABORERS DISTRICT")
keep if !regexm(name, "EMERGENCY MEDICAL")
keep if name != "STRIVE"
keep if !regexm(name, "TUTORING")
keep if !regexm(name, "QALAM") //supporting a school in pakistan
keep if !regexm(name, "PROM")
keep if !regexm(name, "GOLDEN GLOVES")
keep if !regexm(name, "LOVING ARMS")
keep if !regexm(name, "ENHANCE")
keep if name != "FRIENDS OF MADISON COUNTY CHILD ADVOCACY CENTER-NFP"
keep if name != "MINISTRY & EDUCATION FOUNDATION"
keep if !regexm(name, "COLLEGE FOUNDATION")
keep if !regexm(name, "AMERICAN FRIENDS")
keep if !regexm(name, "ALUMNI")
keep if name != "FRIENDS OF MCKENNA TECHNICAL INSTITUTE NFP"
keep if name != "FRIENDS OF COUNTRYSIDE INC"
keep if name != "FRIENDS OF ASHISH"
keep if name != "PARENTS FAMILIES AND FRIENDS OF LESBIANS AND GAYS INC"
keep if name != "FRIENDS OF THE ARLINGTON HEIGHTS" //library
keep if name != "INTERNATIONAL INSTITUTE OFQUALITATIVE INQUIRY"
keep if name != "CABAA EDUCATIONAL FOUNDATION"
keep if name != "FAY SAWYIER FOUNDATION"
keep if name != "JOHN MARSHALL LAW SCHOOL FOUNDATIONINC"
keep if name != "COLLEGE OF DUPAGE FOUNDATION"
keep if name != "BRIGHT FUTURES FOUNDATION"
keep if name != "ST MARY SCHOOL FOUNDATION"
keep if name != "EXTOLLO EDUCATIONAL FOUNDATION"
keep if name != "CHINESE CHRISTIAN EDUCATION FOUNDATION"
keep if name != "MA-AUA EDUCATION FUND INC"
keep if name != "RALPH ERICKSON EDUCATIONAL FOUNDATION" // scuba diving
keep if name != "MITCHELL A MARS FOUNDATION" // scholarship
keep if name != "FREQUENT TRAVELER EDUCATION FOUNDATION"
keep if name != "ALLIANCE FOR CHARACTER IN EDUCATION TUITION ENDOWMENT FUND NFP" // tuition
keep if name != "NOBLE NETWORK EDUCATION FOUNDATION"
keep if name != "DIABETES SCHOLARS FOUNDATION"
keep if name != "ROSALIND OPPENHEIM FOUNDATION"
keep if name != "INCLUSIVE COLLECTIVE"
keep if name != "NEIGHBORHOOD PARENTS NETWORK OF CHICAGO"
keep if name != "THE HOLOCAUST EDUCATION FOUNDATION"
keep if name != "ROCK ISLAND COUNTY EXTENSION AND 4-H EDUCATION FOUNDATION"
keep if name != "RSES EDUCATIONAL FOUNDATION"
keep if name != "FARM AND LAND FOUNDATION"
keep if name != "ARCH DEVELOPMENT CORPORATION"
keep if name != "PETS WITHOUT PARENTS"
keep if name != "SAINT JOHN OF THE CROSS TEACHER RECOGNITION TRUST"
keep if name != "ARABIC SCHOOL OF CHICAGO"
keep if name != "CHRIST THE KING SCHOOL FOUNDATION"
keep if name != "FRYDERYK CHOPIN POLISH SCHOOL IN PALATINE"
keep if name != "MORTGAGE EDUCATION FOUNDATION INC"
keep if name != "TAXPAYER EDUCATION FOUNDATION"
keep if name != "H C HARRIS HEALTH AND EDUCATIONAL FOUNDATION" // scholarships
keep if name != "LOYOLA ACADEMY GIRLS LACROSSE"
keep if name != "LIFES PLAN INC"
keep if name != "ILLINOIS BAR FOUNDATION"
keep if name != "ILLINOIS FOOD RETAILERS EDUCATION FOUNDATION"
keep if name != "ILLINOIS FOOT HEALTH EDUCATION FOUNDATION"
keep if name != "ILLINOIS ALLSTARS PARENT ASSOCIATION"
keep if name != "ILLINOIS ORDER OF DEMOLAY FOUNDATION INC"
keep if name != "HILLELS OF ILLINOIS ENDOWMENT FOUNDATION"
keep if name != "ILLINOIS ELEMENTARY SCHOOL ASSOCIATION INCORPORATED"
keep if name != "ILLINOIS FOOD RETAILERS EDUCATION FOUNDATION"
keep if name != " STEP BY STEP EARLY CHILDHOOD PTA"
keep if name != "ILLINOIS MATHEMATICS ASSOC OF COMM COLLEGES"
keep if name != "ILLINOIS GYMNASTICS INSTITUTE PARENTS BOOSTER CLUB"
keep if name != "ILLINOIS GRADE SCHOOL MUSIC ASSOCIATION"
keep if name != "SOUTHERN ILLINOIS RESEARCH PARK CORPORATION"
keep if name != "CONGREGATION ETZ CHAIM OF DUPAGE COUNTY FOUNDATION NFP"
keep if name != "JERSEYVILLE CATHOLIC EDUCATION CHAR TR"
keep if name != "PANTHER PRIDE FOUNDATION FOR CENTRAL SCHOOLS" //scholarships
keep if name != "ENGINE REBUILDERS EDUCATIONAL FOUNDATION"
keep if name != "CHANA SCHOOL FOUNDATION" //museum
keep if name != "SPECIAL KIDS NETWORK INC"
keep if name != "GLOBAL EDUCATION FUND INC"
keep if name != "POLISH ROMAN CATHOLIC UNION OF AMERICA EDUCATION FUND"
keep if name != "SHAKING THE TREE NFP"
keep if name != "FEDA EDUCATION FOUNDATION"
keep if name != "BARAT EDUCATION FOUNDATION"
keep if name != "ARIE CROWN HEBREW DAY SCHOOL ENDOWMENT FOUNDATION"
keep if name != "HILLEL TORAH NORTH SUBURBAN DAY SCHOOL ENDOWMENT FOUNDATION"
keep if name != "SOLOMON SCHECHTER DAY SCHOOLS ENDOWMENT FOUNDATION"
keep if name != "PCI FOUNDATION"
keep if name != "ST CLAIR COUNTY EXTENSION AND 4-H EDUCATION FOUNDATION"
keep if name != "LAMBDA STATE FOUNDATION FOR EDUCATIONAL STUDIES INC"
keep if name != "TAZEWELL COUNTY EXTENSION EDUCATION FOUNDATION"
keep if name != "WABASH AND OHIO VALLEY SPECIAL EDUCATION FOUNDATION"
keep if !regexm(name, "EXTENSION EDUCATION")
keep if !regexm(name, "4-H")
keep if !regexm(name, "4 H")
keep if name != "HERRIN EDUCATION FOUNDATION" //scholarship
keep if name != "CHILDREN OF POKAT EDUCATIONAL FUND INC"
keep if name != "HOPE SCHOOL FOUNDATION" //clinical
keep if name != "NICARAGUA CHRISTIAN EDUCATION FOUNDATION"
keep if name != "PARENTS FOR GYMNASTICS NFP"
keep if name != "JOHN R AND ELEANOR R MITCHELL FOUNDATION"
keep if !regexm(name, " TRUST") //take out trusts
keep if name != "THE CENTER FOR COMPUTER ASSISTED LEGAL INSTRUCTION"
keep if name != "AMERICAN ACADEMY OF SLEEP MEDICINE FOUNDATION"
keep if name != "ONE MILLION DEGREES"
keep if name != "MEDICATION-INDUCED SUICIDE EDUCATION FOUNDATION IN MEMORY OF"
keep if name != "RESCUECALIFORNIA EDUCATION FOUNDATION"
keep if name != "THE PEOPLES LOBBY EDUCATION INSTITUTE"
keep if name != "KCSO FAMILY AND FRIENDS NFP"
keep if name != "NALANDA EDUCATIONAL AND CHARITABLE FOUNDATION"
keep if name != "COPA SAFETY & EDUCATION FOUNDATION"
keep if name != "MULEBACKERS INC"
keep if name != "CONCENTRIC OUTREACH INC"
keep if name != "FOUNDATION FOR INFORMATION TECHNOLOGY EDUCATION"
keep if name != "AFCEA EDUCATIONAL FOUNDATION"
keep if name != "INTERNATIONAL FOUNDATION FOR RETIREMENT EDUCATION"
keep if name != "SMART WOMEN SMART MONEY EDUCATIONAL FOUNDATION"
keep if name != "PATRIOT EDUCATION FUND" //scholarships
keep if name != "B O S H INC"
keep if name != "NIU HUSKIES HOCKEY PARENT BOOSTER CLUB"
keep if name != "SIU DENTAL ASSOCIATES"
keep if name != "IALD EDUCATIONAL TRUST FUND INC" //scholarship
keep if name != "CHARLIE TROTTERS CULINARY EDUCATION FOUNDATION"
keep if name != "PFLAG CHICAGO METRO"
keep if name != "MULLANE HEALY OBRIEN BOOSTER CLUB"
keep if name != "AWARDS AND RECOGNITION INDUSTRY EDUCATIONAL FOUNDATION"
keep if name != "LOQUATE"
keep if name != "KIDS FIRST CHICAGO FOR EDUCATION"
keep if name != "BIR EDUCATION FOUNDATION" //scholarship
keep if name != "ARENA BOOSTER CLUB"
keep if name != "FOUNDATION FOR DENTAL HEALTH EDUCATION"
keep if name != "MUSIC EDUCATION ADVOCATES COALITION"
keep if name != "JAC EDUCATION FOUNDATION"
keep if name != "FORCE FOUNDATION"
keep if name != "NASA WILDCAT BOOSTER CLUB INC"
keep if name != "MARY MCKEE EDUCATIONAL FUND INC" //scholarships
keep if name != "AIM HIGH YOUTH POTENTIAL BOOSTER CLUB"
keep if name != "MULTICULTURAL EDUCATIONAL FOUNDATION"
keep if name != "POSITIVE PARENTING DUPAGE COURTNEY SIMEK"
keep if name != "CURE NETWORK"
keep if name != "MIDWAY EDUCATIONAL FOUNDATION"
keep if name != "ROUND LAKE BEACH CIVIC FOUNDATION"
keep if name != "IIT STATE STREET CORPORATION NFP"
keep if sec_name != "I POWER GYMNASTICS BOOSTER CLUB"
keep if name != "PASSAGES EDUCATIONAL FUND" //SCHOLARSHIPS
keep if name != "MICHAEL S DE LARCO FOUNDATION"
keep if name != "THE VIVIAN G HARSH SOCIETY INC"
keep if name != "AUSTIN JAYCEES EDUCATIONAL ENDOWMENT FUND"
keep if name != "CHICAGO LAW AND EDUCATION FOUNDATION"
keep if name != "OAKTON COMMUNITY COLLEGE EDUCATIONAL FOUNDATION"
keep if name != "MU MU LAMBDA EDUCATIONAL FOUNDATION"
keep if name != "HILLEL THE FOUNDATION FOR JEWISH CAMPUS LIFE"
keep if name != "CHICAGO STATE FOUNDATION"
keep if name != "DEPAUL COLLEGE PREP FOUNDATION"
keep if name != "NATIONAL ORGANIZATION FOR MARRIAGE EDUCATION FUND"
keep if name != "SCHOOLS COUNT CORPORATION NFP"
keep if name != "CRAWFORD COUNTY SPAY AND NEUTER FOUNDATION INCORPORATED"
keep if name != "COOK COUNTY JUVENILE TEMPORARY DENTENTION CENTER FOUNDATION"
keep if name != "WINGED FOOT FOUNDATION"
keep if name != "ROCK ISLAND COUNTY RETIRED TEACHERS FOUNDATION"
keep if name != "SUPPLIES FOR DREAMS INC"
keep if name != "CITY COLLEGES OF CHICAGO FOUNDATION"
keep if name != "ISSA FOUNDATION"
keep if name != "ONE-FIVE FOUNDATION"
keep if name != "ARIEL EDUCATION INTIATIVE"
keep if name != "ST MARGARETS COLLEGE & SCHOOLS FOUNDATION"
keep if name != "NOTRE DAME SCHOOL TEACHERS FUND INC"
keep if name != "STATE BANK FOUNDATION"
keep if name != "BIG TEN ACADEMIC ALLIANCE"
keep if name != "CHAMBER FOUNDATION OF EFFINGHAM COUNTY"
keep if name != "MET-INDIA NA INC"
keep if name != "VISIT CHAMPAIGN COUNTY FOUNDATION"
keep if name != "EDUCATE BWINDI"
keep if name != "GEM-IFK VENTURE FOR EDUCATIONAL SUPPORT INC"
keep if name != "BOOKS2CHINA"
keep if name != "LOCKPORT FIRE FOUNDATION INC"
keep if name != "IN SEARCH OF GENIUS FOUNDATION"
keep if name != "MORTHLAND FOUNDATION"
keep if name != "MISSION 292"
keep if name != "CRISTO REY NETWORK"
keep if name != "BANSAN FOUNDATION"
keep if name != "KEMMERER VILLAGE FOUNDATION INC"
keep if name != "HOLY FAMILY MINISTRIES"
keep if name != "AUSTIN COMING TOGETHER"
keep if name != "FRIENDS OF THE MONTESSORI ACADEMY OF CHICAGO INC"
keep if sec_name != "SCARIANO KULA ELLCH & HIMES CHTRD"
keep if name != "PYTHAGORAS CHILDRENS ACADEMY ENDOWMENT FUND"
keep if name != "FRIENDS OF RICKOVER NAVAL ACADEMY"
keep if name != "ELIM CHRISTIAN SCHOOL FOUNDATION"
keep if !regexm(name, "CHRISTIAN SCHOOL")
keep if name != "BLOOMINGTON CENTRAL CATHOLIC HIGH SCHOOL FOUNDATION"
keep if name != "ROCHELLE ZELL JEWISH HIGH SCHOOL ENDOWMENT FUND"
keep if name != "BIG SHOULDERS FUND"
keep if name != "FOUNDATIN FOR THE EDUCATIONAL DEVELOPMENT OF CHILDREN"
keep if name != "ACCELERATE INSTITUTE"
keep if name != "FRIENDS OF MORTON FOUNDATION" //community college
keep if name != "FENWICK FOUNDATION INC" //private
keep if name != "BYRON FOUNDATION FOR EDUCATIONAL EXCELLENCE" // scholarship
keep if name != "GRUNDY COUNTY FRIENDS"
keep if name != "WEST 40 EDUCATION NFP" //alt placement
keep if name != "SACRED HEART DU QUOIN EDUCATION FOUNDATION" //catholic
keep if name != "COLLEGE OF LAKE COUNTY FOUNDATION"
keep if name != "PATHFINDERS EDUCATION FOUNDATION INCORPORATED"
keep if name != "FOUNDRY EDUCATIONAL FOUNDATION"
keep if name != "HYMEN MILGROM SUPPORTING ORGANIZATION"
keep if name != "CLARK AND HINMAN FOUNDATION"
keep if name != "WAUKEGAN FEEDER PROGRAM" //bball feeder program
keep if name != "MIDWEST EDUCATIONAL FOUNDATION FOR CHRISTIAN SCIENTISTS"
keep if name != "JEWISH VOCATIONAL SERVICE ENDOWMENT FOUNDATION"
keep if name != "PAUL W CAINE FOUNDATION"
keep if name != "LITERATURE FOR ALL OF US"
keep if name != "FRIENDS OF PEORIA REGIONAL LEARNING CENTER" // alt school
keep if name != "P A T H S PARENTS AND TEACHERS OF HANDICAPPED STUDENTS"
keep if name != "PARENT TEACHER ORGANIZATION FOR EXCEPTIONAL CHILDREN"
keep if name != "WORTH TOWNSHIP HIGH SCHOOL HOCKEY ASSOCIATION" // multiple teams across towns, not school-specific
keep if name != "ROCHELLE ZELL JEWISH HIGH SCHOOL"
keep if name != "THE BATAVIA MOTHERS CLUB FOUNDATION"
keep if name != "PATRICK FOUNDATION INC"
keep if name != "ROUTT HIGH SCHOOL EDUCATION FOUNDATION INC" // catholic
keep if name != "CHRIST OUR ROCK LUTHERAN HIGH SCHOOL" // religious
keep if name != "WHEATON ACADEMY FOUNDATION" //private
keep if name != "ROCKFORD COMPUTERS FOR SCHOOLS NFP"
keep if name != "BREHM PREPARATORY SCHOOL FOUNDATION" //special ed
keep if name != "LOCKPORT LEMONT SPARTANS HIGH SCHOOL HOCKEY CLUB" //multi-town hockey only
keep if name != "GRANT JR BULLDOGS BOOSTER CLUB"
keep if name != "SEVERSON DELLS EDUCATIONAL FOUNDATION" //environment group
keep if name != "FLEISCHER FOUNDATION NFP"
keep if name != "HAMPSHIRE YOUTH FOOTBALL AND CHEERLEADING ASSOCIATION" // youth sports only
keep if name != "IMSA PARENT ASSOCIATION COUNCIL" // tuition
keep if name != "CLS EAGLE PARENT ORGANIZATION" //christian
keep if name != "STEP BY STEP EARLY CHILDHOOD PTA"
keep if name != "FRANCHELL BOSWELL EDUCATIONAL FOUNDATION INC" // scholarships
keep if name != "IMMANUEL LUTHERN SCHOOL EDUCATION FOUNDATION"
keep if name != "BERNARD ZELL ANSHE EMET DAY SCHOOL ENDOWMENT FUND"
keep if name != "MARQUETTE BOOSTER CLUB INC" // catholic
keep if name != "ST TERESA EDUCATIONAL FOUNDATION"
keep if name != "ST MARY SCHOOL OF MT VERNON EDUCATION FOUNDATION" 
keep if name != "NABOR HOUSE EDUCATIONAL FOUNDATION" //scholarships
keep if name != "MISSISSIPPI VALLEY HIGH SCHOOL CLUB ICE HOCKEY ASSOCIATION" // regional ice hockey
keep if name != "FRIENDS OF SAINT THOMAS OF VILLANOVA SCHOOL"
keep if name != "BROTHER RICE HIGH SCHOOL FOUNDATION INC"
keep if name != "ELMHURST PRINCESSES"
keep if name != "FRIENDS OF ELIESTOUN NFP"
keep if name != "WHEATON ACADEMY INSTITUTE"
keep if name != "LE GYMNASTICS BOOSTERS INC"
keep if name != "CHESTERBROOK ACADEMY PARENT ASSOCIATION"
keep if name != "LISLE LIONS CLUB EDUCATIONAL FOUNDATION" //scholarships
keep if name != "JOSEPH ACADEMY FOUNDATION INC"
keep if name != "PARENTS ASSOCIATION GEN K PULASKI SCHOOL" //catholic
keep if name != "FOUNDATIONS COLLEGE PREPARATORY SCHOOL"
keep if name != "TELPOCHCALLI COMMUNITY EDUCATION PROJECT INC" // community group
keep if name != "BARNETT FBO IN ACADEMY FAMILY PHYSICIAN 2800291200"
keep if name != "MARIST H S CHICAGO FOUNDATION" // catholic
keep if name != "SAINT LAURENCE FOUNDATION INC" //tuition
keep if name != "CHICAGO RETIRED TEACHERS AID FUND INC"
keep if name != "LINCOLN LAND HIGH SCHOOL HOCKEY" //multiple schools hockey
keep if name != "BONNIE MCBETH LEARNING CENTER PTO" //ECE
keep if name != "QUINCY NOTRE DAME FOUNDATION" //catholic

//assign keep or not indicator
replace keep_ind = 1 if regexm(name, "DISTRICT") //now, all w/ dist in name are school districts
replace keep_ind = 1 if regexm(name, "FRIENDS OF") & regexm(name, "SCHOOL") & keep_ind == 0
replace keep_ind = 1 if nteefinal == "B94" | nteeirs == "B94"
replace keep_ind = 1 if ein == 900649985 | ein == 363531918 | ein == 260303523 | ein == 363591335 //PTOs filed under B24
replace keep_ind = 0 if nteefinal == "B24" & keep_ind != 1 //Primary & Elementary Schools
replace keep_ind = 1 if nteefinal == "B11" //previously removed MANY extraneous
replace keep_ind = 1 if nteefinal == "B12" // PREVIOUSly remove extraneous
replace keep_ind = 1 if nteefinal == "B1224"
replace keep_ind = 1 if nteefinal == "B1120"
replace keep_ind = 1 if nteefinal == "B112"
replace keep_ind = 1 if nteefinal == "B1124"
replace keep_ind = 1 if name == "FRIENDS OF PULASKI"
replace keep_ind = 1 if name == "FRIENDS AND FAMILY OF SOUTH LOOP SCHOOL INC" //all other B90 bad
replace keep_ind = 1 if name == "LAKE FOREST ASSOCIATION OF PARENTS AND TEACHERS"
replace keep_ind = 1 if nteefinal == "B1125"
replace keep_ind = 1 if nteefinal == "B1130"
replace keep_ind = 1 if name == "HARLEM HIGH SCHOOL FANS CLUB INC"
replace keep_ind = 1 if nteefinal == "B1190"
replace keep_ind = 1 if name == "MARGARET MEAD JR HIGH SCHOOL PTA"
replace keep_ind = 1 if name == "HOFFMAN ESTATES LOYAL PARTNERS"
replace keep_ind = 1 if nteefinal == "B1220"
replace keep_ind = 1 if nteefinal == "B1225"
replace keep_ind = 1 if name == "TAYLORVILLE PUBLIC SCHOOLS FOUNDATION INC"
replace keep_ind = 1 if name == "CHICAGO FOUNDATION FOR EDUCATION"
replace keep_ind = 1 if name == "MONMOUTH-ROSEVILLE EDUCATION FOUNDATION"
replace keep_ind = 1 if name == "DECATUR PUBLIC SCHOOLS FOUNDATION"
replace keep_ind = 1 if name == "LINCOLN-WAY HIGH SCHOOL FOUNDATION FOR EDUCATIONAL EXCELLENCE INC"
replace keep_ind = 1 if name == "MENDON COMMUNITY UNIT SCHOOL DISTRICT 4"
replace keep_ind = 1 if name == "FENWICK HIGH SCHOOL"
replace keep_ind = 1 if name == "NEUQUA VALLEY HIGH SCHOOL LACROSSE CLUB"
replace keep_ind = 1 if name == "WAUBONSIE VALLEY HIGH SCHOOL LACROSSE CLUB"
replace keep_ind = 1 if name == "HIGHLAND PARK HIGH SCHOOL GIANTS CLUB"
replace keep_ind = 1 if name == "CHICAGO PUBLIC SCHOOLS STUDENT SCIENCE FAIR INC"
replace keep_ind = 1 if name == "HARVARD BOOSTER CLUB"
replace keep_ind = 1 if name == "BOOKS AND BREAKFAST"
replace keep_ind = 1 if name == "CLINTON COMMUNITY EDUCATIONALFOUNDATION"
replace keep_ind = 1 if name == "JOHNSBURG EDUCATIONAL PARTNERSHIP FOUNDATION INC"
replace keep_ind = 1 if name == "TELPOCHCALLI COMMUNITY EDUCATION PROJECT INC"
replace keep_ind = 1 if name == "WAUCONDA HIGH SCHOOL"
replace keep_ind = 1 if name == "HINSDALE CENTRAL FOUNDATION"
replace keep_ind = 1 if name == "LEXINGTON EDUCATION ADVANCEMENT FOUNDATION"
replace keep_ind = 1 if name == "EAST RICHLAND COMMUNITY SCHOOL DISTRICT"
replace keep_ind = 1 if name == "PAYTON BOOSTER ASSOCIATION INC"
replace keep_ind = 1 if name == "PRAIRIE HILL SCHOOL PARENT STAFF ASSOCIATION"
replace keep_ind = 1 if name == "PAYTON BOOSTER ASSOCIATION INC"
replace keep_ind = 1 if name == "IVC ATHLETIC BOOSTERS GHOST BOOSTER"
replace keep_ind = 1 if name == "BURLINGTON CENTRAL ATHLETIC BOOSTER"
replace keep_ind = 1 if name == "GLENBROOK SOUTH HIGH SCHOOL DEBATE PARENT LEAGUE"
replace keep_ind = 1 if name == "THE QUINCY PUBLIC SCHOOLS FRIENDS OF THE PERFORMING ARTS"
replace keep_ind = 1 if name == "BOLINGBROOK HIGH SCHOOL THEATRE BOOSTERS"
replace keep_ind = 1 if name == "ROLLING MEADOWS HIGH SCHOOL MUSIC BOOSTERS"
replace keep_ind = 1 if name == "MOLINE PUBLIC SCHOOLS FOUNDATION INC"
replace keep_ind = 1 if name == "PRAIRIE HILL SCHOOL PARENT STAFF ASSOCIATION"
replace keep_ind = 1 if name == "HINSDALE CENTRAL HIGH SCHOOL BOYS LACROSSE BOOSTER CLUB INC"
replace keep_ind = 1 if name == "LAKE ZURICH HIGH SCHOOL LACROSSE BOOSTER CLUB NFP"
replace keep_ind = 1 if name == "GLENBROOK SOUTH HIGH SCHOOL DEBATE PARENT LEAGUE"
replace keep_ind = 1 if name == "CENTENNIAL HIGH SCHOOL BASEBALL BOOSTER CLUB"
replace keep_ind = 1 if name == "BARRINGTON HIGH SCHOOL BRONCO SOCCER BOOSTERS"
replace keep_ind = 1 if nteefinal == "N68" & regexm(name, "SCHOOL")
replace keep_ind = 1 if name == "THE JACKSONVILLE PUBLIC SCHOOLS FOUNDATION"
replace keep_ind = 1 if name == "NEW TRIER PARENTS ASSOCIATION NEW TRIER TOWNSHIP HIGH SCHOOL"
replace keep_ind = 1 if name == "HIGHLAND SCHOOL DISTRICT FDN"
replace keep_ind = 1 if name == "JOSEPH SEARS FOUNDATION-A KENIWORTH SCHOOL DIST NO 38 SUPPORTING ORG"
replace keep_ind = 0 if ein == 370705449 //state-wide PTA congress
replace name = sec_name if name == "" & !missing(sec_name)
replace keep_ind = 1 if missing(keep_ind)

keep if keep_ind == 1	

cd "${path}/Data Intermediate"

save IL_Orgstomerge, replace

/*
assign district versus school org datasets for merging
*/
use IL_Orgstomerge, clear

//assign district-serving ind
gen org_servesDist = .
replace org_servesDist = 1 if regexm(name, "DISTRICT")
replace org_servesDist = 1 if regexm(name, "SCHOOLS")
replace org_servesDist = 1 if nteefinal == "A68" | nteefinal == "B01"
replace org_servesDist = 1 if name == "LAKE FOREST ASSOCIATION OF PARENTS AND TEACHERS"
replace org_servesDist = 0 if name == "PAYTON BOOSTER ASSOCIATION INC"
replace org_servesDist = 0 if name == "WASCO PARENT & TEACHER ORGANIZATION"
replace org_servesDist = 0 if regexm(name, "SCHOOL") & !missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B03" & missing(org_servesDist)
replace org_servesDist = 0 if regexm(name, "HIGH SCHOOL")
replace org_servesDist = 0 if regexm(name, "ELEMENTARY SCHOOL")
replace org_servesDist = 1 if regexm(name, "SCHOOL DIST")
replace org_servesDist = 0 if nteefinal == "B11" & missing(org_servesDist)
replace org_servesDist = 1 if name == "DUPAGE EDUCATION FOUNDATION" | name == "SPRING VALLEY FOUNDATION FOR EDUCATIONAL ENRICHMENT" | name == "SCHUYLER COUNTY EDUCATION FOUNDATION" | name == "MCLEAN COUNTY" | name == "CARY 26 EDUCATION FOUNDATION" | name == "I V C BAND BOOSTERS" | name == "MCLEAN COUNTY" | name == "DUPAGE EDUCATION FOUNDATION" | name == "LAKE COUNTY REGIONAL OFFICE OF EDUCATION FOUNDATION INC" | name == "CHARLSTON CUSD 1"| name == "CHANEY-MONGE FOUNDATION INC" | name == "SYCAMORE EDUCATION FOUNDATION" | name == "CASS RESOURCES FOR ENRICHMENT" | name == "UNIT NO 1 EDUCATION FOUNDATION" | name == "U-46 EDUCATIONAL FOUNDATION" | name == "LIBERTY EDUCATION FOUNDATION" | name == "BALL-CHATHAM EDUCATIONAL FOUNDATION" | name == "GREATER ST CHARLES EDUCATION FDN" | name == "FRIENDS OF WHEATON NORTH PUBLIC SCHOOLS" | name == "HOMEWOOD FOUNDATION FOR EDUCATIONAL EXCELLENCE" | name == "GIBSON CITY-MELVIN-SIBLEY BOOSTER CLUB INC" | name == "SCHUYLER COUNTY EDUCATION FOUNDATION" | name == "ALLENDALE EDUCATIONAL FOUNDATION" | name == "CCSD 46 EDUCATION FOUNDATION NFP" | name == "WINFIELD EDUCATION FOUNDATION" | name == "LENA-WINSLOW EDUCATION FOUNDATION" | name == "MANNHEIM EDUCATIONAL FOUNDATION" | name == "ALTON EDUCATIONAL FOUNDATION" | name == "ROCK ISLAND-MILAN EDUCATION FOUNDATION" | name == "SPRING VALLEY FOUNDATION FOR EDUCATIONAL ENRICHMENT" | name == "CHICAGO EDUCATION TR FUND 121395" | name == "D200 MUSIC BOOSTER" | name == "CARY 26 EDUCATION FOUNDATION" | name == "IVC EDUCATIONAL FOUNDATION" | name == "" | name == "DEER CREEK MACKINAW EDUCATION FOUNDATION" | name == "SHELDON-MILFORD EDUCATION FOUNDATION" | name == "PALOS 118 EDUCATIONAL FOUNDATION" | name == "FAMILIAS EN LA ESCUELA NFP" | name == "STAUNTON EDUCATION FOUNDATION" | name == "NAPERVILLE EDUCATION FOUNDATION" | name == "PUTNAM COUNTY EDUCATIONAL FOUNDATION" | name == "GLENVIEW EDUCATION FOUNDATION" | name == "WESTERN SPRINGS FOUNDATION FOR EDUCATION EXCELLENCE" | name == "YORKVILLE CUSD 115 EDUCATIONAL FOUNDATION" | name == "MONTICELLO AREA EDUCATION FOUNDATION" | name == "GLENCOE EDUCATIONAL FOUNDATION" | name == "CETA EDUCATION FOUNDATION" | name == "DEKALB EDUCATION FOUNDATION" | name == "CHICAGO PUBLIC EDUCATION FUND" | name == "CHILDRENS FIRST FUND THE CHICAGO PUBLIC SCHOOL FOUNDATION" | name == "TREMONT EDUCATION FOUNDATION" | name == "BARRINGTON 220 EDUCATIONAL FOUNDATION" | name == "CHICAGO FOUNDATION FOR EDUCATION" | name == "CLINTON COMMUNITY EDUCATIONALFOUNDATION" | name == "BOOKS AND BREAKFAST" | name == "JOHNSBURG EDUCATIONAL PARTNERSHIP FOUNDATION INC" | name == "HARVARD BOOSTER CLUB" | name == "FRIENDS OF CUSD 5 NFP" | name == "WOODLAND COMMUNITY CONSOLID PTA" | name == "MURPHYSBORO COMMUNITY SCHOOL DISTRICT 186 EDUCATIONAL FOUNDATIO" | name == "IVC ATHLETIC BOOSTERS GHOST BOOSTER" | name == "LEYDEN HIGH SCHOOLS FOUNDATION" | name == "WEST NORTHFIELD SCHOOL DISTRICT NO 31 FOUNDATION" | name == " COAL VALLEY PTA" | name == "MERIDIAN ELEMENTARY PTO" | name == "COAL CITY PARENT SCHOOL ORGANIZATION"

replace org_servesDist = 0 if regexm(name, "FRIENDS OF") & !missing(org_servesDist)
replace org_servesDist = 1 if regexm(name, "COUNTY")
replace org_servesDist = 0 if nteefinal == "B112" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B1120" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B12" & missing(org_servesDist)
replace org_servesDist = 1 if nteefinal == "B1220" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B1124" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B1124" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B1125" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B1130" & missing(org_servesDist)
replace org_servesDist = 1 if nteefinal == "B1190" & missing(org_servesDist)
replace org_servesDist = 1 if nteefinal == "B1194" & missing(org_servesDist)
replace org_servesDist = 1 if nteefinal == "B1282" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B90" & missing(org_servesDist)
replace org_servesDist = 0 if nteefinal == "B94" & missing(org_servesDist)
replace org_servesDist = 0 if missing(org_servesDist)
replace org_servesDist = 1 if name == "LEMONT SD 113A PARENT TEACHER ORGANIZATION"
replace org_servesDist = 1 if name == "SPIRIT OF 67 FOUNDATION"
replace org_servesDist = 1 if name == "FRIENDS OF CUSD 5 NFP"
replace org_servesDist = 1 if name == "DECATUR PUBLIC SCHOOLS FOUNDATION"
replace org_servesDist = 1 if name == "THE QUINCY PUBLIC SCHOOLS FRIENDS OF THE PERFORMING ARTS"


//update names, addresses based on manual searches (so that more match on first link)
replace name = "PITTSFIELD HIGH SCHOOL" if name == "SAUKEE FOOTBALL PARENTS"
replace name = "MASCOUTAH HIGH SCHOOL" if name == "FOUNDATION FOR MASCOUTAH SCHOOLS INC"
replace name = "HINSDALE CENTRAL HIGH SCHOOL" if name == "HINSDALE CENTRAL FOUNDATION"
replace name = "Township High School District 211" if name == "D211 HIGH SCHOOL HOCKEY CLUB"
replace org_servesDist = 1 if name == "Township High School District 211"
replace name = "rolling meadows high school" if name == "PREP HIGH SCHOOL HOCKEY CLUB INC NFP"
replace name = "Stockton Sr High School" if name == "STOCKTON MUSIC BOOSTER CLUB"
replace city = "stockton" if name == "Stockton Sr High School"
replace zip = "61085" if name == "Stockton Sr High School"
replace address = "540 n rush st" if name == "Stockton Sr High School"
replace name = "O Fallon High School" if name == "OFALLON PANTHER BAND BOOSTERS INC"
replace name = "mt zion" if name == "MOUNT ZION FOUNDATION FOR QUALITY EDUCATION"
replace org_servesDist = 1 if name == "mt zion"
replace name = "new lenox district 122" if name == "NEW LENOX PARENT TEACHER ORGANIZATION"
replace org_servesDist = 1 if name == "new lenox district 122"
replace name = "Jacksonville School District 117" if name == "THE JACKSONVILLE PUBLIC SCHOOLS FOUNDATION"
replace org_servesDist = 1 if name == "Jacksonville School District 117"
replace name = "Warren Township High School" if name == "BLUE DEVIL BOOSTER CLUB"
replace name = "Salem Community High School" if name == "SCHS BOOSTER CLUB INC"
replace name = "Lake Park High School" if name == "LAKE PARK LANCER BOOSTER CLUB"
replace name = "Lemont Twp High School" if name == "LOCKPORT LEMONT SPARTANS HIGH SCHOOL HOCKEY CLUB"
replace name = "El Paso Gridley CUSD 11" if name == "EL PASO-GRIDLEY MUSIC BOOSTERS NFP"
replace org_servesDist = 1 if name == "El Paso Gridley CUSD 11"
replace name = "Palos Heights School District 128" if name == "PALOS POWER SOFTBALL"
replace name = "Ogden Elem School" if name == "FRIENDS OF OGDEN SCHOOL INC"
replace name = "Mascoutah High School" if name == "MASCOUTAH BAND BOOSTERS ASSOCIATION"
replace name = "park view elem school" if name == "PARK VIEW PARENT-TEACHER CLUB"
replace name = "Oswego Community Unit School District 308" if name == "OSWEGO FOUNDATION FOR EDUCATIONAL EXCELLENCE"
replace org_servesDist = 1 if name == "Oswego Community Unit School District 308"
replace name = "Glencoe School District 35" if name == "GLENCOE PTO"
replace org_servesDist = 1 if name == "Glencoe School District 35"
replace name = "El Paso-Gridley High School" if name == "TITAN ATHLETIC BOOSTER CLUB INC"
replace name = "Winnetka School District 36" if name == "WINNETKA PARENT TEACHER ORGANIZATION"
replace org_servesDist = 1 if name == "Winnetka School District 36"
replace org_servesDist = 1 if name == "FRIENDS OF COMMUNITY HIGH SCHOOL DISTRICT 218 EDUCATION FOUNDATION"
replace name = "Maine Township High School District 207" if name == "MAINE HIGH SCHOOL HOCKEY ASSOCIATION"
replace org_servesDist = 1 if name == "Maine Township High School District 207"
replace city = "glen ellyn" if name == "park view elem school" //search on site
replace zip = "60137" if name == "park view elem school" //search on site
replace address = "250 s park blvd" if name == "park view elem school"
replace city = "roselle" if name == "Lake Park High School"
replace zip = "60172" if name == "Lake Park High School"
replace address = "500 w bryn mawr ave" if name == "Lake Park High School"
replace name = "Lasalle Elementary School District 122" if name == "LASALLE PUBLIC SCHOOL EDUCATIONAL FOUNDATION"
replace org_servesDist = 1 if name == "Lasalle Elementary School District 122"
replace city = "hinsdale" if name == "HINSDALE CENTRAL HIGH SCHOOL"
replace zip = "60521" if name == "HINSDALE CENTRAL HIGH SCHOOL"
replace address = "5500 s grant st" if name == "HINSDALE CENTRAL HIGH SCHOOL"
replace name = "Winnetka School District 36" if name == "THE WINNETKA PUBLIC SCHOOLS FOUNDATION"
replace org_servesDist = 1 if name == "Winnetka School District 36"
replace name = "Evergreen Elementary School" if name == "BENJAMIN-EVERGREN PTA INC"
replace name = "Mount Pulaski High School" if name == "MT PULASKI TOPPERS BOOSTER CLUB INC"
replace name = "Triad Community Unit 2" if name == "TROY GRADE SCHOOL PARENT TEACHER ORGANIZATION"
replace org_servesDist = 1 if name == "Triad Community Unit 2"
replace org_servesDist = 1 if name == "OBLONG SCHOOL ACADEMIC FOUNDATION"
replace org_servesDist = 1 if name == "CHAMPAIGN-URBANA SCHOOLS FOUNDATION"
replace name = "Hamilton Schools District 328" if name == "CARDINAL FOUNDATION FOR HAMILTON SCHOOLS INC"
replace org_servesDist = 1 if name == "Hamilton Schools District 328"
replace name = "Charleston CUSD 1" if name == "JOINT PTA INC"
replace org_servesDist = 1 if name == "Charleston CUSD 1"
replace org_servesDist = 1 if name == "BELLEVILLE PUBLIC SCHOOLS DISTRICT 118 EDUCATIONAL FOUNDATION LTD"
replace name = "Delavan High School" if name == "EDWARD AND BEULAH SCHMIDT DELAVAN CHARITABLE EDUCATION TR"
replace city = "delavan" if name == "Delavan High School"
replace zip = "61734" if name == "Delavan High School"
replace address = "907 locust st" if name == "Delavan High School"
replace address = "" if name == "Delavan High School"
replace name = "Macomb Senior High School" if name == "MACOMB BAND BOOSTERS INC"
replace name = "Chicago International Charter" if name == "PUMA PARENT TEACHER ORGANIZATION NFP"
replace address = "11 e adams st ste600" if name == "Chicago International Charter"
replace zip = "60603" if name == "Chicago International Charter"
replace name = "Central High School" if name == "BURLINGTON CENTRAL ATHLETIC BOOSTER"
replace city = "mascoutah" if name == "Mascoutah High School"
replace zip = "62258" if name == "Mascoutah High School"
replace address = "1313 w main st" if name == "Mascoutah High School"
replace name = "Warren Township High School" if name == "WARREN DUGOUT CLUB"
replace name = "Bradley Elementary School District 61" if name == " BRADLEY PTA INC"
replace org_servesDist = 1 if name == "Bradley Elementary School District 61"
replace name = "Brentano Elem Math & Science Acad" if name == "FRIENDS OF@BRENTANO SCHOOL"
replace name = "Pana Community Unit School District 8" if name == "PANA EDUCATION FOUNDATION"
replace org_servesDist = 1 if name == "Pana Community Unit School District 8"
replace org_servesDist = 1 if name == "BUSHNELL-PRAIRIE CITY PUBLIC SCHOOLS FOUNDATION"
replace name = "Kanoon Elem Magnet School" if name == "SIDLEY AND AUSTIN FUND FOR KANOON MAGNET SCHOOL INC"
replace name = "Skinner Elem School" if name == "FRIENDS OF@SKINNER WEST"
replace name = "Sterling Morton High School District 201" if name == "MORTON 201 FOUNDATION"
replace org_servesDist = 1 if name == "Sterling Morton High School District 201"
replace name = "Elk Grove High School" if name == "GRENADIER BOOSTER CLUB INC"
replace name = "Glen Ellyn School District 41" if name == "PARTNERSHIP FOR EDUCATIONAL PROGRESS"
replace org_servesDist = 1 if name == "Glen Ellyn School District 41"
replace name = "Young Magnet High School" if name == "WHITNEY YOUNG BOYS BASKETBALL"
replace name = "Kildeer Countryside Community Csd 96" if name == "KILDEER COUNTRYSIDE CCSD 96 PTO COORDINATING COUNCIL"
replace org_servesDist = 1 if name == "Kildeer Countryside Community Csd 96"
replace name = "Springfield School District 186" if name == "THE SPRINGFIELD PUBLIC SCHOOLS FOUNDATION"
replace org_servesDist = 1 if name == "Springfield School District 186"
replace name = "Northwest Elem School" if name == "LASALLE ELEMENTARY SCHOOLS PTA"
replace name = "Homeswood School District 153" if name == "HOMEWOOD PTA"
replace org_servesDist = 1 if name == "Homeswood School District 153"
replace name = "Locust Elem School" if name == "CEPTA INC"
replace name = "Lemont-Bromberek School District 113A" if name == "WARRIOR BOOSTER CLUB INC"
replace org_servesDist = 1 if name == "Lemont-Bromberek School District 113A"
replace name = "Itasca School District 10" if name == "ITASCA PARENT TEACHER ORGANIZATION"
replace org_servesDist = 1 if name == "Itasca School District 10"
replace name = "Joliet Public School District 86" if name == "JOLIET GRADE SCHOOLS FOUNDATION FOR EDUCATIONAL EXCELLENCE"
replace org_servesDist = 1 if name == "Joliet Public School District 86"
replace org_servesDist = 1 if name == "CHICAGO PUBLIC SCHOOLS STUDENT SCIENCE FAIR INC"
replace org_servesDist = 1 if name == "GALESBURG PUBLIC SCHOOLS FOUNDATION"
replace org_servesDist = 1 if name == "EVANSTON SKOKIE COUNCIL OF PTAS"
replace org_servesDist = 1 if name == "PARENTS INVOLVED ALL STUDENTS ACHIEVE TEAM NFP"
replace address = "555 n main st" if name == "WAUCONDA HIGH SCHOOL FINE ARTS BOOSTERS INC"

sort nteefinal
order org_servesDist nteefinal name sec_name 

gen year = fisyr
gen zip_forlink = string(zip5)
gen city_forlink = lower(city)
gen street_forlink = lower(address)
replace street_forlink = regexr(street_forlink , "\(", "")
replace street_forlink = regexr(street_forlink , "\)", "")
replace street_forlink = regexr(street_forlink, "`","")
gen name_forlink = lower(name) + lower(sec_name)
replace name_forlink = regexr(name_forlink, "\((.)+\)", "")
replace name_forlink = regexr(name_forlink , "\(", "")
replace name_forlink = subinstr(name_forlink, "school", "", .)
replace name_forlink = subinstr(name_forlink, "friends of", "", .)
replace city_forlink = subinstr(city_forlink, "mt", "mount",.)

preserve
keep if org_servesDist == 0
save IL_SchoolOrgstomerge, replace
restore

preserve
keep if org_servesDist
replace name_forlink = subinstr(name_forlink, "district", "", .)
replace name_forlink = "City of Chicago School District 299" if name_forlink == "chicago public education fund"
save IL_DistrictOrgstomerge, replace
restore
