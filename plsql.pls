
--sa se dubleze stocul produselor care au mai putin de 15 bucati
begin 
update produse_salon
set stoc=stoc*2
where stoc<20;
if sql%notfound then
dbms_output.put_line('Nu exista produse cu stocul mai mic de 20 de bucati');
else
dbms_output.put_line('S-a modificat stocul pentru '||sql%rowcount||' produse');
end if;
end;


--sa se afiseze pentru fiecare comanda valoarea totala si cine a intermediat-o (angajat+furnizor)
declare
cursor c1 is select id_comanda as idc, sum(pret*cantitate) as valoare_comanda from lista_comenzi group by id_comanda;
cursor c2(p_id number) is select f.nume as furniz, a.nume as angaj
from angajati_salon a, comenzi_salon c, furnizori f
where f.id_furnizor=c.id_furnizor and a.id_angajat=c.id_angajat and c.id_comanda=p_id;
begin
for v_com in c1 loop
dbms_output.put_line('Comanda cu id-ul:'||v_com.idc||' are valoarea '||v_com.valoare_comanda||' lei.');
for v_c in c2(v_com.idc) loop
dbms_output.put_line(' -> Comanda a fost intermediata de furnizorul '|| v_c.furniz||' si de angajatul '||v_c.angaj);
end loop; 
end loop;
 end;


--sa se afiseze informatii despre angajati si programarile lor
declare
cursor c1 is select id_angajat, nume, prenume from angajati_salon order by id_angajat;
cursor c2(p_id angajati_salon.id_angajat%type) is select id_programare,data from programari where id_angajat=p_id;
begin
for v_ang in c1 loop
dbms_output.put_line(v_ang.id_angajat||': '||'Angajatul '||v_ang.nume||'-'||v_ang.prenume);
for v_ang1 in c2(v_ang.id_angajat) loop
dbms_output.put_line('Are programarea cu id-ul '||v_ang1.id_programare||' in data de '||to_char(v_ang1.data,'DD-Mon-YY'));
end loop; end loop; end;


--sa se afiseze pentru fiecare functie informatii despre angajatii aferenti 
declare 
cursor c1 is select distinct(denumire_functie) from angajati_salon;
cursor c2(p_den angajati_salon.denumire_functie%type) is select nume, prenume, salariul from angajati_salon where denumire_functie=p_den;
v_den angajati_salon.denumire_functie%type;
v_nume angajati_salon.nume%type;
v_prenume angajati_salon.prenume%type;
v_sal angajati_salon.salariul%type;
begin
open c1;
loop
fetch c1 into v_den;
exit when c1%notfound;
dbms_output.put_line('Denumire functie: '||v_den);
open c2(v_den);
loop
fetch c2 into v_nume,v_prenume,v_sal;
exit when c2%notfound;
dbms_output.put_line('   '||'Angajatul '||v_nume||'-'||v_prenume||' are salariul '||v_sal||' lei.');
end loop;
dbms_output.put_line('');
close c2;
end loop;
close c1;
end;


--sa se afiseze serviciile care au pretul mai mare ca media preturilor
declare
cursor c is select denumire_serviciu, pret from servicii_salon;
v_serv c%rowtype;
v_med servicii_salon.pret%type;
begin
select avg(pret)
into v_med
from servicii_salon;
dbms_output.put_line('Pretul mediu pentru un serviciu este '||v_med||' lei.');
open c;
loop
fetch c into v_serv;
exit when c%notfound;
if v_serv.pret>v_med then
dbms_output.put_line('Serviciul "'||v_serv.denumire_serviciu||'" '||'costa '||v_serv.pret||' lei.');
else
dbms_output.put_line('   Serviciul "'||v_serv.denumire_serviciu||'" '|| 'are pretul mai mic ca media preturilor.');
end if;
end loop;
end;


--sa se majoreze cu 100 de lei salariul angajatilor cu denumirea functiei „Frizer”, cu 150 celor cu denumirea „Make-up Artist” si cu 200 altfel. Sa se afiseze numarul de modificari facute
begin
update angajati_salon
set salariul=
case
when lower(denumire_functie)='frizer' then salariul+100
when lower(denumire_functie)='make-up artist' then salariul+150
else salariul+200
end;
if sql%rowcount>0 then
dbms_output.put_line('S-au facut '||sql%rowcount||' modificari.');
end if;
end;


--sa se afiseze pentru fiecare serviciu produsele folosite
declare 
cursor c1 is select id_serviciu, denumire_serviciu from servicii_salon;
cursor c2(p_id number) is select distinct(p.id_produs), denumire_produs
from produse_salon p, detalii_servicii d
where p.id_produs=d.id_produs and d.id_serviciu=p_id;
begin 
for v_serv in c1 loop
dbms_output.put_line('Pentru serviciul "'||v_serv.denumire_serviciu||'"'||' sunt necesare urmatoarele produse:');
for v_serv2 in c2(v_serv.id_serviciu) loop
dbms_output.put_line('  -'||v_serv2.denumire_produs);
end loop;
end loop;
end;


--sa se majoreze cu 20 pretul unui serviciu al carui cod este citit de la tastatura, in cazul in care acesta nu exista se va invoca o exceptie
declare
cod_invalid exception;
begin
update servicii_salon
set pret=pret+20
where id_serviciu=:id;
if sql%rowcount=0 then
raise cod_invalid;
else
dbms_output.put_line('Pretul serviciului s-a modificat cu succes');
end if;
exception
when cod_invalid then 
dbms_output.put_line('Codul introdus nu exista.');
dbms_output.put_line('Codurile valide sunt urmatoarele:');
for c in (select id_serviciu from servicii_salon)
loop
dbms_output.put_line('-'||c.id_serviciu);
end loop; end;


--sa se afiseze id-ul si numele clientilor care au avut programare intr-o luna citita de la tastatura. In cazul in care nu exista programari sau sunt mai multe se va invoca o exceptie
declare 
v_id clienti_salon.id_client%type;
v_nume clienti_salon.nume%type;
v_luna number:=:zi;
begin
select p.id_client, nume
into v_id,v_nume
from programari p, clienti_salon c
where p.id_client=c.id_client and extract(month from data)=v_luna;
dbms_output.put_line('Clientul '||v_nume||' a avut o programare in luna '||v_luna);
exception
when too_many_rows then
dbms_output.put_line('In luna '||v_luna||' exista mai multe programari');
when no_data_found then
dbms_output.put_line('In luna '||v_luna||' nu exista programari');
end;


--sa se adauge o inregistrare in tabela angajati_salon tratand posibilele exceptii
declare 
valori_insuficiente exception;
pragma exception_init(valori_insuficiente,-01400);
unicitate exception;
pragma exception_init(unicitate,-00001);
begin
insert into angajati_salon(id_angajat, nume, prenume)
values(11,'Popescu','Mihai'); 
exception
when valori_insuficiente then
dbms_output.put_line('Nu ati introdus valori pentru toate campurile obligatorii.');
when unicitate then
dbms_output.put_line('Id-ul introdus trebuie sa fie unic!');
end;


--afisati denumirea produsului al carui id este citit de la tastatura si calculati cantitatea totala comandata din acel produs
declare
v_id produse_salon.id_produs%type:=:id;
v_den produse_salon.denumire_produs%type;
v_cant_total lista_comenzi.cantitate%type;
fara_comenzi exception;
v_nr number;
begin
select denumire_produs
into v_den
from produse_salon
where id_produs=v_id;
dbms_output.put_line('Produsul cu id-ul '||v_id||' are denumirea '||v_den);
select count(id_produs)
into v_nr
from lista_comenzi
where id_produs=v_id;
if v_nr=0 then
raise fara_comenzi;
else
select sum(cantitate)
into v_cant_total
from lista_comenzi
where id_produs=v_id;
dbms_output.put_line('Cantitatea totala comandata este de '||v_cant_total||' bucati');
end if;
exception
when no_data_found then
dbms_output.put_line('Produsul cu id-ul '||v_id||' nu exista');
when fara_comenzi then
dbms_output.put_line('Produsul nu a fost comandat');
when others then
dbms_output.put_line('A aparut o alta exceptie');
end;


--sa se afiseze numele produselor si in ce servicii sunt folosite. In cazul in care nu sunt folosite se va invoca o exceptie 
declare
nu_e_folosit exception;
v_id number:=:id;
v_den varchar2(20);
v_dens varchar2(20);
v_nr number;
begin
select id_produs, denumire_produs
into v_id,v_den
from produse_salon
where id_produs=v_id;
dbms_output.put_line('Produsul cu id-ul '||v_id||' este '||v_den);
select count(id_produs)
into v_nr
from detalii_servicii
where id_produs=v_id;
if v_nr=0 then
raise nu_e_folosit;
else
for c in (select denumire_serviciu 
from servicii_salon s, detalii_servicii d
where id_produs=v_id and s.id_serviciu=d.id_serviciu)
loop
dbms_output.put_line('Produsul '||v_den||' este folosit pentru serviciul de '||c.denumire_serviciu);
end loop;
end if;
exception
when nu_e_folosit then
dbms_output.put_line('Produsul nu este folosit');
end;



--sa se creeze procedura care afiseaza produsele care au un numar de bucati mai mic decat un numar dat ca parametru de intrare
create or replace procedure stoc_limitat (p_cantitate produse_salon.stoc%type)
is
begin
for c in (select * from produse_salon where stoc<=p_cantitate order by stoc ) loop
if(c.stoc>0) then
dbms_output.put_line('ID:'||c.id_produs||' Produsul '||c.denumire_produs||' este in cantitate limitata, mai sunt doar  '||c.stoc||' bucati.' );
else 
dbms_output.put_line('ID:'||c.id_produs||' Produsul '||c.denumire_produs||' nu mai este in stoc.');
end if;
end loop;
end;

begin
stoc_limitat(20);
end;


--sa se creeze procedura prin care se calculeaza valoarea unei comenzi intermediate de un angajat al carui id se transmite ca parametru de intrare
create or replace procedure valoare_comenzi(p_id angajati_salon.id_angajat%type)
is
v_nume angajati_salon.nume%type;
v_nr number;
fara_comenzi exception;
begin
select nume into v_nume from angajati_salon where id_angajat=p_id;
select count(id_angajat) into v_nr from comenzi_salon where id_angajat=p_id;
if v_nr=0 then raise fara_comenzi;
else
for c in(select id_comanda, sum(pret*cantitate) as valoare from lista_comenzi
where id_comanda=(select id_comanda from comenzi_salon where id_angajat=p_id)
group by id_comanda)
loop
dbms_output.put_line('Angajatul '||v_nume||' a intermediat comenzi in valoare de '||c.valoare||' lei');
end loop;
end if;
exception
when no_data_found then
dbms_output.put_line('Angajatul cu id-ul introdus nu exista');
when fara_comenzi then 
dbms_output.put_line('Angajatul nu a intermediat comenzi');
end;
begin
valoare_comenzi(100); end;
--sa se creeze procedura care afiseaza clientii care au avut cel putin 2 programari
create or replace procedure clienti_fideli
is
begin
for c in (select nume,count(p.id_client)
from programari p,clienti_salon c
where p.id_client=c.id_client
group by nume
having count(p.id_client)>1) loop
dbms_output.put_line(c.nume || ' este client fidel. ');
end loop;
end;

begin
clienti_fideli;
end; 


--sa se creeze functia care calculeaza si returneaza totalul de plata pentru o programare
create or replace function bon(p_id programari.id_programare%type)
return number
is
v_total servicii_salon.pret%type;
begin
select  sum(pret) 
into v_total
from detalii_programari d, servicii_salon s
where s.id_serviciu=d.id_serviciu and id_programare=p_id;
return v_total;
exception
when no_data_found then
return null;
end;


declare 
v_total number;
begin
v_total:=bon(15);
if v_total is null then
dbms_output.put_line('Nu exista programarea');
else
dbms_output.put_line('Totalul de plata este '||v_total|| ' lei.');
end if;
end;


--sa se creeze functia care mareste si returneaza stocul unui produs cu un numar de bucati transmis ca parametru;
create or replace function mareste_stocul(p_id produse_salon.id_produs%type, p_bucati produse_salon.stoc%type)
return number
is
v_stoc produse_salon.stoc%type;
nu_exista_produs exception;
begin
update produse_salon
set stoc=stoc+p_bucati
where id_produs=p_id;
if sql%rowcount=0 then
raise nu_exista_produs;
else
select stoc into v_stoc from produse_salon where id_produs=p_id;
return v_stoc;
end if;
exception
when nu_exista_produs then return null;
end;


declare
v number;
begin
v:=mareste_stocul(110,10);
if v is null then dbms_output.put_line('Nu exista produsul');
else
dbms_output.put_line('Stocul s-a marit cu succes'); end if; end; 
--sa se creeze functia care calculeaza suma totala cheltuita de un client
create or replace function suma_cheltuita(p_id clienti_salon.id_client%type)
return number
is
v_total number:=0;
v_nr number;
id_invalid exception;
begin
select count(id_client) into v_nr from programari;
if v_nr=0 then
raise id_invalid;
else
for c in (select id_programare 
from programari
where id_client=p_id) loop
v_total:=v_total+ bon(c.id_programare);
return v_total;
end loop;
end if;
exception
when id_invalid then return null;
end;

declare
suma number;
begin
suma:=suma_cheltuita(8);
if suma is null then
dbms_output.put_line('Id invalid');
else 
dbms_output.put_line('Clientul a cheltuit in total '||suma|| ' lei');
end if;
end; 



--creează o procedura care, folosind 2 cursori, 
--sa afiseze lista furnizorilor și, pentru fiecare dintre aceștia - lista comenzilor primite în anul X și valoarea fiecăreia dintre acestea.
--X va fi parametrul procedurii. Trateaza eventualele exceptii. 
--Apelează procedura

create or replace procedure comenzi_furnizori(p_an number)
is
v_data number;
an_inexistent exception;
begin
for c2 in (select * from furnizori) loop
select count(id_comanda) into v_data from comenzi_salon where extract(year from data)=p_an;
if 
v_data=0 then raise an_inexistent;
else
dbms_output.put_line('Furnizorul '||c2.nume|| ' a intermediat comenzile:');
for c1 in (select c.id_comanda, sum(pret*cantitate) as valoare from comenzi_salon c,lista_comenzi l
where id_furnizor=c2.id_furnizor and extract(year from data)=p_an and c.id_comanda=l.id_comanda  
group by c.id_comanda)
loop
dbms_output.put_line('Comanda are valoarea '|| c1.valoare|| ' lei');
end loop;
end if;
end loop;
exception 
when an_inexistent then dbms_output.put_line('Nu exista comenzi in anul introdus');
end;


begin
comenzi_furnizori(2020);
end;


--creează o procedura prin care sa se returneze numărul programărilor
-- din anul curent pentru angajatul dat ca parametru, 
--dacă acesta are aceeași funcție cu angajatul cu salariul cel mai mare. 
--Trateaza eventualele exceptii. Apelează procedura

create or replace procedure nr_prog(p_id angajati_salon.id_angajat%type,p_nr out number)
is
v_den angajati_salon.denumire_functie%type;
v_an number:=extract(year from sysdate);
v_nr number;
v_id number;
functie_diferita exception;
nu_exista exception;
begin
select count(id_angajat) into v_id from angajati_salon where id_angajat=p_id;
if v_id=0 then raise nu_exista;
else
select denumire_functie into v_den
from angajati_salon
where id_angajat=(select id_angajat from angajati_salon order by salariul desc fetch first 1 row only);
end if;
select count(id_angajat) into v_nr from angajati_salon 
where id_angajat=p_id and denumire_functie=v_den;

if v_nr=0 then raise functie_diferita;
else
select count(id_programare) into p_nr
from programari
where id_angajat=p_id and extract(year from data)=v_an;
end if;
exception
when nu_exista then dbms_output.put_line('Angajatul introdus nu exista');
when functie_diferita then dbms_output.put_line('Angajatul introdus are alta functie fata de angajatul cu salariul cel mai mare');
end;


declare 
v_nr number;
begin
--nr_prog(2,v_nr);
nr_prog(3,v_nr);
if v_nr is not null then
dbms_output.put_line('Angajatul are '||v_nr||' programari');
end if;
end;


--sa se creeze un trigger asupra tabelei lista_comenzi:
--la insert, stocul produselor trebuie marit cu cantitatea comandata
--la update, stocul produselor trebuie modificat in mod corespunzator

create or replace trigger stoc_modificat
after insert or update of cantitate on lista_comenzi
for each row
declare 
v_stoc produse_salon.stoc%type;
begin
select stoc into v_stoc from produse_salon where id_produs=:new.id_produs;
case
when inserting then v_stoc:=v_stoc+:new.cantitate;
when updating then v_stoc:=v_stoc-(:old.cantitate-:new.cantitate);
else v_stoc:=v_stoc;
end case;
update produse_salon 
set stoc=v_stoc
where id_produs=:new.id_produs;
end;


--sa se creeze un trigger care sa nu-i permita unui angajat sa aiba 2 programari in acelasi timp
create or replace trigger programari_angajat
before insert on programari
for each row
begin
for c in (select data  from programari where id_angajat=:new.id_angajat) loop
if c.data=:new.data then
raise_application_error(-20003,'Un angajat nu poate avea mai multe programari in acelasi timp');
end if;
end loop;
end;


--sa se creeze un trigger care opreste inserarea sau modificare unei programari intr-o zi libera sau de sarbatoare
create or replace function get_data(p_data programari.data%type) return date
is v_data date;
begin
v_data:=to_date(to_char(p_data, 'dd-mm-yyyy'), 'dd-mm-yyyy');
return v_data; end;

create or replace trigger zile_libere
before insert or update of data on programari
for each row
begin
if substr(get_data(:new.data),1,5) in ('25-12','01-01','01-05','01-06','24-02','30-11','01-12')
then raise_application_error(-20004,'Nu puteti adauga programari in zilele libere sau de sarbatori legale');
end if;
end;
select * from programari
insert into programari values (20, '25-12-2021 18:34:37,000000000 EUROPE/ATHENS',8,5);


--sa se creeze pachetul care contine:
--o functie care returneaza numarul de programari dintr-o zi data ca parametru
--o procedura care afiseazala serviciile cerute de un client la o programare

create or replace package informatii_programari as
function nr_programari (p_data programari.data%type) return number;
procedure servicii (p_id programari.id_programare%type);
end;

create or replace package body informatii_programari as
function nr_programari (p_data programari.data%type)return number is
v_nr number;
v_data date:=to_date(to_char(p_data, 'dd-mm-yyyy'), 'dd-mm-yyyy');
begin
select count(id_programare)
into v_nr
from programari
where to_date(to_char(data, 'dd-mm-yyyy'), 'dd-mm-yyyy')=v_data;
return v_nr;
exception
when no_data_found then return null;
end;
procedure servicii (p_id programari.id_programare%type)
is
begin
dbms_output.put_line('Programarea cu id-ul  '||p_id|| ' are urmatoarele servicii ');
for c in (select s.id_serviciu,denumire_serviciu from servicii_salon s,detalii_programari d where id_programare=p_id
and s.id_serviciu=d.id_serviciu) loop
dbms_output.put_line(c.denumire_serviciu);
end loop;
exception
when no_data_found then
dbms_output.put_line('Programarea nu exista');
end;
end;

declare
x number;
begin
for c in (select distinct(data) from programari) loop
x:=informatii_programari.nr_programari(c.data);
if x is not null then
dbms_output.put_line('In data de '||c.data||' au fost '||x|| ' programari');
end if;
end loop;
informatii_programari.servicii(3);
end; 


--sa se creeze pachetul care contine:
--o procedura care adauga o noua intregistrare in tabela angajati 
--o procedura care sterge o inregistrare din tabela angajati
--o procedura care modifica salariul unui angajat si salveaza modificare in tabela istoric_angajati

create table istoric_angajati (
id_angajat number(5) constraint pk_ang primary key,
data_modificare date not null,
salariul_vechi number(6) not null,
salariul_nou number(6) not null);

create or replace package gestiune_angajati as
procedure adauga_angajat(p_id angajati_salon.id_angajat%type,
p_nume angajati_salon.nume%type,p_prenume angajati_salon.prenume%type,
p_den_functie angajati_salon.denumire_functie%type,
p_sal angajati.salariul%type);
procedure concediaza_angajat(p_id angajati_salon.id_angajat%type);
procedure mareste_salariul(p_id angajati_salon.id_angajat%type,
p_sal_nou angajati_salon.salariul%type);
end;

create or replace package body gestiune_angajati as
procedure adauga_angajat(p_id angajati_salon.id_angajat%type,
p_nume angajati_salon.nume%type,p_prenume angajati_salon.prenume%type,
p_den_functie angajati_salon.denumire_functie%type,
p_sal angajati.salariul%type) is
unicitate exception;
pragma exception_init(unicitate,-00001);
begin
insert into angajati_salon values(p_id,p_nume,p_prenume,p_den_functie,p_sal);
exception
when unicitate then dbms_output.put_line('Id-ul introdus trebuie sa fie unic');
end;
procedure concediaza_angajat(p_id angajati_salon.id_angajat%type) is
v_nr number;
nu_exista exception;
begin
select count(id_angajat) into v_nr from angajati_salon where id_angajat=p_id;
if v_nr=0 then raise nu_exista;
else
delete from angajati_salon where id_angajat=p_id;
dbms_output.put_line('Stergerea a fost realizata cu succes');
end if;
exception
when nu_exista then dbms_output.put_line('Angajatul cu id-ul '||p_id||' nu exista.');
end;
procedure mareste_salariul(p_id angajati_salon.id_angajat%type,
p_sal_nou angajati_salon.salariul%type) is
v_sal_vechi angajati_salon.salariul%type; 
begin
select salariul into v_sal_vechi from angajati_salon where id_angajat=p_id;
update angajati_salon
set salariul=p_sal_nou
where id_angajat=p_id;
insert into istoric_angajati values(p_id,sysdate,v_sal_vechi,p_sal_nou);
exception
when no_data_found then dbms_output.put_line('Angajatul cu id-ul '||p_id||' nu exista.');
end;
end;

begin
gestiune_angajati.adauga_angajat(21,'Georgescu','Andreea','Cosmetician',2500);
gestiune_angajati.adauga_angajat(21,'Marin','Ana','Stilist',2300);

gestiune_angajati.concediaza_angajat(21);
gestiune_angajati.concediaza_angajat(21);

gestiune_angajati.mareste_salariul(6,2500);
gestiune_angajati.mareste_salariul(21,2800);
end;






