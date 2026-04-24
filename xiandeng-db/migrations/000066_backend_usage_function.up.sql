DROP FUNCTION IF EXISTS get_student_user_by_account_id(uuid);
CREATE OR REPLACE FUNCTION get_student_user_by_account_id(account_id uuid)
    RETURNS TABLE
            (
                phone              varchar,
                email              varchar,
                nickname           varchar,
                firstname          varchar,
                lastname           varchar,
                sex                gender,
                province           varchar,
                city               varchar,
                avatarurl          text,
                accountname        varchar,
                accounttype        entitytype,
                acctcreatedat      timestamp,
                university         varchar,
                majorcode          varchar,
                genstudysuggestion text,
                mbtienergy varchar,
                mbtimind varchar,
                mbtidecision varchar,
                mbtireaction varchar,
                major varchar,
                StudyingSuggestion text,
                MajorReference text,
                mbtitype char,
                CharacterSuggestion text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
return query
select u.phone,
       u.email,
       u.nickname,
       u.firstname,
       u.lastname,
       u.sex,
       u.province,
       u.city,
       u.avatarurl,
       acct.accountname,
       acct.type,
       acct.createdat     as acctcreatedat,
       sa.university,
       sa.majorcode,
       sa.StudySuggestion as genstudysuggestion,
       sa.mbtienergy,
       sa.mbtimind,
       sa.mbtidecision,
       sa.mbtireaction,
       m.name as major,
       m.StudyingSuggestion,
       m.MajorReference,
       ms.Type as mbtitype,
       ms.Suggestion as CharacterSuggestion
from public.users u
         left join useraccountrole uar on u.id = uar.userid
         left join account acct on acct.id = uar.accountid
         left join public.roles r on r.id = uar.roleid
         left join public.studentattribute sa on acct.id = sa.accountid
         LEFT JOIN Major m ON sa.majorcode = m.code
         LEFT JOIN MBTISuggestion ms ON CONCAT(sa.MBTIEnergy, sa.MBTIMind, sa.MBTIDecision, sa.MBTIReaction) = ms.Type
where acct.id = account_id
  and r.rolename = 'STUDENT';
END;
$function$;