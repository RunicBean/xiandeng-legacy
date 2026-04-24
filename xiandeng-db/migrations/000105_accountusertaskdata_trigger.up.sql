     
create trigger accountusertaskdata_audit_trigger after
insert
    or
delete
    or
update
    on
    public.accountusertaskdata for each row execute function logaudit();
