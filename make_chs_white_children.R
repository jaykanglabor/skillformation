# Create a teaching-friendly extract from the public-use CNLSY/79 Child/Young
# Adult file used by Cunha, Heckman, and Schennach (2010).
#
# The raw CSV is intentionally not copied into this repository.  This script
# reads only the selected columns and writes a small derived extract locally.

library(data.table)

raw_dir <- file.path("data", "raw", "nlscya_all_1979-2020")
raw_csv <- file.path(raw_dir, "nlscya_all_1979-2020.csv")
raw_sdf <- file.path(raw_dir, "nlscya_all_1979-2020.sdf")
out_dir <- file.path("data", "derived")

if (!file.exists(raw_csv)) {
  stop("The CNLSY/79 CSV was not found at: ", raw_csv)
}
if (!file.exists(raw_sdf)) {
  stop("The CNLSY/79 codebook was not found at: ", raw_sdf)
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# -------------------------------------------------------------------------
# 1. Read the codebook and locate variables by their labels.
# -------------------------------------------------------------------------
codebook_lines <- readLines(raw_sdf, encoding = "UTF-8")
is_variable <- grepl("^[A-Z][0-9]+\\.[0-9]+\\s", codebook_lines)
codebook <- data.table(line = codebook_lines[is_variable])
codebook[, code_dotted := sub("^\\s*(\\S+).*", "\\1", line)]
codebook[, code := gsub("\\.", "", code_dotted)]
codebook[, year := sub("^\\S+\\s+(\\S+).*", "\\1", line)]

find_code <- function(year, pattern, description) {
  target_year <- as.character(year)
  candidates <- codebook[
    year == target_year & grepl(pattern, line, ignore.case = TRUE),
    code
  ]

  if (length(candidates) == 0L) {
    stop("Could not find ", description, " for ", year,
         ". Search pattern was: ", pattern)
  }

  # A few codebook waves contain multiple versions of a similar item.  The
  # patterns below are deliberately specific; retain the first exact match.
  candidates[1L]
}

find_code_optional <- function(year, pattern) {
  target_year <- as.character(year)
  candidates <- codebook[
    year == target_year & grepl(pattern, line, ignore.case = TRUE),
    code
  ]
  if (length(candidates) == 0L) NA_character_ else candidates[1L]
}

find_first_available <- function(year, patterns, description) {
  for (pattern in patterns) {
    code <- find_code_optional(year, pattern)
    if (!is.na(code)) return(code)
  }
  stop("Could not find ", description, " for ", year)
}

find_first_available_optional <- function(year, patterns) {
  for (pattern in patterns) {
    code <- find_code_optional(year, pattern)
    if (!is.na(code)) return(code)
  }
  NA_character_
}

get_or_na <- function(data, code) {
  if (is.na(code)) rep(NA_real_, nrow(data)) else data[[code]]
}

base_vars <- c(
  child_id = "C0000100",
  mother_id = "C0000200",
  race = "C0005300",
  sex = "C0005400",
  birth_year = "C0005700",
  birth_order = "C0005800",
  mother_age_at_birth = "C0007000"
)

# Birth weight is a retrospective child-level measure rather than a measure
# observed in each child-survey wave.  It is the period-1 cognitive measure
# listed in Web Appendix Table 10-4.
a9_static_vars <- c(
  birth_weight_ounces = "C0328600",
  gestation_length_10weeks = "C0328000"
)

# CHS's empirical application uses the original CNLSY/79 assessment window
# (1986--2006) and eight age periods from age 0 through ages 13--14.  The
# public-use file has later variables too, but 2016 does not provide the same
# child-assessment-age field, so later waves are left out of this replication
# extract.
wave_years <- seq(1986, 2006, by = 2)

wave_map <- rbindlist(lapply(wave_years, function(y) {
  data.table(
    wave = y,
    age_months = find_code(
      y,
      "AGE OF CHILD \\(IN MONTHS\\) AT CHILD ASSESSMENT DATE, CHILD SUPPLEMENT",
      "child assessment age"
    ),
    math_raw = find_code(
      y,
      "PIAT MATH: *TOTAL RAW SCORE",
      "PIAT Mathematics total raw score"
    ),
    reading_recognition_raw = find_code(
      y,
      "PIAT READING RECOGNITION: *TOTAL RAW SCORE",
      "PIAT Reading Recognition total raw score"
    ),
    msd_raw = find_code_optional(
      y,
      "MOTOR & SOCIAL DEVELOPMENT: RAW SCORE"
    ),
    ppvt_raw = find_code(
      y,
      "PEABODY PICTURE VOCABULARY.*TOTAL RAW SCORE",
      "PPVT total raw score"
    ),
    temperament_difficulty_raw = find_code_optional(
      y,
      "HOW MY CHILD USUALLY ACTS/TEMPERAMENT: DIFFICULTY COMPOSITE RAW SCORE"
    ),
    anti_raw = find_code(y,
      "BEHAVIOR PROBLEMS INDEX: ANTISOCIAL RAW SCORE",
      "BPI antisocial raw score"),
    anxious_depressed_raw = find_code(y,
      "BEHAVIOR PROBLEMS INDEX: ANXIOUS/DEPRESSED RAW SCORE",
      "BPI anxious/depressed raw score"),
    headstrong_raw = find_code(y,
      "BEHAVIOR PROBLEMS INDEX: HEADSTRONG RAW SCORE",
      "BPI headstrong raw score"),
    hyperactive_raw = find_code(y,
      "BEHAVIOR PROBLEMS INDEX: HYPERACTIVE RAW SCORE",
      "BPI hyperactive raw score"),
    dependent_raw = find_code(y,
      "BEHAVIOR PROBLEMS INDEX: DEPENDENT RAW SCORE",
      "BPI dependent raw score"),
    peer_conflict_withdrawn_raw = find_code(y,
      "BEHAVIOR PROBLEMS INDEX: PEER CONFLICTS/WITHDRAWN RAW SCORE",
      "BPI peer conflicts/withdrawn raw score"),
    home_read_a = find_code(
      y,
      "HOME PART A \\(0-2 YRS\\): HOW OFTEN MOTHER READS TO CHILD",
      "HOME mother-reads item, Part A"
    ),
    home_read_b = find_code(
      y,
      "HOME PART B .*HOW OFTEN MOTHER READS TO CHILD",
      "HOME mother-reads item, Part B"
    ),
    home_read_c = find_code(
      y,
      "HOME PART C .*HOW OFTEN MOTHER READS TO CHILD",
      "HOME mother-reads item, Part C"
    ),
    home_read_d = find_code_optional(
      y,
      "HOME PART D .*HOW OFTEN MOTHER READS TO CHILD"
    ),
    home_music_c = find_first_available(
      y,
      c(
        "HOME PART C .*HOW OFTEN CHILD TAKEN TO MUSIC/THEATER PERFORMANCE",
        "RECODE - HOME C .*HOW OFTEN CHILD TAKEN TO MUSIC/THEATER PERFORMANCE",
        "HOME PART C .*HOW OFTEN CHILD TAKEN TO THEATER"
      ),
      "HOME musical-performance item, Part C"
    ),
    home_music_d = find_first_available_optional(
      y,
      c(
        "HOME PART D .*HOW OFTEN CHILD TAKEN TO MUSIC/THEATER PERFORMANCE",
        "RECODE - HOME D .*HOW OFTEN CHILD TAKEN TO MUSIC/THEATER PERFORMANCE",
        "HOME PART D .*HOW OFTEN CHILD TAKEN TO THEATER"
      )
    ),
    home_total_z = find_code(y,
      "HOME INVENTORY: TOTAL STANDARD SCORE",
      "HOME total standard score"),
    home_cognitive_z = find_code(y,
      "HOME INVENTORY: COGNITIVE STIMULATION STANDARD SCORE",
      "HOME cognitive stimulation standard score"),
    home_emotional_z = find_code(y,
      "HOME INVENTORY: EMOTIONAL SUPPORT STANDARD SCORE",
      "HOME emotional support standard score")
  )
}))

wave_measure_vars <- setdiff(names(wave_map), "wave")
selected_vars <- unique(c(
  unname(base_vars),
  unname(a9_static_vars),
  unlist(wave_map[, wave_measure_vars, with = FALSE], use.names = FALSE)
))
selected_vars <- selected_vars[!is.na(selected_vars)]
header <- names(fread(raw_csv, nrows = 0L, showProgress = FALSE))
missing_vars <- setdiff(selected_vars, header)
if (length(missing_vars) > 0L) {
  stop("The following selected columns were not found in the CSV: ",
       paste(missing_vars, collapse = ", "))
}

# -------------------------------------------------------------------------
# 2. Read only the selected columns and apply the CHS-style sample filter.
# -------------------------------------------------------------------------
raw <- fread(raw_csv, select = selected_vars, showProgress = TRUE)

# NLS special missing values are negative codes in these numeric measures.
measure_vars <- setdiff(names(raw), names(base_vars))
raw[, (measure_vars) := lapply(.SD, function(x) {
  x[x < 0] <- NA_real_
  x
}), .SDcols = measure_vars]

# Replace the raw NLS column codes with readable names before constructing
# sample indicators and the long panel.
setnames(raw, old = c(unname(base_vars), unname(a9_static_vars)),
         new = c(names(base_vars), names(a9_static_vars)))

raw[, race_label := fifelse(
  race == 3,
  "non-black, non-Hispanic (CHS white-sample definition)",
  fifelse(race == 2, "Black", fifelse(race == 1, "Hispanic", NA_character_))
)]
raw[, white_sample := race == 3]
raw[, firstborn := birth_order == 1]

white_children <- raw[white_sample == TRUE]
chs_white_firstborn <- raw[white_sample == TRUE & firstborn == TRUE]

# Save the child-level wide file.  It contains the full set of available
# calendar waves; users can select the eight age periods used by CHS.
wide_output <- copy(chs_white_firstborn)
for (i in seq_len(nrow(wave_map))) {
  y <- wave_map$wave[i]
  for (m in wave_measure_vars) {
    if (!is.na(wave_map[[m]][i])) {
      setnames(
        wide_output,
        old = wave_map[[m]][i],
        new = paste0(m, "_", y)
      )
    }
  }
}
fwrite(
  wide_output,
  file.path(out_dir, "chs_white_firstborn_measurements_wide.csv")
)
saveRDS(
  wide_output,
  file.path(out_dir, "chs_white_firstborn_measurements_wide.rds")
)

# -------------------------------------------------------------------------
# 3. Convert the selected measures to child-by-wave long format.
# -------------------------------------------------------------------------
long <- rbindlist(lapply(seq_len(nrow(wave_map)), function(i) {
  y <- wave_map$wave[i]
  z <- chs_white_firstborn[, .(
    child_id,
    mother_id,
    sex_code = sex,
    birth_year,
    birth_order,
    mother_age_at_birth,
    race_code = race,
    race_label,
    birth_weight_ounces,
    wave = y,
    assessment_age_months = get(wave_map$age_months[i]),
    piat_math_raw = get(wave_map$math_raw[i]),
    piat_reading_recognition_raw = get(wave_map$reading_recognition_raw[i]),
    msd_raw = get_or_na(chs_white_firstborn, wave_map$msd_raw[i]),
    ppvt_raw = get(wave_map$ppvt_raw[i]),
    temperament_difficulty_raw = get_or_na(chs_white_firstborn,
                                           wave_map$temperament_difficulty_raw[i]),
    bpi_antisocial_raw = get(wave_map$anti_raw[i]),
    bpi_anxious_depressed_raw = get(wave_map$anxious_depressed_raw[i]),
    bpi_headstrong_raw = get(wave_map$headstrong_raw[i]),
    bpi_hyperactive_raw = get(wave_map$hyperactive_raw[i]),
    bpi_dependent_raw = get(wave_map$dependent_raw[i]),
    bpi_peer_conflict_withdrawn_raw = get(wave_map$peer_conflict_withdrawn_raw[i]),
    home_read_a = get(wave_map$home_read_a[i]),
    home_read_b = get(wave_map$home_read_b[i]),
    home_read_c = get(wave_map$home_read_c[i]),
    home_read_d = get_or_na(chs_white_firstborn, wave_map$home_read_d[i]),
    home_music_c = get(wave_map$home_music_c[i]),
    home_music_d = get_or_na(chs_white_firstborn, wave_map$home_music_d[i]),
    home_total_z = get(wave_map$home_total_z[i]),
    home_cognitive_z = get(wave_map$home_cognitive_z[i]),
    home_emotional_z = get(wave_map$home_emotional_z[i])
  )]
  z[, assessment_age_years := assessment_age_months / 12]
  z[, in_chs_age_range := !is.na(assessment_age_months) &
      assessment_age_months <= 168]
  z[, chs_period_approx := fifelse(
    !in_chs_age_range, NA_integer_,
    pmin(8L, pmax(1L, floor((assessment_age_years + 1) / 2) + 1L))
  )]
  z
}), use.names = TRUE)

setorder(long, child_id, wave)
fwrite(long, file.path(out_dir, "chs_white_firstborn_measurements_long.csv"))
saveRDS(long, file.path(out_dir, "chs_white_firstborn_measurements_long.rds"))

# Keep a small, human-readable record of what was extracted.
codebook_extract <- data.table(
  wave = rep(wave_map$wave, times = length(wave_measure_vars)),
  measure = rep(wave_measure_vars, each = nrow(wave_map)),
  code = unlist(wave_map[, wave_measure_vars, with = FALSE], use.names = FALSE)
)
fwrite(codebook_extract, file.path(out_dir, "chs_white_firstborn_selected_codebook.csv"))

# -------------------------------------------------------------------------
# 4. Construct the period-level variables listed in Web Appendix A9.
# -------------------------------------------------------------------------
# The official Web Appendix Table 10-4 selects one representative measure for
# each factor in each of eight developmental periods.  The broader extract
# above keeps all available measures; this block creates the A9-style teaching
# file and retains the source survey wave for every selected value.
first_nonmissing <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) NA_real_ else as.numeric(x[1L])
}

first_wave <- function(wave, x) {
  wave <- wave[!is.na(x)]
  if (length(wave) == 0L) NA_integer_ else as.integer(wave[1L])
}

a9_wave <- long[assessment_age_months >= 0 & assessment_age_months < 180]
a9_wave[, a9_period := cut(
  assessment_age_months,
  breaks = c(-Inf, 12, 36, 60, 84, 108, 132, 156, 180),
  labels = FALSE,
  right = FALSE
)]

a9_wave[, a9_cognitive_candidate := fcase(
  a9_period == 2, msd_raw,
  a9_period == 3, ppvt_raw,
  a9_period >= 4, piat_math_raw,
  default = NA_real_
)]
a9_wave[, a9_non_cognitive_candidate := fcase(
  a9_period %in% c(1, 2), temperament_difficulty_raw,
  a9_period >= 3, bpi_antisocial_raw,
  default = NA_real_
)]
a9_wave[, a9_investment_candidate := fcase(
  a9_period %in% c(1, 2), home_read_a,
  a9_period == 3, home_read_b,
  a9_period >= 4, fcoalesce(home_music_c, home_music_d),
  default = NA_real_
)]

a9_selected <- a9_wave[, .(
  a9_cognitive_value = first_nonmissing(a9_cognitive_candidate),
  cognitive_source_wave = first_wave(wave, a9_cognitive_candidate),
  a9_non_cognitive_value = first_nonmissing(a9_non_cognitive_candidate),
  non_cognitive_source_wave = first_wave(wave, a9_non_cognitive_candidate),
  a9_investment_value = first_nonmissing(a9_investment_candidate),
  investment_source_wave = first_wave(wave, a9_investment_candidate)
), by = .(child_id, a9_period)]
setnames(a9_selected, "a9_period", "period")

child_base <- unique(chs_white_firstborn[, .(
  child_id,
  mother_id,
  sex_code = sex,
  birth_year,
  birth_order,
  mother_age_at_birth,
  race_code = race,
  race_label,
  birth_weight_ounces,
  gestation_length_10weeks
)])

period_grid <- CJ(child_id = child_base$child_id, period = 1:8, unique = TRUE)
a9_period <- merge(child_base, period_grid, by = "child_id", all = TRUE,
                   allow.cartesian = TRUE)
a9_period <- merge(a9_period, a9_selected,
                   by = c("child_id", "period"), all.x = TRUE)
setorder(a9_period, child_id, period)

a9_period[, cognitive_measure := fifelse(
  period == 1,
  birth_weight_ounces,
  a9_cognitive_value
)]
a9_period[, cognitive_measure_name := fcase(
  period == 1, "Weight at birth",
  period == 2, "Motor-Social Development",
  period == 3, "Peabody Picture Vocabulary Test",
  period >= 4, "PIAT Mathematics"
)]
a9_period[, non_cognitive_measure := a9_non_cognitive_value]
a9_period[, non_cognitive_measure_name := fcase(
  period %in% c(1, 2), "Temperament Difficulty",
  period >= 3, "BPI Antisocial Behavior"
)]
a9_period[, investment_measure := a9_investment_value]
a9_period[, investment_measure_name := fcase(
  period %in% c(1, 2, 3), "Frequency Mother Reads to Child",
  period >= 4, "Frequency Child Goes to Musical Shows"
)]
a9_period[, a9_measure_set := "Web Appendix Table 10-4"]
a9_period[, `:=`(
  has_cognitive_measure = !is.na(cognitive_measure),
  has_non_cognitive_measure = !is.na(non_cognitive_measure),
  has_investment_measure = !is.na(investment_measure)
)]

# Maternal measures in Web Appendix Table 9-3 come from the NLSY79
# respondent file and are merged by the child's mother ID.
maternal_csv <- file.path("data", "raw", "nlsy79_all_1979-2022",
                          "nlsy79_all_1979-2022.csv")
if (!file.exists(maternal_csv)) {
  stop("The NLSY79 respondent CSV was not found at: ", maternal_csv)
}

maternal_vars <- c(
  mother_id = "R0000100",
  maternal_asvab_arithmetic_reasoning = "R0615100",
  maternal_asvab_word_knowledge = "R0615200",
  maternal_asvab_paragraph_composition = "R0615300",
  maternal_asvab_numerical_operations = "R0615400",
  maternal_asvab_coding_speed = "R0615500",
  maternal_asvab_mathematics_knowledge = "R0615700",
  maternal_se_worth_1980 = "R0303500",
  maternal_se_good_qualities_1980 = "R0303600",
  maternal_se_failure_1980 = "R0303700",
  maternal_se_nothing_to_be_proud_1980 = "R0303900",
  maternal_se_positive_attitude_1980 = "R0304000",
  maternal_se_more_self_respect_1980 = "R0304200",
  maternal_se_useless_1980 = "R0304300",
  maternal_se_no_good_1980 = "R0304400",
  maternal_se_worth_1987 = "R2349100",
  maternal_se_good_qualities_1987 = "R2349200",
  maternal_se_failure_1987 = "R2349300",
  maternal_se_nothing_to_be_proud_1987 = "R2349500",
  maternal_se_positive_attitude_1987 = "R2349600",
  maternal_se_more_self_respect_1987 = "R2349800",
  maternal_se_useless_1987 = "R2349900",
  maternal_se_no_good_1987 = "R2350000",
  maternal_rotter_no_control = "R0153000",
  maternal_rotter_no_plans = "R0153200",
  maternal_rotter_luck_big_factor = "R0153400",
  maternal_rotter_luck_big_role = "R0153600"
)

maternal_header <- names(fread(maternal_csv, nrows = 0L,
                               showProgress = FALSE))
maternal_missing <- setdiff(unname(maternal_vars), maternal_header)
if (length(maternal_missing) > 0L) {
  stop("The following maternal columns were not found in the NLSY79 CSV: ",
       paste(maternal_missing, collapse = ", "))
}

maternal <- fread(
  maternal_csv,
  select = unique(unname(maternal_vars)),
  showProgress = TRUE
)
maternal_measure_vars <- setdiff(names(maternal), maternal_vars[["mother_id"]])
maternal[, (maternal_measure_vars) := lapply(.SD, function(x) {
  x[x < 0] <- NA_real_
  x
}), .SDcols = maternal_measure_vars]
setnames(maternal, old = unname(maternal_vars), new = names(maternal_vars))

# The appendix lists eight Rosenberg self-esteem items.  Prefer the 1980
# observation and fall back to the corresponding 1987 observation when needed.
for (item in c(
  "worth", "good_qualities", "failure", "nothing_to_be_proud",
  "positive_attitude", "more_self_respect", "useless", "no_good"
)) {
  maternal[, paste0("maternal_se_", item) := fcoalesce(
    get(paste0("maternal_se_", item, "_1980")),
    get(paste0("maternal_se_", item, "_1987"))
  )]
}

maternal_core_vars <- c(
  grep("^maternal_asvab_", names(maternal), value = TRUE),
  grep("^maternal_se_(worth|good_qualities|failure|nothing_to_be_proud|positive_attitude|more_self_respect|useless|no_good)$",
       names(maternal), value = TRUE),
  grep("^maternal_rotter_", names(maternal), value = TRUE)
)
maternal[, maternal_a9_n_nonmissing := rowSums(!is.na(.SD)),
         .SDcols = maternal_core_vars]
maternal[, maternal_a9_complete := maternal_a9_n_nonmissing ==
           length(maternal_core_vars)]

a9_period <- merge(a9_period, maternal, by = "mother_id", all.x = TRUE)
a9_period[, child_has_any_a9_measure := any(
  has_cognitive_measure | has_non_cognitive_measure | has_investment_measure
), by = child_id]
a9_period[, child_has_all_three_a9_types := all(c(
  any(has_cognitive_measure),
  any(has_non_cognitive_measure),
  any(has_investment_measure)
)), by = child_id]

fwrite(a9_period,
       file.path(out_dir, "chs_white_firstborn_appendix_a9_period.csv"))
saveRDS(a9_period,
        file.path(out_dir, "chs_white_firstborn_appendix_a9_period.rds"))

a9_dictionary <- data.table(
  period = 1:8,
  age_range = c("Birth", "1--2", "3--4", "5--6", "7--8", "9--10",
                "11--12", "13--14"),
  cognitive_measure = c("Weight at birth", "Motor-Social Development",
                        "Peabody Picture Vocabulary Test",
                        rep("PIAT Mathematics", 5)),
  non_cognitive_measure = c(rep("Temperament Difficulty", 2),
                            rep("BPI Antisocial Behavior", 6)),
  investment_measure = c(rep("Frequency Mother Reads to Child", 3),
                         rep("Frequency Child Goes to Musical Shows", 5)),
  source = "Cunha, Heckman, and Schennach (2010), Web Appendix Table 10-4"
)
fwrite(a9_dictionary,
       file.path(out_dir, "chs_white_firstborn_appendix_a9_variable_dictionary.csv"))

a9_child <- unique(a9_period[, .(
  child_id,
  mother_id,
  white_sample = TRUE,
  firstborn = TRUE,
  child_has_any_a9_measure,
  child_has_all_three_a9_types,
  maternal_a9_complete
)])
fwrite(a9_child,
       file.path(out_dir, "chs_white_firstborn_appendix_a9_child.csv"))
a9_counts <- data.table(
  sample = c(
    "Race code 3 and firstborn",
    "Has at least one age-eligible A9 child measure",
    "Has all three A9 child measure types",
    "Has complete A9 maternal measurement vector",
    "CHS published reference sample"
  ),
  n_children = c(
    nrow(a9_child),
    sum(a9_child$child_has_any_a9_measure),
    sum(a9_child$child_has_all_three_a9_types),
    sum(a9_child$maternal_a9_complete, na.rm = TRUE),
    2207L
  )
)
fwrite(a9_counts,
       file.path(out_dir, "chs_white_firstborn_appendix_a9_sample_counts.csv"))

cat("Created the Appendix A9 period-level teaching extract.\n")
print(a9_counts)

counts <- data.table(
  sample = c(
    "All CNLSY/79 child records",
    "Race code 3: non-black, non-Hispanic",
    "Race code 3 and firstborn"
  ),
  n_children = c(nrow(raw), nrow(white_children), nrow(chs_white_firstborn))
)
fwrite(counts, file.path(out_dir, "chs_white_firstborn_sample_counts.csv"))

cat("Created the CNLSY/79 teaching extract.\n")
print(counts)
cat("\nThe race filter is CRACE == 3 and the firstborn filter is BTHORDR == 1.\n")
cat("The raw NLS file was not copied or modified.\n")
