create trigger prototask_audit_trigger after
insert
    or
delete
    or
update
    on
    public.prototask for each row execute function logaudit();


create trigger prototaskelement_audit_trigger after
insert
    or
delete
    or
update
    on
    public.prototaskelement for each row execute function logaudit();
