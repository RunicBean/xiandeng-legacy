DROP trigger IF EXISTS trg_student_study_checklist_status_auto_updated ON public.accountusertaskdata;

DROP INDEX IF EXISTS idx_student_study_checklist_status_student_id;
DROP INDEX IF EXISTS idx_student_study_checklist_status_checklist_id;

DROP TABLE IF EXISTS student_study_checklist_status;
DROP TABLE IF EXISTS study_checklist;


